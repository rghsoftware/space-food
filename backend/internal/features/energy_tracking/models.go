// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

package energy_tracking

import (
	"time"

	"github.com/google/uuid"
)

// TimeOfDay represents different parts of the day
type TimeOfDay string

const (
	Morning   TimeOfDay = "morning"   // 5am-12pm
	Afternoon TimeOfDay = "afternoon" // 12pm-5pm
	Evening   TimeOfDay = "evening"   // 5pm-10pm
	Night     TimeOfDay = "night"     // 10pm-5am
)

// EnergyLevel constants for clarity
type EnergyLevel int

const (
	Exhausted EnergyLevel = 1 // Zero-prep meals only
	Depleted  EnergyLevel = 2 // Minimal effort, under 5 min
	Moderate  EnergyLevel = 3 // Simple cooking, 10-15 min
	Good      EnergyLevel = 4 // Can follow recipes
	Energized EnergyLevel = 5 // Complex meals, multiple steps
)

// UserEnergyPattern represents learned energy patterns by time and day
type UserEnergyPattern struct {
	ID                 uuid.UUID `json:"id" db:"id"`
	UserID             uuid.UUID `json:"user_id" db:"user_id"`
	TimeOfDay          TimeOfDay `json:"time_of_day" db:"time_of_day"`
	DayOfWeek          int       `json:"day_of_week" db:"day_of_week"` // 0=Sunday, 6=Saturday
	TypicalEnergyLevel int       `json:"typical_energy_level" db:"typical_energy_level"`
	SampleCount        int       `json:"sample_count" db:"sample_count"`
	CreatedAt          time.Time `json:"created_at" db:"created_at"`
	UpdatedAt          time.Time `json:"updated_at" db:"updated_at"`
}

// EnergySnapshot represents a single energy level recording
type EnergySnapshot struct {
	ID          uuid.UUID `json:"id" db:"id"`
	UserID      uuid.UUID `json:"user_id" db:"user_id"`
	RecordedAt  time.Time `json:"recorded_at" db:"recorded_at"`
	EnergyLevel int       `json:"energy_level" db:"energy_level"`
	TimeOfDay   TimeOfDay `json:"time_of_day" db:"time_of_day"`
	DayOfWeek   int       `json:"day_of_week" db:"day_of_week"`
	Context     string    `json:"context,omitempty" db:"context"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
}

// FavoriteMeal represents a user's saved favorite meal
type FavoriteMeal struct {
	ID               uuid.UUID  `json:"id" db:"id"`
	UserID           uuid.UUID  `json:"user_id" db:"user_id"`
	RecipeID         *uuid.UUID `json:"recipe_id,omitempty" db:"recipe_id"`
	MealName         string     `json:"meal_name" db:"meal_name"`
	EnergyLevel      *int       `json:"energy_level,omitempty" db:"energy_level"`
	TypicalTimeOfDay *string    `json:"typical_time_of_day,omitempty" db:"typical_time_of_day"`
	FrequencyScore   int        `json:"frequency_score" db:"frequency_score"`
	LastEaten        *time.Time `json:"last_eaten,omitempty" db:"last_eaten"`
	Notes            string     `json:"notes,omitempty" db:"notes"`
	CreatedAt        time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt        time.Time  `json:"updated_at" db:"updated_at"`
}

// EnergyBasedRecommendation contains meal recommendations based on energy
type EnergyBasedRecommendation struct {
	Meals         []FavoriteMeal `json:"meals"`
	CurrentEnergy int            `json:"current_energy"`
	TimeOfDay     TimeOfDay      `json:"time_of_day"`
	Reasoning     string         `json:"reasoning"`
}

// Request/Response DTOs

// RecordEnergyRequest for recording current energy level
type RecordEnergyRequest struct {
	EnergyLevel int    `json:"energy_level" binding:"required,min=1,max=5"`
	Context     string `json:"context" binding:"max=50"`
}

// SaveFavoriteMealRequest for saving a favorite meal
type SaveFavoriteMealRequest struct {
	RecipeID         *uuid.UUID `json:"recipe_id,omitempty"`
	MealName         string     `json:"meal_name" binding:"required,min=1,max=200"`
	EnergyLevel      *int       `json:"energy_level,omitempty" binding:"omitempty,min=1,max=5"`
	TypicalTimeOfDay *string    `json:"typical_time_of_day,omitempty"`
	Notes            string     `json:"notes,omitempty" binding:"max=500"`
}

// UpdateFavoriteMealRequest for updating a favorite meal
type UpdateFavoriteMealRequest struct {
	MealName         string     `json:"meal_name" binding:"required,min=1,max=200"`
	EnergyLevel      *int       `json:"energy_level,omitempty" binding:"omitempty,min=1,max=5"`
	TypicalTimeOfDay *string    `json:"typical_time_of_day,omitempty"`
	Notes            string     `json:"notes,omitempty" binding:"max=500"`
}

// GetMealsRequest for filtering favorite meals
type GetMealsRequest struct {
	EnergyLevel *int       `form:"energy_level" binding:"omitempty,min=1,max=5"`
	TimeOfDay   *TimeOfDay `form:"time_of_day"`
	MaxResults  int        `form:"max_results" binding:"omitempty,min=1,max=100"`
}

// EnergySnapshotsResponse for returning energy history
type EnergySnapshotsResponse struct {
	Snapshots []EnergySnapshot `json:"snapshots"`
	StartDate time.Time        `json:"start_date"`
	EndDate   time.Time        `json:"end_date"`
}

// RecipeWithEnergy represents a recipe with energy information
type RecipeWithEnergy struct {
	ID                      uuid.UUID `json:"id" db:"id"`
	Name                    string    `json:"name" db:"name"`
	EnergyLevel             *int      `json:"energy_level,omitempty" db:"energy_level"`
	PreparationTimeMinutes  *int      `json:"preparation_time_minutes,omitempty" db:"preparation_time_minutes"`
	ActiveTimeMinutes       *int      `json:"active_time_minutes,omitempty" db:"active_time_minutes"`
}
