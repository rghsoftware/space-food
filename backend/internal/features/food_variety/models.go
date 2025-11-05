// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

package food_variety

import (
	"database/sql/driver"
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
)

// FoodHyperfixation tracks food hyperfixation patterns (non-judgmental)
type FoodHyperfixation struct {
	ID                  uuid.UUID  `json:"id" db:"id"`
	UserID              uuid.UUID  `json:"user_id" db:"user_id"`
	FoodName            string     `json:"food_name" db:"food_name"`
	StartedAt           time.Time  `json:"started_at" db:"started_at"`
	EndedAt             *time.Time `json:"ended_at,omitempty" db:"ended_at"`
	FrequencyCount      int        `json:"frequency_count" db:"frequency_count"`
	PeakFrequencyPerDay float64    `json:"peak_frequency_per_day" db:"peak_frequency_per_day"`
	IsActive            bool       `json:"is_active" db:"is_active"`
	Notes               string     `json:"notes,omitempty" db:"notes"`
	CreatedAt           time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt           time.Time  `json:"updated_at" db:"updated_at"`
}

// FoodProfile defines characteristics for food chaining
type FoodProfile struct {
	ID              uuid.UUID      `json:"id" db:"id"`
	FoodName        string         `json:"food_name" db:"food_name"`
	Texture         string         `json:"texture,omitempty" db:"texture"`
	FlavorProfile   string         `json:"flavor_profile,omitempty" db:"flavor_profile"`
	Temperature     string         `json:"temperature,omitempty" db:"temperature"`
	Complexity      int            `json:"complexity" db:"complexity"`
	CommonAllergens pq.StringArray `json:"common_allergens,omitempty" db:"common_allergens"`
	DietaryTags     pq.StringArray `json:"dietary_tags,omitempty" db:"dietary_tags"`
	CreatedAt       time.Time      `json:"created_at" db:"created_at"`
}

// FoodChainSuggestion represents an AI-generated food suggestion
type FoodChainSuggestion struct {
	ID                uuid.UUID  `json:"id" db:"id"`
	UserID            uuid.UUID  `json:"user_id" db:"user_id"`
	CurrentFoodName   string     `json:"current_food_name" db:"current_food_name"`
	SuggestedFoodName string     `json:"suggested_food_name" db:"suggested_food_name"`
	SimilarityScore   float64    `json:"similarity_score" db:"similarity_score"`
	Reasoning         string     `json:"reasoning" db:"reasoning"`
	WasTried          bool       `json:"was_tried" db:"was_tried"`
	WasLiked          *bool      `json:"was_liked,omitempty" db:"was_liked"`
	TriedAt           *time.Time `json:"tried_at,omitempty" db:"tried_at"`
	Feedback          string     `json:"feedback,omitempty" db:"feedback"`
	CreatedAt         time.Time  `json:"created_at" db:"created_at"`
}

// FoodVariation represents a simple variation of a familiar food
type FoodVariation struct {
	ID            uuid.UUID `json:"id" db:"id"`
	BaseFoodName  string    `json:"base_food_name" db:"base_food_name"`
	VariationType string    `json:"variation_type" db:"variation_type"` // sauce, topping, preparation, side
	VariationName string    `json:"variation_name" db:"variation_name"`
	Description   string    `json:"description,omitempty" db:"description"`
	Complexity    int       `json:"complexity" db:"complexity"`
	CreatedAt     time.Time `json:"created_at" db:"created_at"`
}

// NutritionTrackingSettings defines user preferences for nutrition tracking (opt-in)
type NutritionTrackingSettings struct {
	UserID             uuid.UUID      `json:"user_id" db:"user_id"`
	TrackingEnabled    bool           `json:"tracking_enabled" db:"tracking_enabled"`
	ShowCalorieCounts  bool           `json:"show_calorie_counts" db:"show_calorie_counts"`
	ShowMacros         bool           `json:"show_macros" db:"show_macros"`
	ShowMicronutrients bool           `json:"show_micronutrients" db:"show_micronutrients"`
	FocusNutrients     pq.StringArray `json:"focus_nutrients,omitempty" db:"focus_nutrients"`
	ShowWeeklySummary  bool           `json:"show_weekly_summary" db:"show_weekly_summary"`
	ShowDailySummary   bool           `json:"show_daily_summary" db:"show_daily_summary"`
	ReminderStyle      string         `json:"reminder_style" db:"reminder_style"` // gentle, disabled
	CreatedAt          time.Time      `json:"created_at" db:"created_at"`
	UpdatedAt          time.Time      `json:"updated_at" db:"updated_at"`
}

// NutritionInsight represents a gentle nutrition insight
type NutritionInsight struct {
	ID            uuid.UUID `json:"id" db:"id"`
	UserID        uuid.UUID `json:"user_id" db:"user_id"`
	WeekStartDate time.Time `json:"week_start_date" db:"week_start_date"`
	InsightType   string    `json:"insight_type" db:"insight_type"`
	Message       string    `json:"message" db:"message"`
	IsDismissed   bool      `json:"is_dismissed" db:"is_dismissed"`
	CreatedAt     time.Time `json:"created_at" db:"created_at"`
}

