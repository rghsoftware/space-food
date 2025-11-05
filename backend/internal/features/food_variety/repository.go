// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

package food_variety

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

// Repository defines the interface for food variety data operations
type Repository interface {
	// Hyperfixation tracking
	UpsertHyperfixation(ctx context.Context, userID uuid.UUID, foodName string, frequency int) error
	GetActiveHyperfixations(ctx context.Context, userID uuid.UUID) ([]FoodHyperfixation, error)
	EndHyperfixation(ctx context.Context, id uuid.UUID) error

	// Food profiles
	GetFoodProfile(ctx context.Context, foodName string) (*FoodProfile, error)
	CreateFoodProfile(ctx context.Context, profile *FoodProfile) error
	GetAllFoodProfiles(ctx context.Context, limit, offset int) ([]FoodProfile, error)

	// Food chain suggestions
	GetUntriedChainSuggestions(ctx context.Context, userID uuid.UUID, currentFood string) ([]FoodChainSuggestion, error)
	SaveChainSuggestion(ctx context.Context, suggestion *FoodChainSuggestion) error
	UpdateChainFeedback(ctx context.Context, id, userID uuid.UUID, wasLiked bool, feedback string, triedAt time.Time) error
	GetChainSuggestionsByUser(ctx context.Context, userID uuid.UUID, limit, offset int) ([]FoodChainSuggestion, error)

	// Food variations
	GetFoodVariations(ctx context.Context, baseFoodName string) ([]FoodVariation, error)
	SaveFoodVariation(ctx context.Context, variation *FoodVariation) error

	// Last eaten tracking
	UpdateLastEaten(ctx context.Context, userID uuid.UUID, foodName string) error
	GetFoodFrequency(ctx context.Context, userID uuid.UUID, foodName string, days int) (int, error)
	GetLastEatenTracking(ctx context.Context, userID uuid.UUID, foodName string) (*LastEatenTracking, error)

	// Variety analysis
	GetUniqueFoodsCount(ctx context.Context, userID uuid.UUID, days int) (int, error)
	GetTopFoods(ctx context.Context, userID uuid.UUID, days int, limit int) ([]FoodFrequency, error)

	// Nutrition settings
	GetOrCreateNutritionSettings(ctx context.Context, userID uuid.UUID) (*NutritionTrackingSettings, error)
	UpdateNutritionSettings(ctx context.Context, settings *NutritionTrackingSettings) error

	// Nutrition insights
	CreateNutritionInsight(ctx context.Context, insight *NutritionInsight) error
	GetWeeklyInsights(ctx context.Context, userID uuid.UUID, weekStart time.Time) ([]NutritionInsight, error)
	DismissInsight(ctx context.Context, id, userID uuid.UUID) error

	// Rotation schedules
	CreateRotationSchedule(ctx context.Context, schedule *FoodRotationSchedule) error
	GetUserRotationSchedules(ctx context.Context, userID uuid.UUID) ([]FoodRotationSchedule, error)
	GetRotationSchedule(ctx context.Context, id, userID uuid.UUID) (*FoodRotationSchedule, error)
	UpdateRotationSchedule(ctx context.Context, schedule *FoodRotationSchedule) error
	DeleteRotationSchedule(ctx context.Context, id, userID uuid.UUID) error
}

type repository struct {
	db *sqlx.DB
}

// NewRepository creates a new food variety repository
func NewRepository(db *sqlx.DB) Repository {
	return &repository{db: db}
}

// Hyperfixation operations

func (r *repository) UpsertHyperfixation(ctx context.Context, userID uuid.UUID, foodName string, frequency int) error {
	query := `
		INSERT INTO food_hyperfixations (
			id, user_id, food_name, started_at, frequency_count,
			peak_frequency_per_day, is_active, created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		ON CONFLICT (user_id, food_name) WHERE is_active = true
		DO UPDATE SET
			frequency_count = $5,
			peak_frequency_per_day = GREATEST(food_hyperfixations.peak_frequency_per_day, $6),
			updated_at = $9
	`
	peakPerDay := float64(frequency) / 7.0 // Approximate daily average
	now := time.Now()

	_, err := r.db.ExecContext(ctx, query,
		uuid.New(), userID, foodName, now, frequency,
		peakPerDay, true, now, now,
	)
	return err
}

