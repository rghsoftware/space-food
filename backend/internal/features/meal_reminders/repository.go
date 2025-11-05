package meal_reminders

import (
	"context"
	"database/sql"
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
)

// Repository handles database operations for meal reminders
type Repository struct {
	db *sql.DB
}

// NewRepository creates a new meal reminders repository
func NewRepository(db *sql.DB) *Repository {
	return &Repository{db: db}
}

// Meal Reminder Operations

// CreateReminder creates a new meal reminder
func (r *Repository) CreateReminder(ctx context.Context, reminder *MealReminder) error {
	query := `
		INSERT INTO meal_reminders (
			id, user_id, name, scheduled_time, pre_alert_minutes, enabled, days_of_week
		) VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING created_at, updated_at
	`

	return r.db.QueryRowContext(
		ctx, query,
		reminder.ID, reminder.UserID, reminder.Name, reminder.ScheduledTime,
		reminder.PreAlertMinutes, reminder.Enabled, pq.Array(reminder.DaysOfWeek),
	).Scan(&reminder.CreatedAt, &reminder.UpdatedAt)
}

// GetUserReminders retrieves all reminders for a user
func (r *Repository) GetUserReminders(ctx context.Context, userID uuid.UUID) ([]MealReminder, error) {
	query := `
		SELECT id, user_id, name, scheduled_time, pre_alert_minutes, enabled, days_of_week, created_at, updated_at
		FROM meal_reminders
		WHERE user_id = $1
		ORDER BY scheduled_time ASC
	`

	rows, err := r.db.QueryContext(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var reminders []MealReminder
	for rows.Next() {
		var reminder MealReminder
		if err := rows.Scan(
			&reminder.ID, &reminder.UserID, &reminder.Name, &reminder.ScheduledTime,
			&reminder.PreAlertMinutes, &reminder.Enabled, pq.Array(&reminder.DaysOfWeek),
			&reminder.CreatedAt, &reminder.UpdatedAt,
		); err != nil {
			return nil, err
		}
		reminders = append(reminders, reminder)
	}

	return reminders, rows.Err()
}

// GetReminderByID retrieves a specific reminder
func (r *Repository) GetReminderByID(ctx context.Context, id, userID uuid.UUID) (*MealReminder, error) {
	query := `
		SELECT id, user_id, name, scheduled_time, pre_alert_minutes, enabled, days_of_week, created_at, updated_at
		FROM meal_reminders
		WHERE id = $1 AND user_id = $2
	`

	var reminder MealReminder
	err := r.db.QueryRowContext(ctx, query, id, userID).Scan(
		&reminder.ID, &reminder.UserID, &reminder.Name, &reminder.ScheduledTime,
		&reminder.PreAlertMinutes, &reminder.Enabled, pq.Array(&reminder.DaysOfWeek),
		&reminder.CreatedAt, &reminder.UpdatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}

	return &reminder, nil
}

// UpdateReminder updates an existing meal reminder
func (r *Repository) UpdateReminder(ctx context.Context, reminder *MealReminder) error {
	query := `
		UPDATE meal_reminders
		SET name = $1, scheduled_time = $2, pre_alert_minutes = $3,
			enabled = $4, days_of_week = $5, updated_at = NOW()
		WHERE id = $6 AND user_id = $7
	`

	result, err := r.db.ExecContext(
		ctx, query,
		reminder.Name, reminder.ScheduledTime, reminder.PreAlertMinutes,
		reminder.Enabled, pq.Array(reminder.DaysOfWeek), reminder.ID, reminder.UserID,
	)
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

// DeleteReminder deletes a meal reminder
func (r *Repository) DeleteReminder(ctx context.Context, id, userID uuid.UUID) error {
	query := `DELETE FROM meal_reminders WHERE id = $1 AND user_id = $2`

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

// Meal Log Operations

// CreateMealLog creates a new meal log entry
func (r *Repository) CreateMealLog(ctx context.Context, log *MealLog) error {
	query := `
		INSERT INTO meal_logs (
			id, user_id, reminder_id, logged_at, scheduled_for, notes, energy_level
		) VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING created_at
	`

	return r.db.QueryRowContext(
		ctx, query,
		log.ID, log.UserID, log.ReminderID, log.LoggedAt, log.ScheduledFor, log.Notes, log.EnergyLevel,
	).Scan(&log.CreatedAt)
}

// GetMealLogs retrieves meal logs for a user within a date range
func (r *Repository) GetMealLogs(ctx context.Context, userID uuid.UUID, startDate, endDate time.Time) ([]MealLog, error) {
	query := `
		SELECT id, user_id, reminder_id, logged_at, scheduled_for, notes, energy_level, created_at
		FROM meal_logs
		WHERE user_id = $1 AND logged_at >= $2 AND logged_at < $3
		ORDER BY logged_at DESC
	`

	rows, err := r.db.QueryContext(ctx, query, userID, startDate, endDate)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var logs []MealLog
	for rows.Next() {
		var log MealLog
		if err := rows.Scan(
			&log.ID, &log.UserID, &log.ReminderID, &log.LoggedAt,
			&log.ScheduledFor, &log.Notes, &log.EnergyLevel, &log.CreatedAt,
		); err != nil {
			return nil, err
		}
		logs = append(logs, log)
	}

	return logs, rows.Err()
}

// GetDailyLogCount gets the count of meals and snacks for a specific day
func (r *Repository) GetDailyLogCount(ctx context.Context, userID uuid.UUID, date time.Time) (*DailyLogCount, error) {
	// Count meals (Breakfast, Lunch, Dinner) vs snacks (everything else)
	query := `
		SELECT
			COUNT(*) FILTER (
				WHERE mr.name IN ('Breakfast', 'Lunch', 'Dinner')
			) as meals,
			COUNT(*) FILTER (
				WHERE mr.name IS NULL OR mr.name NOT IN ('Breakfast', 'Lunch', 'Dinner')
			) as snacks
		FROM meal_logs ml
		LEFT JOIN meal_reminders mr ON ml.reminder_id = mr.id
		WHERE ml.user_id = $1 AND DATE(ml.logged_at) = DATE($2)
	`

	var count DailyLogCount
	err := r.db.QueryRowContext(ctx, query, userID, date).Scan(&count.Meals, &count.Snacks)
	if err != nil {
		return nil, err
	}

	return &count, nil
}

// Eating Timeline Settings Operations

// GetTimelineSettings retrieves or creates timeline settings for a user
func (r *Repository) GetOrCreateTimelineSettings(ctx context.Context, userID uuid.UUID) (*EatingTimelineSettings, error) {
	settings := &EatingTimelineSettings{UserID: userID}

	query := `
		INSERT INTO eating_timeline_settings (user_id)
		VALUES ($1)
		ON CONFLICT (user_id) DO UPDATE SET user_id = EXCLUDED.user_id
		RETURNING user_id, daily_meal_goal, daily_snack_goal, show_streak, show_missed_meals, created_at, updated_at
	`

	err := r.db.QueryRowContext(ctx, query, userID).Scan(
		&settings.UserID, &settings.DailyMealGoal, &settings.DailySnackGoal,
		&settings.ShowStreak, &settings.ShowMissedMeals, &settings.CreatedAt, &settings.UpdatedAt,
	)

	return settings, err
}

// UpdateTimelineSettings updates timeline settings for a user
func (r *Repository) UpdateTimelineSettings(ctx context.Context, settings *EatingTimelineSettings) error {
	query := `
		UPDATE eating_timeline_settings
		SET daily_meal_goal = $1, daily_snack_goal = $2, show_streak = $3,
			show_missed_meals = $4, updated_at = NOW()
		WHERE user_id = $5
	`

	result, err := r.db.ExecContext(
		ctx, query,
		settings.DailyMealGoal, settings.DailySnackGoal, settings.ShowStreak,
		settings.ShowMissedMeals, settings.UserID,
	)
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
