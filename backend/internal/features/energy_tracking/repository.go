// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

package energy_tracking

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// Repository handles data access for energy tracking
type Repository struct {
	db *sql.DB
}

// NewRepository creates a new energy tracking repository
func NewRepository(db *sql.DB) *Repository {
	return &Repository{db: db}
}

// Energy Snapshots

// RecordEnergySnapshot stores a new energy level recording
func (r *Repository) RecordEnergySnapshot(ctx context.Context, snapshot *EnergySnapshot) error {
	query := `
		INSERT INTO energy_snapshots (id, user_id, recorded_at, energy_level, time_of_day, day_of_week, context)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING created_at
	`
	return r.db.QueryRowContext(ctx, query,
		snapshot.ID, snapshot.UserID, snapshot.RecordedAt, snapshot.EnergyLevel,
		snapshot.TimeOfDay, snapshot.DayOfWeek, snapshot.Context,
	).Scan(&snapshot.CreatedAt)
}

// GetEnergySnapshots retrieves energy snapshots within a date range
func (r *Repository) GetEnergySnapshots(ctx context.Context, userID uuid.UUID, startDate, endDate time.Time) ([]EnergySnapshot, error) {
	query := `
		SELECT id, user_id, recorded_at, energy_level, time_of_day, day_of_week, context, created_at
		FROM energy_snapshots
		WHERE user_id = $1 AND recorded_at >= $2 AND recorded_at < $3
		ORDER BY recorded_at DESC
	`
	rows, err := r.db.QueryContext(ctx, query, userID, startDate, endDate)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var snapshots []EnergySnapshot
	for rows.Next() {
		var s EnergySnapshot
		if err := rows.Scan(&s.ID, &s.UserID, &s.RecordedAt, &s.EnergyLevel,
			&s.TimeOfDay, &s.DayOfWeek, &s.Context, &s.CreatedAt); err != nil {
			return nil, err
		}
		snapshots = append(snapshots, s)
	}
	return snapshots, rows.Err()
}

// Energy Patterns

// GetOrCreateEnergyPattern gets existing pattern or creates with default
func (r *Repository) GetOrCreateEnergyPattern(ctx context.Context, userID uuid.UUID, timeOfDay TimeOfDay, dayOfWeek int) (*UserEnergyPattern, error) {
	pattern := &UserEnergyPattern{
		ID:                 uuid.New(),
		UserID:             userID,
		TimeOfDay:          timeOfDay,
		DayOfWeek:          dayOfWeek,
		TypicalEnergyLevel: 3, // Default to moderate
		SampleCount:        1,
	}

	query := `
		INSERT INTO user_energy_patterns (id, user_id, time_of_day, day_of_week, typical_energy_level, sample_count)
		VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (user_id, time_of_day, day_of_week)
		DO UPDATE SET typical_energy_level = user_energy_patterns.typical_energy_level,
		              sample_count = user_energy_patterns.sample_count
		RETURNING id, user_id, time_of_day, day_of_week, typical_energy_level, sample_count, created_at, updated_at
	`

	err := r.db.QueryRowContext(ctx, query,
		pattern.ID, pattern.UserID, pattern.TimeOfDay, pattern.DayOfWeek,
		pattern.TypicalEnergyLevel, pattern.SampleCount,
	).Scan(&pattern.ID, &pattern.UserID, &pattern.TimeOfDay, &pattern.DayOfWeek,
		&pattern.TypicalEnergyLevel, &pattern.SampleCount, &pattern.CreatedAt, &pattern.UpdatedAt)

	return pattern, err
}

// UpdateEnergyPattern updates an existing energy pattern
func (r *Repository) UpdateEnergyPattern(ctx context.Context, pattern *UserEnergyPattern) error {
	query := `
		UPDATE user_energy_patterns
		SET typical_energy_level = $1, sample_count = $2, updated_at = NOW()
		WHERE user_id = $3 AND time_of_day = $4 AND day_of_week = $5
	`
	_, err := r.db.ExecContext(ctx, query,
		pattern.TypicalEnergyLevel, pattern.SampleCount,
		pattern.UserID, pattern.TimeOfDay, pattern.DayOfWeek,
	)
	return err
}

