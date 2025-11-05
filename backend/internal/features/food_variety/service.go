// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

package food_variety

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// Service defines the interface for food variety business logic
type Service interface {
	// Hyperfixation tracking
	TrackFoodConsumption(ctx context.Context, userID uuid.UUID, foodName string) error
	GetActiveHyperfixations(ctx context.Context, userID uuid.UUID) ([]FoodHyperfixation, error)
	RecordHyperfixation(ctx context.Context, userID uuid.UUID, req *RecordHyperfixationRequest) error

	// Food chaining
	GenerateChainSuggestions(ctx context.Context, userID uuid.UUID, foodName string, count int) ([]FoodChainSuggestion, error)
	RecordChainFeedback(ctx context.Context, suggestionID, userID uuid.UUID, req *RecordChainFeedbackRequest) error
	GetUserChainSuggestions(ctx context.Context, userID uuid.UUID, limit, offset int) ([]FoodChainSuggestion, error)

	// Variation ideas
	GetVariationIdeas(ctx context.Context, foodName string) ([]FoodVariation, error)

	// Variety analysis
	GetVarietyAnalysis(ctx context.Context, userID uuid.UUID) (*VarietyAnalysis, error)

	// Nutrition settings
	GetNutritionSettings(ctx context.Context, userID uuid.UUID) (*NutritionTrackingSettings, error)
	UpdateNutritionSettings(ctx context.Context, userID uuid.UUID, req *UpdateNutritionSettingsRequest) error

	// Nutrition insights
	GenerateWeeklyInsights(ctx context.Context, userID uuid.UUID) ([]NutritionInsight, error)
	GetWeeklyInsights(ctx context.Context, userID uuid.UUID) ([]NutritionInsight, error)
	DismissInsight(ctx context.Context, insightID, userID uuid.UUID) error

	// Rotation schedules
	CreateRotationSchedule(ctx context.Context, userID uuid.UUID, req *CreateRotationScheduleRequest) (*FoodRotationSchedule, error)
	GetRotationSchedules(ctx context.Context, userID uuid.UUID) ([]FoodRotationSchedule, error)
	UpdateRotationSchedule(ctx context.Context, scheduleID, userID uuid.UUID, req *UpdateRotationScheduleRequest) error
	DeleteRotationSchedule(ctx context.Context, scheduleID, userID uuid.UUID) error
}

type service struct {
	repo           Repository
	aiChainService AIChainService
}

// NewService creates a new food variety service
func NewService(repo Repository, aiService AIChainService) Service {
	return &service{
		repo:           repo,
		aiChainService: aiService,
	}
}

// Hyperfixation tracking

func (s *service) TrackFoodConsumption(ctx context.Context, userID uuid.UUID, foodName string) error {
	// Update last eaten tracking
	if err := s.repo.UpdateLastEaten(ctx, userID, foodName); err != nil {
		return err
	}

	// Check if this qualifies as a hyperfixation
	freq, err := s.repo.GetFoodFrequency(ctx, userID, foodName, 7)
	if err != nil {
		return err
	}

	// If eating this food 5+ times in 7 days, consider it a hyperfixation
	if freq >= 5 {
		return s.repo.UpsertHyperfixation(ctx, userID, foodName, freq)
	}

	return nil
}

func (s *service) GetActiveHyperfixations(ctx context.Context, userID uuid.UUID) ([]FoodHyperfixation, error) {
	return s.repo.GetActiveHyperfixations(ctx, userID)
}

func (s *service) RecordHyperfixation(ctx context.Context, userID uuid.UUID, req *RecordHyperfixationRequest) error {
	// Manual recording of hyperfixation
	return s.repo.UpsertHyperfixation(ctx, userID, req.FoodName, 1)
}

// Food chaining

func (s *service) GenerateChainSuggestions(ctx context.Context, userID uuid.UUID, foodName string, count int) ([]FoodChainSuggestion, error) {
	// Check if suggestions already exist
	existing, err := s.repo.GetUntriedChainSuggestions(ctx, userID, foodName)
	if err == nil && len(existing) >= count {
		return existing[:count], nil
	}

	// Get food profile if exists
	profile, _ := s.repo.GetFoodProfile(ctx, foodName)

	// Generate with AI
	suggestions, err := s.aiChainService.GenerateChainSuggestions(ctx, foodName, profile, count)
	if err != nil {
		return nil, err
	}

	// Save suggestions
	for i := range suggestions {
		suggestions[i].ID = uuid.New()
		suggestions[i].UserID = userID
		suggestions[i].CurrentFoodName = foodName
		suggestions[i].CreatedAt = time.Now()
		if err := s.repo.SaveChainSuggestion(ctx, &suggestions[i]); err != nil {
			return nil, err
		}
	}

	return suggestions, nil
}

