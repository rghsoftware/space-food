package meal_reminders

import (
	"context"
	"fmt"
	"regexp"
	"time"

	"github.com/google/uuid"
)

// Service handles business logic for meal reminders
type Service struct {
	repo *Repository
}

// NewService creates a new meal reminders service
func NewService(repo *Repository) *Service {
	return &Service{repo: repo}
}

// Time format validator
var timeFormatRegex = regexp.MustCompile(`^([0-1][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$`)

// ValidateTimeFormat validates HH:MM:SS time format
func (s *Service) ValidateTimeFormat(timeStr string) error {
	if !timeFormatRegex.MatchString(timeStr) {
		return fmt.Errorf("invalid time format, expected HH:MM:SS")
	}
	return nil
}

// Meal Reminder Operations

// CreateReminder creates a new meal reminder
func (s *Service) CreateReminder(ctx context.Context, userID uuid.UUID, req CreateMealReminderRequest) (*MealReminder, error) {
	if err := s.ValidateTimeFormat(req.ScheduledTime); err != nil {
		return nil, err
	}

	reminder := &MealReminder{
		ID:              uuid.New(),
		UserID:          userID,
		Name:            req.Name,
		ScheduledTime:   req.ScheduledTime,
		PreAlertMinutes: req.PreAlertMinutes,
		Enabled:         req.Enabled,
		DaysOfWeek:      req.DaysOfWeek,
	}

	if err := s.repo.CreateReminder(ctx, reminder); err != nil {
		return nil, err
	}

	return reminder, nil
}

// GetUserReminders retrieves all reminders for a user
func (s *Service) GetUserReminders(ctx context.Context, userID uuid.UUID) ([]MealReminder, error) {
	return s.repo.GetUserReminders(ctx, userID)
}

// GetReminder retrieves a specific reminder
func (s *Service) GetReminder(ctx context.Context, id, userID uuid.UUID) (*MealReminder, error) {
	return s.repo.GetReminderByID(ctx, id, userID)
}

// UpdateReminder updates an existing meal reminder
func (s *Service) UpdateReminder(ctx context.Context, id, userID uuid.UUID, req UpdateMealReminderRequest) (*MealReminder, error) {
	if err := s.ValidateTimeFormat(req.ScheduledTime); err != nil {
		return nil, err
	}

	reminder := &MealReminder{
		ID:              id,
		UserID:          userID,
		Name:            req.Name,
		ScheduledTime:   req.ScheduledTime,
		PreAlertMinutes: req.PreAlertMinutes,
		Enabled:         req.Enabled,
		DaysOfWeek:      req.DaysOfWeek,
	}

	if err := s.repo.UpdateReminder(ctx, reminder); err != nil {
		return nil, err
	}

	// Fetch updated reminder
	return s.repo.GetReminderByID(ctx, id, userID)
}

// DeleteReminder deletes a meal reminder
func (s *Service) DeleteReminder(ctx context.Context, id, userID uuid.UUID) error {
	return s.repo.DeleteReminder(ctx, id, userID)
}

// Meal Log Operations

// LogMeal creates a new meal log entry
func (s *Service) LogMeal(ctx context.Context, userID uuid.UUID, req LogMealRequest) (*MealLog, error) {
	now := time.Now()

	log := &MealLog{
		ID:          uuid.New(),
		UserID:      userID,
		ReminderID:  req.ReminderID,
		LoggedAt:    now,
		Notes:       req.Notes,
		EnergyLevel: req.EnergyLevel,
	}

	// If logging from a reminder, calculate the scheduled time
	if req.ReminderID != nil {
		reminder, err := s.repo.GetReminderByID(ctx, *req.ReminderID, userID)
		if err == nil && reminder != nil {
			scheduledFor := s.calculateScheduledTime(now, reminder.ScheduledTime)
			log.ScheduledFor = &scheduledFor
		}
	}

	if err := s.repo.CreateMealLog(ctx, log); err != nil {
		return nil, err
	}

	return log, nil
}

// calculateScheduledTime calculates the scheduled time for today based on time string
func (s *Service) calculateScheduledTime(now time.Time, timeStr string) time.Time {
	// Parse time string HH:MM:SS
	var hour, minute, second int
	fmt.Sscanf(timeStr, "%d:%d:%d", &hour, &minute, &second)

	return time.Date(
		now.Year(), now.Month(), now.Day(),
		hour, minute, second, 0, now.Location(),
	)
}