// GetUserEnergyPatterns retrieves all energy patterns for a user
func (r *Repository) GetUserEnergyPatterns(ctx context.Context, userID uuid.UUID) ([]UserEnergyPattern, error) {
	query := `
		SELECT id, user_id, time_of_day, day_of_week, typical_energy_level, sample_count, created_at, updated_at
		FROM user_energy_patterns
		WHERE user_id = $1
		ORDER BY day_of_week,
		         CASE time_of_day
		             WHEN 'morning' THEN 1
		             WHEN 'afternoon' THEN 2
		             WHEN 'evening' THEN 3
		             WHEN 'night' THEN 4
		         END
	`
	rows, err := r.db.QueryContext(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var patterns []UserEnergyPattern
	for rows.Next() {
		var p UserEnergyPattern
		if err := rows.Scan(&p.ID, &p.UserID, &p.TimeOfDay, &p.DayOfWeek,
			&p.TypicalEnergyLevel, &p.SampleCount, &p.CreatedAt, &p.UpdatedAt); err != nil {
			return nil, err
		}
		patterns = append(patterns, p)
	}
	return patterns, rows.Err()
}

// Favorite Meals

// SaveFavoriteMeal creates a new favorite meal
func (r *Repository) SaveFavoriteMeal(ctx context.Context, meal *FavoriteMeal) error {
	query := `
		INSERT INTO saved_favorite_meals (id, user_id, recipe_id, meal_name, energy_level, typical_time_of_day, notes)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING created_at, updated_at
	`
	return r.db.QueryRowContext(ctx, query,
		meal.ID, meal.UserID, meal.RecipeID, meal.MealName,
		meal.EnergyLevel, meal.TypicalTimeOfDay, meal.Notes,
	).Scan(&meal.CreatedAt, &meal.UpdatedAt)
}

// GetFavoriteMealByID retrieves a specific favorite meal
func (r *Repository) GetFavoriteMealByID(ctx context.Context, id, userID uuid.UUID) (*FavoriteMeal, error) {
	query := `
		SELECT id, user_id, recipe_id, meal_name, energy_level, typical_time_of_day,
		       frequency_score, last_eaten, notes, created_at, updated_at
		FROM saved_favorite_meals
		WHERE id = $1 AND user_id = $2
	`
	var m FavoriteMeal
	err := r.db.QueryRowContext(ctx, query, id, userID).Scan(
		&m.ID, &m.UserID, &m.RecipeID, &m.MealName, &m.EnergyLevel,
		&m.TypicalTimeOfDay, &m.FrequencyScore, &m.LastEaten,
		&m.Notes, &m.CreatedAt, &m.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &m, nil
}

// GetFavoriteMeals retrieves favorite meals with optional filtering
func (r *Repository) GetFavoriteMeals(ctx context.Context, userID uuid.UUID, energyLevel *int, timeOfDay *TimeOfDay, maxResults int) ([]FavoriteMeal, error) {
	query := `
		SELECT id, user_id, recipe_id, meal_name, energy_level, typical_time_of_day,
		       frequency_score, last_eaten, notes, created_at, updated_at
		FROM saved_favorite_meals
		WHERE user_id = $1
	`

	args := []interface{}{userID}
	argNum := 1

	if energyLevel != nil {
		argNum++
		query += fmt.Sprintf(" AND (energy_level IS NULL OR energy_level <= $%d)", argNum)
		args = append(args, *energyLevel)
	}

	if timeOfDay != nil {
		argNum++
		query += fmt.Sprintf(" AND (typical_time_of_day = $%d OR typical_time_of_day IS NULL)", argNum)
		args = append(args, string(*timeOfDay))
	}

	query += " ORDER BY frequency_score DESC, last_eaten DESC NULLS LAST"

	if maxResults > 0 {
		argNum++
		query += fmt.Sprintf(" LIMIT $%d", argNum)
		args = append(args, maxResults)
	}

	rows, err := r.db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var meals []FavoriteMeal
	for rows.Next() {
		var m FavoriteMeal
		if err := rows.Scan(&m.ID, &m.UserID, &m.RecipeID, &m.MealName,
			&m.EnergyLevel, &m.TypicalTimeOfDay, &m.FrequencyScore,
			&m.LastEaten, &m.Notes, &m.CreatedAt, &m.UpdatedAt); err != nil {
			return nil, err
		}
		meals = append(meals, m)
	}
	return meals, rows.Err()
}

// UpdateFavoriteMeal updates an existing favorite meal
func (r *Repository) UpdateFavoriteMeal(ctx context.Context, meal *FavoriteMeal) error {
	query := `
		UPDATE saved_favorite_meals
		SET meal_name = $1, energy_level = $2, typical_time_of_day = $3, notes = $4, updated_at = NOW()
		WHERE id = $5 AND user_id = $6
	`
	_, err := r.db.ExecContext(ctx, query,
		meal.MealName, meal.EnergyLevel, meal.TypicalTimeOfDay,
		meal.Notes, meal.ID, meal.UserID,
	)
	return err
}

// IncrementMealFrequency increments frequency score and updates last eaten
func (r *Repository) IncrementMealFrequency(ctx context.Context, mealID, userID uuid.UUID) error {
	query := `
		UPDATE saved_favorite_meals
		SET frequency_score = frequency_score + 1, last_eaten = NOW(), updated_at = NOW()
		WHERE id = $1 AND user_id = $2
	`
	result, err := r.db.ExecContext(ctx, query, mealID, userID)
	if err != nil {
		return err
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return err
	}
	if rows == 0 {
		return sql.ErrNoRows
	}

	return nil
}

// DeleteFavoriteMeal deletes a favorite meal
func (r *Repository) DeleteFavoriteMeal(ctx context.Context, id, userID uuid.UUID) error {
	query := `DELETE FROM saved_favorite_meals WHERE id = $1 AND user_id = $2`
	result, err := r.db.ExecContext(ctx, query, id, userID)
	if err != nil {
		return err
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return err
	}
	if rows == 0 {
		return sql.ErrNoRows
	}

	return nil
}

// GetRecipesByEnergyLevel retrieves recipes filtered by energy level
func (r *Repository) GetRecipesByEnergyLevel(ctx context.Context, userID uuid.UUID, maxEnergyLevel int, limit int) ([]RecipeWithEnergy, error) {
	query := `
		SELECT id, name, energy_level, preparation_time_minutes, active_time_minutes
		FROM recipes
		WHERE user_id = $1 AND energy_level IS NOT NULL AND energy_level <= $2
		ORDER BY energy_level ASC, preparation_time_minutes ASC NULLS LAST
		LIMIT $3
	`

	rows, err := r.db.QueryContext(ctx, query, userID, maxEnergyLevel, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var recipes []RecipeWithEnergy
	for rows.Next() {
		var r RecipeWithEnergy
		if err := rows.Scan(&r.ID, &r.Name, &r.EnergyLevel,
			&r.PreparationTimeMinutes, &r.ActiveTimeMinutes); err != nil {
			return nil, err
		}
		recipes = append(recipes, r)
	}
	return recipes, rows.Err()
}
