// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

package energy_tracking

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// Service handles business logic for energy tracking
type Service struct {
	repo *Repository
}

// NewService creates a new energy tracking service
func NewService(repo *Repository) *Service {
	return &Service{repo: repo}
}

// RecordEnergy records the user's current energy level
func (s *Service) RecordEnergy(ctx context.Context, userID uuid.UUID, req RecordEnergyRequest) (*EnergySnapshot, error) {
	now := time.Now()
	snapshot := &EnergySnapshot{
		ID:          uuid.New(),
		UserID:      userID,
		RecordedAt:  now,
		EnergyLevel: req.EnergyLevel,
		TimeOfDay:   s.getTimeOfDay(now),
		DayOfWeek:   int(now.Weekday()),
		Context:     req.Context,
	}

	if err := s.repo.RecordEnergySnapshot(ctx, snapshot); err != nil {
		return nil, err
	}

	// Update energy patterns in background (don't block the response)
	go s.updateEnergyPatterns(context.Background(), userID, snapshot)

	return snapshot, nil
}

// GetEnergyHistory retrieves energy snapshots within a date range
func (s *Service) GetEnergyHistory(ctx context.Context, userID uuid.UUID, days int) (*EnergySnapshotsResponse, error) {
	endDate := time.Now()
	startDate := endDate.AddDate(0, 0, -days)

	snapshots, err := s.repo.GetEnergySnapshots(ctx, userID, startDate, endDate)
	if err != nil {
		return nil, err
	}

	// Initialize empty array if no snapshots
	if snapshots == nil {
		snapshots = []EnergySnapshot{}
	}

	return &EnergySnapshotsResponse{
		Snapshots: snapshots,
		StartDate: startDate,
		EndDate:   endDate,
	}, nil
}

// GetEnergyPatterns retrieves learned energy patterns for a user
func (s *Service) GetEnergyPatterns(ctx context.Context, userID uuid.UUID) ([]UserEnergyPattern, error) {
	patterns, err := s.repo.GetUserEnergyPatterns(ctx, userID)
	if err != nil {
		return nil, err
	}

	// Initialize empty array if no patterns
	if patterns == nil {
		patterns = []UserEnergyPattern{}
	}

	return patterns, nil
}

// GetEnergyBasedRecommendations provides meal recommendations based on energy
func (s *Service) GetEnergyBasedRecommendations(ctx context.Context, userID uuid.UUID, currentEnergy *int) (*EnergyBasedRecommendation, error) {
	now := time.Now()
	timeOfDay := s.getTimeOfDay(now)

	// If no current energy provided, predict based on patterns
	if currentEnergy == nil {
		pattern, err := s.repo.GetOrCreateEnergyPattern(ctx, userID, timeOfDay, int(now.Weekday()))
		if err != nil {
			// If pattern lookup fails, default to moderate
			defaultEnergy := 3
			currentEnergy = &defaultEnergy
		} else {
			currentEnergy = &pattern.TypicalEnergyLevel
		}
	}

	// Get favorite meals appropriate for this energy level
	maxResults := 20
	meals, err := s.repo.GetFavoriteMeals(ctx, userID, currentEnergy, &timeOfDay, maxResults)
	if err != nil {
		return nil, err
	}

	// Initialize empty array if no meals
	if meals == nil {
		meals = []FavoriteMeal{}
	}

	// Generate reasoning
	reasoning := s.generateReasoning(*currentEnergy, timeOfDay, len(meals))

	return &EnergyBasedRecommendation{
		Meals:         meals,
		CurrentEnergy: *currentEnergy,
		TimeOfDay:     timeOfDay,
		Reasoning:     reasoning,
	}, nil
}

// SaveFavoriteMeal creates a new favorite meal
func (s *Service) SaveFavoriteMeal(ctx context.Context, userID uuid.UUID, req SaveFavoriteMealRequest) (*FavoriteMeal, error) {
	meal := &FavoriteMeal{
		ID:               uuid.New(),
		UserID:           userID,
		RecipeID:         req.RecipeID,
		MealName:         req.MealName,
		EnergyLevel:      req.EnergyLevel,
		TypicalTimeOfDay: req.TypicalTimeOfDay,
		Notes:            req.Notes,
		FrequencyScore:   0,
	}

	if err := s.repo.SaveFavoriteMeal(ctx, meal); err != nil {
		return nil, err
	}
	return meal, nil
}

// GetFavoriteMeal retrieves a specific favorite meal
func (s *Service) GetFavoriteMeal(ctx context.Context, id, userID uuid.UUID) (*FavoriteMeal, error) {
	return s.repo.GetFavoriteMealByID(ctx, id, userID)
}

// GetFavoriteMeals retrieves favorite meals with optional filtering
func (s *Service) GetFavoriteMeals(ctx context.Context, userID uuid.UUID, req GetMealsRequest) ([]FavoriteMeal, error) {
	maxResults := req.MaxResults
	if maxResults == 0 {
		maxResults = 20
	}
	if maxResults > 100 {
		maxResults = 100
	}

	meals, err := s.repo.GetFavoriteMeals(ctx, userID, req.EnergyLevel, req.TimeOfDay, maxResults)
	if err != nil {
		return nil, err
	}

	// Initialize empty array if no meals
	if meals == nil {
		meals = []FavoriteMeal{}
	}

	return meals, nil
}