// GetMealLogs retrieves meal logs for a date range
func (s *Service) GetMealLogs(ctx context.Context, userID uuid.UUID, startDate, endDate time.Time) ([]MealLog, error) {
	return s.repo.GetMealLogs(ctx, userID, startDate, endDate)
}

// GetEatingTimeline generates eating timeline for a date range
func (s *Service) GetEatingTimeline(ctx context.Context, userID uuid.UUID, startDate, endDate time.Time) ([]EatingTimeline, error) {
	// Get timeline settings
	settings, err := s.repo.GetOrCreateTimelineSettings(ctx, userID)
	if err != nil {
		return nil, err
	}

	// Get logs for the date range
	logs, err := s.repo.GetMealLogs(ctx, userID, startDate, endDate)
	if err != nil {
		return nil, err
	}

	// Group logs by date
	timelineMap := make(map[string]*EatingTimeline)

	for _, log := range logs {
		dateStr := log.LoggedAt.Format("2006-01-02")

		if _, exists := timelineMap[dateStr]; !exists {
			// Get daily counts
			count, err := s.repo.GetDailyLogCount(ctx, userID, log.LoggedAt)
			if err != nil {
				continue
			}

			timelineMap[dateStr] = &EatingTimeline{
				Date:         dateStr,
				MealsLogged:  count.Meals,
				SnacksLogged: count.Snacks,
				MealGoal:     settings.DailyMealGoal,
				SnackGoal:    settings.DailySnackGoal,
				Logs:         []MealLog{},
			}
		}

		timelineMap[dateStr].Logs = append(timelineMap[dateStr].Logs, log)
	}

	// Convert map to sorted slice
	var timeline []EatingTimeline
	currentDate := startDate
	for currentDate.Before(endDate) {
		dateStr := currentDate.Format("2006-01-02")
		if day, exists := timelineMap[dateStr]; exists {
			timeline = append(timeline, *day)
		} else {
			// Include empty days
			timeline = append(timeline, EatingTimeline{
				Date:         dateStr,
				MealsLogged:  0,
				SnacksLogged: 0,
				MealGoal:     settings.DailyMealGoal,
				SnackGoal:    settings.DailySnackGoal,
				Logs:         []MealLog{},
			})
		}
		currentDate = currentDate.AddDate(0, 0, 1)
	}

	// Calculate streak if enabled
	if settings.ShowStreak {
		streak := s.calculateStreak(timeline, settings)
		if len(timeline) > 0 && streak > 0 {
			timeline[0].StreakDays = streak
		}
	}

	return timeline, nil
}

// calculateStreak calculates consecutive days meeting goals
func (s *Service) calculateStreak(timeline []EatingTimeline, settings *EatingTimelineSettings) int {
	streak := 0
	for i := len(timeline) - 1; i >= 0; i-- {
		day := timeline[i]
		if day.MealsLogged >= settings.DailyMealGoal && day.SnacksLogged >= settings.DailySnackGoal {
			streak++
		} else {
			break
		}
	}
	return streak
}

// Timeline Settings Operations

// GetTimelineSettings retrieves timeline settings for a user
func (s *Service) GetTimelineSettings(ctx context.Context, userID uuid.UUID) (*EatingTimelineSettings, error) {
	return s.repo.GetOrCreateTimelineSettings(ctx, userID)
}

// UpdateTimelineSettings updates timeline settings
func (s *Service) UpdateTimelineSettings(ctx context.Context, userID uuid.UUID, req UpdateTimelineSettingsRequest) (*EatingTimelineSettings, error) {
	settings := &EatingTimelineSettings{
		UserID:          userID,
		DailyMealGoal:   req.DailyMealGoal,
		DailySnackGoal:  req.DailySnackGoal,
		ShowStreak:      req.ShowStreak,
		ShowMissedMeals: req.ShowMissedMeals,
	}

	if err := s.repo.UpdateTimelineSettings(ctx, settings); err != nil {
		return nil, err
	}

	return s.repo.GetOrCreateTimelineSettings(ctx, userID)
}