func (r *repository) GetActiveHyperfixations(ctx context.Context, userID uuid.UUID) ([]FoodHyperfixation, error) {
	var hyperfixations []FoodHyperfixation
	query := `
		SELECT * FROM food_hyperfixations
		WHERE user_id = $1 AND is_active = true
		ORDER BY frequency_count DESC
	`
	err := r.db.SelectContext(ctx, &hyperfixations, query, userID)
	return hyperfixations, err
}

func (r *repository) EndHyperfixation(ctx context.Context, id uuid.UUID) error {
	query := `
		UPDATE food_hyperfixations
		SET is_active = false, ended_at = NOW(), updated_at = NOW()
		WHERE id = $1
	`
	_, err := r.db.ExecContext(ctx, query, id)
	return err
}

// Food profile operations

func (r *repository) GetFoodProfile(ctx context.Context, foodName string) (*FoodProfile, error) {
	var profile FoodProfile
	query := `SELECT * FROM food_profiles WHERE food_name = $1`
	err := r.db.GetContext(ctx, &profile, query, foodName)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &profile, err
}

func (r *repository) CreateFoodProfile(ctx context.Context, profile *FoodProfile) error {
	query := `
		INSERT INTO food_profiles (
			id, food_name, texture, flavor_profile, temperature,
			complexity, common_allergens, dietary_tags, created_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		ON CONFLICT (food_name) DO NOTHING
	`
	_, err := r.db.ExecContext(ctx, query,
		profile.ID, profile.FoodName, profile.Texture, profile.FlavorProfile,
		profile.Temperature, profile.Complexity, profile.CommonAllergens,
		profile.DietaryTags, profile.CreatedAt,
	)
	return err
}

func (r *repository) GetAllFoodProfiles(ctx context.Context, limit, offset int) ([]FoodProfile, error) {
	var profiles []FoodProfile
	query := `
		SELECT * FROM food_profiles
		ORDER BY food_name
		LIMIT $1 OFFSET $2
	`
	err := r.db.SelectContext(ctx, &profiles, query, limit, offset)
	return profiles, err
}

// Chain suggestion operations

func (r *repository) GetUntriedChainSuggestions(ctx context.Context, userID uuid.UUID, currentFood string) ([]FoodChainSuggestion, error) {
	var suggestions []FoodChainSuggestion
	query := `
		SELECT * FROM food_chain_suggestions
		WHERE user_id = $1 AND current_food_name = $2 AND was_tried = false
		ORDER BY similarity_score DESC
	`
	err := r.db.SelectContext(ctx, &suggestions, query, userID, currentFood)
	return suggestions, err
}

func (r *repository) SaveChainSuggestion(ctx context.Context, suggestion *FoodChainSuggestion) error {
	query := `
		INSERT INTO food_chain_suggestions (
			id, user_id, current_food_name, suggested_food_name,
			similarity_score, reasoning, was_tried, created_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`
	_, err := r.db.ExecContext(ctx, query,
		suggestion.ID, suggestion.UserID, suggestion.CurrentFoodName,
		suggestion.SuggestedFoodName, suggestion.SimilarityScore,
		suggestion.Reasoning, suggestion.WasTried, suggestion.CreatedAt,
	)
	return err
}

