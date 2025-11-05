package meal_reminders

import (
	"time"

	"github.com/google/uuid"
)

// MealReminder represents a recurring meal reminder
type MealReminder struct {
	ID              uuid.UUID `json:"id" db:"id"`
	UserID          uuid.UUID `json:"user_id" db:"user_id"`
	Name            string    `json:"name" db:"name"`
	ScheduledTime   string    `json:"scheduled_time" db:"scheduled_time"` // "08:00:00" format
	PreAlertMinutes int       `json:"pre_alert_minutes" db:"pre_alert_minutes"`
	Enabled         bool      `json:"enabled" db:"enabled"`
	DaysOfWeek      []int     `json:"days_of_week" db:"days_of_week"` // 0-6 (Sunday-Saturday)
	CreatedAt       time.Time `json:"created_at" db:"created_at"`
	UpdatedAt       time.Time `json:"updated_at" db:"updated_at"`
}

// MealLog represents a logged meal
type MealLog struct {
	ID           uuid.UUID  `json:"id" db:"id"`
	UserID       uuid.UUID  `json:"user_id" db:"user_id"`
	ReminderID   *uuid.UUID `json:"reminder_id,omitempty" db:"reminder_id"`
	LoggedAt     time.Time  `json:"logged_at" db:"logged_at"`
	ScheduledFor *time.Time `json:"scheduled_for,omitempty" db:"scheduled_for"`
	Notes        string     `json:"notes,omitempty" db:"notes"`
	EnergyLevel  *int       `json:"energy_level,omitempty" db:"energy_level"` // 1-5
	CreatedAt    time.Time  `json:"created_at" db:"created_at"`
}

// EatingTimelineSettings represents user preferences for timeline display
type EatingTimelineSettings struct {
	UserID          uuid.UUID `json:"user_id" db:"user_id"`
	DailyMealGoal   int       `json:"daily_meal_goal" db:"daily_meal_goal"`
	DailySnackGoal  int       `json:"daily_snack_goal" db:"daily_snack_goal"`
	ShowStreak      bool      `json:"show_streak" db:"show_streak"`
	ShowMissedMeals bool      `json:"show_missed_meals" db:"show_missed_meals"`
	CreatedAt       time.Time `json:"created_at" db:"created_at"`
	UpdatedAt       time.Time `json:"updated_at" db:"updated_at"`
}

// EatingTimeline represents a day's eating timeline
type EatingTimeline struct {
	Date         string    `json:"date"` // YYYY-MM-DD
	MealsLogged  int       `json:"meals_logged"`
	SnacksLogged int       `json:"snacks_logged"`
	MealGoal     int       `json:"meal_goal"`
	SnackGoal    int       `json:"snack_goal"`
	Logs         []MealLog `json:"logs"`
	StreakDays   int       `json:"streak_days,omitempty"`
}

// Request/Response DTOs

// CreateMealReminderRequest is the payload for creating a meal reminder
type CreateMealReminderRequest struct {
	Name            string `json:"name" binding:"required,min=1,max=100"`
	ScheduledTime   string `json:"scheduled_time" binding:"required"` // Will validate time format
	PreAlertMinutes int    `json:"pre_alert_minutes" binding:"min=0,max=60"`
	Enabled         bool   `json:"enabled"`
	DaysOfWeek      []int  `json:"days_of_week" binding:"required,min=1,dive,min=0,max=6"`
}

// UpdateMealReminderRequest is the payload for updating a meal reminder
type UpdateMealReminderRequest struct {
	Name            string `json:"name" binding:"required,min=1,max=100"`
	ScheduledTime   string `json:"scheduled_time" binding:"required"`
	PreAlertMinutes int    `json:"pre_alert_minutes" binding:"min=0,max=60"`
	Enabled         bool   `json:"enabled"`
	DaysOfWeek      []int  `json:"days_of_week" binding:"required,min=1,dive,min=0,max=6"`
}

// LogMealRequest is the payload for logging a meal
type LogMealRequest struct {
	ReminderID  *uuid.UUID `json:"reminder_id,omitempty"`
	Notes       string     `json:"notes,omitempty" binding:"max=500"`
	EnergyLevel *int       `json:"energy_level,omitempty" binding:"omitempty,min=1,max=5"`
}

// UpdateTimelineSettingsRequest is the payload for updating timeline settings
type UpdateTimelineSettingsRequest struct {
	DailyMealGoal   int  `json:"daily_meal_goal" binding:"min=0"`
	DailySnackGoal  int  `json:"daily_snack_goal" binding:"min=0"`
	ShowStreak      bool `json:"show_streak"`
	ShowMissedMeals bool `json:"show_missed_meals"`
}

// DailyLogCount represents meal/snack counts for a day
type DailyLogCount struct {
	Meals  int
	Snacks int
}