// FoodRotationSchedule represents an optional structured rotation
type FoodRotationSchedule struct {
	ID           uuid.UUID              `json:"id" db:"id"`
	UserID       uuid.UUID              `json:"user_id" db:"user_id"`
	ScheduleName string                 `json:"schedule_name" db:"schedule_name"`
	RotationDays int                    `json:"rotation_days" db:"rotation_days"`
	Foods        RotationFoodList       `json:"foods" db:"foods"`
	IsActive     bool                   `json:"is_active" db:"is_active"`
	CreatedAt    time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time              `json:"updated_at" db:"updated_at"`
}

// RotationFoodList is a custom type for JSONB array storage
type RotationFoodList []RotationFood

type RotationFood struct {
	Name string `json:"name"`
	Day  int    `json:"day,omitempty"`
}

// Value implements driver.Valuer for RotationFoodList
func (r RotationFoodList) Value() (driver.Value, error) {
	return json.Marshal(r)
}

// Scan implements sql.Scanner for RotationFoodList
func (r *RotationFoodList) Scan(value interface{}) error {
	if value == nil {
		return nil
	}
	bytes, ok := value.([]byte)
	if !ok {
		return json.Unmarshal([]byte(value.(string)), r)
	}
	return json.Unmarshal(bytes, r)
}

// LastEatenTracking tracks when foods were last eaten
type LastEatenTracking struct {
	UserID               uuid.UUID `json:"user_id" db:"user_id"`
	FoodName             string    `json:"food_name" db:"food_name"`
	LastEatenAt          time.Time `json:"last_eaten_at" db:"last_eaten_at"`
	TimesEatenLast7Days  int       `json:"times_eaten_last_7_days" db:"times_eaten_last_7_days"`
	TimesEatenLast30Days int       `json:"times_eaten_last_30_days" db:"times_eaten_last_30_days"`
	CreatedAt            time.Time `json:"created_at" db:"created_at"`
	UpdatedAt            time.Time `json:"updated_at" db:"updated_at"`
}

// VarietyAnalysis provides variety metrics
type VarietyAnalysis struct {
	UniqueFoodsLast7Days  int                  `json:"unique_foods_last_7_days"`
	UniqueFoodsLast30Days int                  `json:"unique_foods_last_30_days"`
	TopFoods              []FoodFrequency      `json:"top_foods"`
	ActiveHyperfixations  []FoodHyperfixation  `json:"active_hyperfixations,omitempty"`
	SuggestedRotations    []string             `json:"suggested_rotations"`
	VarietyScore          int                  `json:"variety_score"` // 1-10
}

// FoodFrequency represents how often a food is eaten
type FoodFrequency struct {
	FoodName   string  `json:"food_name"`
	Count      int     `json:"count"`
	Percentage float64 `json:"percentage"`
}

// Request/Response DTOs

// RecordHyperfixationRequest represents a request to record a hyperfixation
type RecordHyperfixationRequest struct {
	FoodName string `json:"food_name" binding:"required,min=1,max=200"`
	Notes    string `json:"notes,omitempty" binding:"max=500"`
}

// GenerateChainSuggestionsRequest represents a request to generate food chain suggestions
type GenerateChainSuggestionsRequest struct {
	FoodName       string `json:"food_name" binding:"required"`
	MaxSuggestions int    `json:"max_suggestions" binding:"min=1,max=10"`
}

// RecordChainFeedbackRequest represents feedback on a chain suggestion
type RecordChainFeedbackRequest struct {
	WasLiked bool   `json:"was_liked"`
	Feedback string `json:"feedback,omitempty" binding:"max=500"`
}

// UpdateNutritionSettingsRequest represents a request to update nutrition settings
type UpdateNutritionSettingsRequest struct {
	TrackingEnabled    *bool    `json:"tracking_enabled,omitempty"`
	ShowCalorieCounts  *bool    `json:"show_calorie_counts,omitempty"`
	ShowMacros         *bool    `json:"show_macros,omitempty"`
	ShowMicronutrients *bool    `json:"show_micronutrients,omitempty"`
	FocusNutrients     []string `json:"focus_nutrients,omitempty"`
	ShowWeeklySummary  *bool    `json:"show_weekly_summary,omitempty"`
	ShowDailySummary   *bool    `json:"show_daily_summary,omitempty"`
	ReminderStyle      *string  `json:"reminder_style,omitempty"`
}

// CreateRotationScheduleRequest represents a request to create a rotation schedule
type CreateRotationScheduleRequest struct {
	ScheduleName string           `json:"schedule_name" binding:"required,min=1,max=200"`
	RotationDays int              `json:"rotation_days" binding:"required,min=1,max=365"`
	Foods        RotationFoodList `json:"foods" binding:"required,min=1"`
}

// UpdateRotationScheduleRequest represents a request to update a rotation schedule
type UpdateRotationScheduleRequest struct {
	ScheduleName *string           `json:"schedule_name,omitempty" binding:"omitempty,min=1,max=200"`
	RotationDays *int              `json:"rotation_days,omitempty" binding:"omitempty,min=1,max=365"`
	Foods        *RotationFoodList `json:"foods,omitempty" binding:"omitempty,min=1"`
	IsActive     *bool             `json:"is_active,omitempty"`
}