func (r *repository) UpdateChainFeedback(ctx context.Context, id, userID uuid.UUID, wasLiked bool, feedback string, triedAt time.Time) error {
	query := `
		UPDATE food_chain_suggestions
		SET was_tried = true, was_liked = $1, feedback = $2, tried_at = $3
		WHERE id = $4 AND user_id = $5
	`
	result, err := r.db.ExecContext(ctx, query, wasLiked, feedback, triedAt, id, userID)
	if err != nil {
		return err
	}
	rows, _ := result.RowsAffected()
	if rows == 0 {
		return fmt.Errorf("suggestion not found or access denied")
	}
	return nil
}

func (r *repository) GetChainSuggestionsByUser(ctx context.Context, userID uuid.UUID, limit, offset int) ([]FoodChainSuggestion, error) {
	var suggestions []FoodChainSuggestion
	query := `
		SELECT * FROM food_chain_suggestions
		WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`
	err := r.db.SelectContext(ctx, &suggestions, query, userID, limit, offset)
	return suggestions, err
}

// Variation operations

func (r *repository) GetFoodVariations(ctx context.Context, baseFoodName string) ([]FoodVariation, error) {
	var variations []FoodVariation
	query := `
		SELECT * FROM food_variations
		WHERE base_food_name = $1
		ORDER BY complexity ASC, variation_type
	`
	err := r.db.SelectContext(ctx, &variations, query, baseFoodName)
	return variations, err
}

func (r *repository) SaveFoodVariation(ctx context.Context, variation *FoodVariation) error {
	query := `
		INSERT INTO food_variations (
			id, base_food_name, variation_type, variation_name,
			description, complexity, created_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7)
	`
	_, err := r.db.ExecContext(ctx, query,
		variation.ID, variation.BaseFoodName, variation.VariationType,
		variation.VariationName, variation.Description, variation.Complexity,
		variation.CreatedAt,
	)
	return err
}

// Last eaten tracking operations

func (r *repository) UpdateLastEaten(ctx context.Context, userID uuid.UUID, foodName string) error {
	query := `
		INSERT INTO last_eaten_tracking (
			user_id, food_name, last_eaten_at,
			times_eaten_last_7_days, times_eaten_last_30_days,
			created_at, updated_at
		) VALUES ($1, $2, $3, 1, 1, $4, $4)
		ON CONFLICT (user_id, food_name) DO UPDATE SET
			last_eaten_at = $3,
			times_eaten_last_7_days = (
				SELECT COUNT(*) FROM meal_logs
				WHERE user_id = $1 AND food_name ILIKE '%' || $2 || '%'
				AND logged_at >= NOW() - INTERVAL '7 days'
			),
			times_eaten_last_30_days = (
				SELECT COUNT(*) FROM meal_logs
				WHERE user_id = $1 AND food_name ILIKE '%' || $2 || '%'
				AND logged_at >= NOW() - INTERVAL '30 days'
			),
			updated_at = $4
	`
	now := time.Now()
	_, err := r.db.ExecContext(ctx, query, userID, foodName, now, now)
	return err
}

func (r *repository) GetFoodFrequency(ctx context.Context, userID uuid.UUID, foodName string, days int) (int, error) {
	var count int
	query := `
		SELECT COALESCE(times_eaten_last_7_days, 0)
		FROM last_eaten_tracking
		WHERE user_id = $1 AND food_name = $2
	`
	if days == 30 {
		query = `
			SELECT COALESCE(times_eaten_last_30_days, 0)
			FROM last_eaten_tracking
			WHERE user_id = $1 AND food_name = $2
		`
	}
	err := r.db.GetContext(ctx, &count, query, userID, foodName)
	if err == sql.ErrNoRows {
		return 0, nil
	}
	return count, err
}

func (r *repository) GetLastEatenTracking(ctx context.Context, userID uuid.UUID, foodName string) (*LastEatenTracking, error) {
	var tracking LastEatenTracking
	query := `SELECT * FROM last_eaten_tracking WHERE user_id = $1 AND food_name = $2`
	err := r.db.GetContext(ctx, &tracking, query, userID, foodName)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &tracking, err
}

// Variety analysis operations