// UpdateFavoriteMeal updates an existing favorite meal
func (s *Service) UpdateFavoriteMeal(ctx context.Context, id, userID uuid.UUID, req UpdateFavoriteMealRequest) (*FavoriteMeal, error) {
	// Get existing meal to verify ownership
	existing, err := s.repo.GetFavoriteMealByID(ctx, id, userID)
	if err != nil {
		return nil, err
	}
	if existing == nil {
		return nil, fmt.Errorf("meal not found")
	}

	// Update fields
	existing.MealName = req.MealName
	existing.EnergyLevel = req.EnergyLevel
	existing.TypicalTimeOfDay = req.TypicalTimeOfDay
	existing.Notes = req.Notes

	if err := s.repo.UpdateFavoriteMeal(ctx, existing); err != nil {
		return nil, err
	}

	return existing, nil
}

// MarkMealEaten increments frequency score and updates last eaten time
func (s *Service) MarkMealEaten(ctx context.Context, mealID, userID uuid.UUID) error {
	return s.repo.IncrementMealFrequency(ctx, mealID, userID)
}

// DeleteFavoriteMeal deletes a favorite meal
func (s *Service) DeleteFavoriteMeal(ctx context.Context, id, userID uuid.UUID) error {
	return s.repo.DeleteFavoriteMeal(ctx, id, userID)
}

// GetRecipesByEnergy retrieves recipes filtered by energy level
func (s *Service) GetRecipesByEnergy(ctx context.Context, userID uuid.UUID, maxEnergyLevel int, limit int) ([]RecipeWithEnergy, error) {
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}

	recipes, err := s.repo.GetRecipesByEnergyLevel(ctx, userID, maxEnergyLevel, limit)
	if err != nil {
		return nil, err
	}

	// Initialize empty array if no recipes
	if recipes == nil {
		recipes = []RecipeWithEnergy{}
	}

	return recipes, nil
}

// Private helper methods

// updateEnergyPatterns updates learned energy patterns based on new snapshot
func (s *Service) updateEnergyPatterns(ctx context.Context, userID uuid.UUID, snapshot *EnergySnapshot) {
	// Get existing pattern
	pattern, err := s.repo.GetOrCreateEnergyPattern(ctx, userID, snapshot.TimeOfDay, snapshot.DayOfWeek)
	if err != nil {
		return
	}

	// Get recent snapshots for this time/day combo (last 30 days)
	startDate := time.Now().AddDate(0, 0, -30)
	endDate := time.Now()
	snapshots, err := s.repo.GetEnergySnapshots(ctx, userID, startDate, endDate)
	if err != nil {
		return
	}

	// Calculate weighted average energy for this time/day
	// More recent snapshots have higher weight
	var weightedSum float64
	var totalWeight float64
	now := time.Now()

	for _, s := range snapshots {
		if s.TimeOfDay == snapshot.TimeOfDay && s.DayOfWeek == snapshot.DayOfWeek {
			// Calculate weight based on recency (more recent = higher weight)
			daysAgo := now.Sub(s.RecordedAt).Hours() / 24
			weight := 1.0 / (1.0 + daysAgo/7.0) // Exponential decay with 7-day half-life

			weightedSum += float64(s.EnergyLevel) * weight
			totalWeight += weight
		}
	}

	if totalWeight > 0 {
		newAverage := int(weightedSum/totalWeight + 0.5) // Round to nearest int
		if newAverage < 1 {
			newAverage = 1
		}
		if newAverage > 5 {
			newAverage = 5
		}

		pattern.TypicalEnergyLevel = newAverage
		pattern.SampleCount = int(totalWeight + 0.5)
		s.repo.UpdateEnergyPattern(ctx, pattern)
	}
}

// getTimeOfDay determines time of day category
func (s *Service) getTimeOfDay(t time.Time) TimeOfDay {
	hour := t.Hour()
	switch {
	case hour >= 5 && hour < 12:
		return Morning
	case hour >= 12 && hour < 17:
		return Afternoon
	case hour >= 17 && hour < 22:
		return Evening
	default:
		return Night
	}
}

// generateReasoning creates a human-friendly explanation
func (s *Service) generateReasoning(energyLevel int, timeOfDay TimeOfDay, mealCount int) string {
	var energyDesc, timeDesc string

	switch energyLevel {
	case 1, 2:
		energyDesc = "low energy"
	case 3:
		energyDesc = "moderate energy"
	case 4, 5:
		energyDesc = "good energy"
	}

	switch timeOfDay {
	case Morning:
		timeDesc = "morning"
	case Afternoon:
		timeDesc = "afternoon"
	case Evening:
		timeDesc = "evening"
	case Night:
		timeDesc = "late night"
	}

	if mealCount == 0 {
		return "No favorite meals saved yet. Add some meals you enjoy to get personalized recommendations!"
	}

	return fmt.Sprintf("Showing meals appropriate for your %s this %s. These meals match your energy level and typical eating patterns.", energyDesc, timeDesc)
}