func (s *service) RecordChainFeedback(ctx context.Context, suggestionID, userID uuid.UUID, req *RecordChainFeedbackRequest) error {
	return s.repo.UpdateChainFeedback(ctx, suggestionID, userID, req.WasLiked, req.Feedback, time.Now())
}

func (s *service) GetUserChainSuggestions(ctx context.Context, userID uuid.UUID, limit, offset int) ([]FoodChainSuggestion, error) {
	return s.repo.GetChainSuggestionsByUser(ctx, userID, limit, offset)
}

// Variation ideas

func (s *service) GetVariationIdeas(ctx context.Context, foodName string) ([]FoodVariation, error) {
	// Check if variations already exist
	existing, err := s.repo.GetFoodVariations(ctx, foodName)
	if err == nil && len(existing) > 0 {
		return existing, nil
	}

	// Generate with AI
	variations, err := s.aiChainService.GenerateVariationIdeas(ctx, foodName)
	if err != nil {
		return nil, err
	}

	// Save variations
	for i := range variations {
		variations[i].ID = uuid.New()
		variations[i].BaseFoodName = foodName
		variations[i].CreatedAt = time.Now()
		if err := s.repo.SaveFoodVariation(ctx, &variations[i]); err != nil {
			return nil, err
		}
	}

	return variations, nil
}

// Variety analysis

func (s *service) GetVarietyAnalysis(ctx context.Context, userID uuid.UUID) (*VarietyAnalysis, error) {
	// Get unique foods count
	unique7, err := s.repo.GetUniqueFoodsCount(ctx, userID, 7)
	if err != nil {
		return nil, err
	}

	unique30, err := s.repo.GetUniqueFoodsCount(ctx, userID, 30)
	if err != nil {
		return nil, err
	}

	// Get top foods
	topFoods, err := s.repo.GetTopFoods(ctx, userID, 30, 10)
	if err != nil {
		return nil, err
	}

	// Get active hyperfixations
	hyperfixations, _ := s.GetActiveHyperfixations(ctx, userID)

	// Calculate variety score (1-10)
	varietyScore := s.calculateVarietyScore(unique7, unique30, len(hyperfixations))

	// Generate rotation suggestions
	rotations := s.generateRotationSuggestions(topFoods, hyperfixations)

	return &VarietyAnalysis{
		UniqueFoodsLast7Days:  unique7,
		UniqueFoodsLast30Days: unique30,
		TopFoods:              topFoods,
		ActiveHyperfixations:  hyperfixations,
		SuggestedRotations:    rotations,
		VarietyScore:          varietyScore,
	}, nil
}

func (s *service) calculateVarietyScore(unique7, unique30, hyperfixationCount int) int {
	// Scoring logic:
	// - 10 unique foods in 7 days = score 10
	// - Active hyperfixations reduce score slightly
	// - More variety in 30 days is positive

	score := unique7 // Base score from weekly variety

	// Bonus for monthly variety
	if unique30 > 20 {
		score += 2
	} else if unique30 > 15 {
		score += 1
	}

	// Small reduction for hyperfixations (but not punitive)
	score -= (hyperfixationCount / 2)

	// Clamp to 1-10
	if score < 1 {
		score = 1
	}
	if score > 10 {
		score = 10
	}

	return score
}

func (s *service) generateRotationSuggestions(topFoods []FoodFrequency, hyperfixations []FoodHyperfixation) []string {
	suggestions := []string{}

	// Suggest rotation if someone is eating the same thing very often
	for _, food := range topFoods {
		if food.Percentage > 40 {
			suggestions = append(suggestions,
				fmt.Sprintf("Try alternating %s with a similar food to add variety", food.FoodName))
		}
	}

	// Gentle suggestion for hyperfixations
	if len(hyperfixations) > 0 {
		suggestions = append(suggestions,
			"You have some favorite foods you're eating often right now. That's totally okay! When you're ready, try a small variation.")
	}

	// If good variety, provide positive feedback
	if len(topFoods) > 0 && topFoods[0].Percentage < 30 {
		suggestions = append(suggestions,
			"You're doing great with food variety! Keep enjoying what works for you.")
	}

	return suggestions
}

// Nutrition settings

func (s *service) GetNutritionSettings(ctx context.Context, userID uuid.UUID) (*NutritionTrackingSettings, error) {
	return s.repo.GetOrCreateNutritionSettings(ctx, userID)
}