func (r *repository) GetUniqueFoodsCount(ctx context.Context, userID uuid.UUID, days int) (int, error) {
	var count int
	query := `
		SELECT COUNT(DISTINCT food_name)
		FROM last_eaten_tracking
		WHERE user_id = $1
		AND last_eaten_at >= NOW() - INTERVAL '1 day' * $2
	`
	err := r.db.GetContext(ctx, &count, query, userID, days)
	return count, err
}

func (r *repository) GetTopFoods(ctx context.Context, userID uuid.UUID, days int, limit int) ([]FoodFrequency, error) {
	var foods []struct {
		FoodName string `db:"food_name"`
		Count    int    `db:"count"`
	}

	query := `
		SELECT food_name,
		       CASE WHEN $2 = 7 THEN times_eaten_last_7_days
		            ELSE times_eaten_last_30_days END as count
		FROM last_eaten_tracking
		WHERE user_id = $1
		AND last_eaten_at >= NOW() - INTERVAL '1 day' * $2
		ORDER BY count DESC
		LIMIT $3
	`
	err := r.db.SelectContext(ctx, &foods, query, userID, days, limit)
	if err != nil {
		return nil, err
	}

	// Calculate total for percentages
	var total int
	for _, f := range foods {
		total += f.Count
	}

	frequencies := make([]FoodFrequency, len(foods))
	for i, f := range foods {
		percentage := 0.0
		if total > 0 {
			percentage = (float64(f.Count) / float64(total)) * 100
		}
		frequencies[i] = FoodFrequency{
			FoodName:   f.FoodName,
			Count:      f.Count,
			Percentage: percentage,
		}
	}

	return frequencies, nil
}

// Nutrition settings operations