func (s *service) UpdateNutritionSettings(ctx context.Context, userID uuid.UUID, req *UpdateNutritionSettingsRequest) error {
	settings, err := s.GetNutritionSettings(ctx, userID)
	if err != nil {
		return err
	}

	// Apply updates (only update fields that are provided)
	if req.TrackingEnabled != nil {
		settings.TrackingEnabled = *req.TrackingEnabled
	}
	if req.ShowCalorieCounts != nil {
		settings.ShowCalorieCounts = *req.ShowCalorieCounts
	}
	if req.ShowMacros != nil {
		settings.ShowMacros = *req.ShowMacros
	}
	if req.ShowMicronutrients != nil {
		settings.ShowMicronutrients = *req.ShowMicronutrients
	}
	if req.FocusNutrients != nil {
		settings.FocusNutrients = req.FocusNutrients
	}
	if req.ShowWeeklySummary != nil {
		settings.ShowWeeklySummary = *req.ShowWeeklySummary
	}
	if req.ShowDailySummary != nil {
		settings.ShowDailySummary = *req.ShowDailySummary
	}
	if req.ReminderStyle != nil {
		settings.ReminderStyle = *req.ReminderStyle
	}

	return s.repo.UpdateNutritionSettings(ctx, settings)
}

// Nutrition insights

func (s *service) GenerateWeeklyInsights(ctx context.Context, userID uuid.UUID) ([]NutritionInsight, error) {
	settings, err := s.GetNutritionSettings(ctx, userID)
	if err != nil || !settings.TrackingEnabled || !settings.ShowWeeklySummary {
		return nil, nil
	}

	// Get current week start (Monday)
	now := time.Now()
	weekday := int(now.Weekday())
	if weekday == 0 {
		weekday = 7 // Sunday = 7
	}
	weekStart := now.AddDate(0, 0, -(weekday - 1)).Truncate(24 * time.Hour)

	// Generate gentle, non-judgmental insights
	insights := []NutritionInsight{}

	// Example insight: variety celebration
	varietyAnalysis, err := s.GetVarietyAnalysis(ctx, userID)
	if err == nil && varietyAnalysis.UniqueFoodsLast7Days > 7 {
		insights = append(insights, NutritionInsight{
			ID:            uuid.New(),
			UserID:        userID,
			WeekStartDate: weekStart,
			InsightType:   "variety_celebration",
			Message:       fmt.Sprintf("You tried %d different foods this week! That's great variety! 🎉", varietyAnalysis.UniqueFoodsLast7Days),
			IsDismissed:   false,
			CreatedAt:     time.Now(),
		})
	}

	// Save insights
	for i := range insights {
		if err := s.repo.CreateNutritionInsight(ctx, &insights[i]); err != nil {
			return nil, err
		}
	}

	return insights, nil
}

func (s *service) GetWeeklyInsights(ctx context.Context, userID uuid.UUID) ([]NutritionInsight, error) {
	// Get current week start
	now := time.Now()
	weekday := int(now.Weekday())
	if weekday == 0 {
		weekday = 7
	}
	weekStart := now.AddDate(0, 0, -(weekday - 1)).Truncate(24 * time.Hour)

	return s.repo.GetWeeklyInsights(ctx, userID, weekStart)
}

func (s *service) DismissInsight(ctx context.Context, insightID, userID uuid.UUID) error {
	return s.repo.DismissInsight(ctx, insightID, userID)
}

// Rotation schedules

func (s *service) CreateRotationSchedule(ctx context.Context, userID uuid.UUID, req *CreateRotationScheduleRequest) (*FoodRotationSchedule, error) {
	schedule := &FoodRotationSchedule{
		ID:           uuid.New(),
		UserID:       userID,
		ScheduleName: req.ScheduleName,
		RotationDays: req.RotationDays,
		Foods:        req.Foods,
		IsActive:     true,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	if err := s.repo.CreateRotationSchedule(ctx, schedule); err != nil {
		return nil, err
	}

	return schedule, nil
}

func (s *service) GetRotationSchedules(ctx context.Context, userID uuid.UUID) ([]FoodRotationSchedule, error) {
	return s.repo.GetUserRotationSchedules(ctx, userID)
}

func (s *service) UpdateRotationSchedule(ctx context.Context, scheduleID, userID uuid.UUID, req *UpdateRotationScheduleRequest) error {
	schedule, err := s.repo.GetRotationSchedule(ctx, scheduleID, userID)
	if err != nil {
		return err
	}

	// Apply updates
	if req.ScheduleName != nil {
		schedule.ScheduleName = *req.ScheduleName
	}
	if req.RotationDays != nil {
		schedule.RotationDays = *req.RotationDays
	}
	if req.Foods != nil {
		schedule.Foods = *req.Foods
	}
	if req.IsActive != nil {
		schedule.IsActive = *req.IsActive
	}

	schedule.UpdatedAt = time.Now()

	return s.repo.UpdateRotationSchedule(ctx, schedule)
}

func (s *service) DeleteRotationSchedule(ctx context.Context, scheduleID, userID uuid.UUID) error {
	return s.repo.DeleteRotationSchedule(ctx, scheduleID, userID)
}