func (r *repository) GetOrCreateNutritionSettings(ctx context.Context, userID uuid.UUID) (*NutritionTrackingSettings, error) {
	var settings NutritionTrackingSettings
	query := `SELECT * FROM nutrition_tracking_settings WHERE user_id = $1`
	err := r.db.GetContext(ctx, &settings, query, userID)
	if err == sql.ErrNoRows {
		// Create default settings
		settings = NutritionTrackingSettings{
			UserID:             userID,
			TrackingEnabled:    false,
			ShowCalorieCounts:  false,
			ShowMacros:         false,
			ShowMicronutrients: false,
			ShowWeeklySummary:  true,
			ShowDailySummary:   false,
			ReminderStyle:      "gentle",
			CreatedAt:          time.Now(),
			UpdatedAt:          time.Now(),
		}
		insertQuery := `
			INSERT INTO nutrition_tracking_settings (
				user_id, tracking_enabled, show_calorie_counts, show_macros,
				show_micronutrients, show_weekly_summary, show_daily_summary,
				reminder_style, created_at, updated_at
			) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		`
		_, err = r.db.ExecContext(ctx, insertQuery,
			settings.UserID, settings.TrackingEnabled, settings.ShowCalorieCounts,
			settings.ShowMacros, settings.ShowMicronutrients, settings.ShowWeeklySummary,
			settings.ShowDailySummary, settings.ReminderStyle,
			settings.CreatedAt, settings.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
	}
	return &settings, nil
}

func (r *repository) UpdateNutritionSettings(ctx context.Context, settings *NutritionTrackingSettings) error {
	query := `
		UPDATE nutrition_tracking_settings
		SET tracking_enabled = $1, show_calorie_counts = $2, show_macros = $3,
		    show_micronutrients = $4, focus_nutrients = $5, show_weekly_summary = $6,
		    show_daily_summary = $7, reminder_style = $8, updated_at = $9
		WHERE user_id = $10
	`
	_, err := r.db.ExecContext(ctx, query,
		settings.TrackingEnabled, settings.ShowCalorieCounts, settings.ShowMacros,
		settings.ShowMicronutrients, settings.FocusNutrients, settings.ShowWeeklySummary,
		settings.ShowDailySummary, settings.ReminderStyle, time.Now(), settings.UserID,
	)
	return err
}

// Nutrition insight operations

func (r *repository) CreateNutritionInsight(ctx context.Context, insight *NutritionInsight) error {
	query := `
		INSERT INTO nutrition_insights (
			id, user_id, week_start_date, insight_type, message, created_at
		) VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (user_id, week_start_date, insight_type) DO UPDATE
		SET message = $5
	`
	_, err := r.db.ExecContext(ctx, query,
		insight.ID, insight.UserID, insight.WeekStartDate,
		insight.InsightType, insight.Message, insight.CreatedAt,
	)
	return err
}

func (r *repository) GetWeeklyInsights(ctx context.Context, userID uuid.UUID, weekStart time.Time) ([]NutritionInsight, error) {
	var insights []NutritionInsight
	query := `
		SELECT * FROM nutrition_insights
		WHERE user_id = $1 AND week_start_date = $2 AND is_dismissed = false
		ORDER BY created_at DESC
	`
	err := r.db.SelectContext(ctx, &insights, query, userID, weekStart)
	return insights, err
}

func (r *repository) DismissInsight(ctx context.Context, id, userID uuid.UUID) error {
	query := `
		UPDATE nutrition_insights
		SET is_dismissed = true
		WHERE id = $1 AND user_id = $2
	`
	_, err := r.db.ExecContext(ctx, query, id, userID)
	return err
}

// Rotation schedule operations

func (r *repository) CreateRotationSchedule(ctx context.Context, schedule *FoodRotationSchedule) error {
	query := `
		INSERT INTO food_rotation_schedules (
			id, user_id, schedule_name, rotation_days, foods,
			is_active, created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`
	_, err := r.db.ExecContext(ctx, query,
		schedule.ID, schedule.UserID, schedule.ScheduleName,
		schedule.RotationDays, schedule.Foods, schedule.IsActive,
		schedule.CreatedAt, schedule.UpdatedAt,
	)
	return err
}

func (r *repository) GetUserRotationSchedules(ctx context.Context, userID uuid.UUID) ([]FoodRotationSchedule, error) {
	var schedules []FoodRotationSchedule
	query := `
		SELECT * FROM food_rotation_schedules
		WHERE user_id = $1
		ORDER BY is_active DESC, created_at DESC
	`
	err := r.db.SelectContext(ctx, &schedules, query, userID)
	return schedules, err
}

func (r *repository) GetRotationSchedule(ctx context.Context, id, userID uuid.UUID) (*FoodRotationSchedule, error) {
	var schedule FoodRotationSchedule
	query := `SELECT * FROM food_rotation_schedules WHERE id = $1 AND user_id = $2`
	err := r.db.GetContext(ctx, &schedule, query, id, userID)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("rotation schedule not found")
	}
	return &schedule, err
}

func (r *repository) UpdateRotationSchedule(ctx context.Context, schedule *FoodRotationSchedule) error {
	query := `
		UPDATE food_rotation_schedules
		SET schedule_name = $1, rotation_days = $2, foods = $3,
		    is_active = $4, updated_at = $5
		WHERE id = $6 AND user_id = $7
	`
	_, err := r.db.ExecContext(ctx, query,
		schedule.ScheduleName, schedule.RotationDays, schedule.Foods,
		schedule.IsActive, time.Now(), schedule.ID, schedule.UserID,
	)
	return err
}

func (r *repository) DeleteRotationSchedule(ctx context.Context, id, userID uuid.UUID) error {
	query := `DELETE FROM food_rotation_schedules WHERE id = $1 AND user_id = $2`
	result, err := r.db.ExecContext(ctx, query, id, userID)
	if err != nil {
		return err
	}
	rows, _ := result.RowsAffected()
	if rows == 0 {
		return fmt.Errorf("rotation schedule not found or access denied")
	}
	return nil
}
