// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

package cooking_assistant

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

// Repository defines the interface for cooking assistant data operations
type Repository interface {
	// Breakdowns
	GetBreakdown(ctx context.Context, recipeID uuid.UUID, granularity int, energyLevel *int) (*RecipeBreakdown, error)
	CreateBreakdown(ctx context.Context, breakdown *RecipeBreakdown) error
	UpdateBreakdownUsage(ctx context.Context, id uuid.UUID) error

	// Cooking Sessions
	CreateCookingSession(ctx context.Context, session *CookingSession) error
	GetCookingSession(ctx context.Context, id uuid.UUID) (*CookingSession, error)
	GetCookingSessionByUserAndID(ctx context.Context, userID, sessionID uuid.UUID) (*CookingSession, error)
	GetActiveCookingSession(ctx context.Context, userID uuid.UUID) (*CookingSession, error)
	UpdateSessionProgress(ctx context.Context, id uuid.UUID, stepIndex int, notes string) error
	PauseSession(ctx context.Context, id uuid.UUID) error
	ResumeSession(ctx context.Context, id uuid.UUID) error
	CompleteSession(ctx context.Context, id uuid.UUID) error
	AbandonSession(ctx context.Context, id uuid.UUID) error
	GetUserCookingSessions(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*CookingSession, error)

	// Step Completions
	CompleteStep(ctx context.Context, completion *CookingStepCompletion) error
	GetSessionStepCompletions(ctx context.Context, sessionID uuid.UUID) ([]*CookingStepCompletion, error)

	// Timers
	CreateTimer(ctx context.Context, timer *CookingTimer) error
	GetSessionTimers(ctx context.Context, sessionID uuid.UUID) ([]*CookingTimer, error)
	GetTimer(ctx context.Context, id uuid.UUID) (*CookingTimer, error)
	UpdateTimer(ctx context.Context, timer *CookingTimer) error
	PauseTimer(ctx context.Context, id uuid.UUID) error
	ResumeTimer(ctx context.Context, id uuid.UUID) error
	CompleteTimer(ctx context.Context, id uuid.UUID) error
	CancelTimer(ctx context.Context, id uuid.UUID) error

	// Body Doubling Rooms
	CreateRoom(ctx context.Context, room *BodyDoublingRoom) error
	GetRoom(ctx context.Context, id uuid.UUID) (*BodyDoublingRoom, error)
	GetRoomByCode(ctx context.Context, code string) (*BodyDoublingRoom, error)
	GetPublicRooms(ctx context.Context, limit, offset int) ([]*BodyDoublingRoom, error)
	EndRoom(ctx context.Context, id uuid.UUID) error

	// Body Doubling Participants
	JoinRoom(ctx context.Context, participant *BodyDoublingParticipant) error
	LeaveRoom(ctx context.Context, roomID, userID uuid.UUID) error
	GetRoomParticipants(ctx context.Context, roomID uuid.UUID) ([]*BodyDoublingParticipant, error)
	GetRoomParticipantCount(ctx context.Context, roomID uuid.UUID) (int, error)
	UpdateParticipantActivity(ctx context.Context, roomID, userID uuid.UUID, currentStep string, energyLevel *int) error
}

type repository struct {
	db *sqlx.DB
}

// NewRepository creates a new cooking assistant repository
func NewRepository(db *sqlx.DB) Repository {
	return &repository{db: db}
}

// Breakdown operations

func (r *repository) GetBreakdown(ctx context.Context, recipeID uuid.UUID, granularity int, energyLevel *int) (*RecipeBreakdown, error) {
	var breakdown RecipeBreakdown
	query := `
		SELECT * FROM recipe_breakdowns
		WHERE recipe_id = $1 AND granularity_level = $2 AND energy_level IS NOT DISTINCT FROM $3
		ORDER BY generated_at DESC
		LIMIT 1
	`
	err := r.db.GetContext(ctx, &breakdown, query, recipeID, granularity, energyLevel)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &breakdown, err
}

func (r *repository) CreateBreakdown(ctx context.Context, breakdown *RecipeBreakdown) error {
	query := `
		INSERT INTO recipe_breakdowns (
			id, recipe_id, user_id, granularity_level, energy_level,
			breakdown_data, ai_provider, ai_model, generated_at,
			use_count, created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
	`
	_, err := r.db.ExecContext(ctx, query,
		breakdown.ID, breakdown.RecipeID, breakdown.UserID,
		breakdown.GranularityLevel, breakdown.EnergyLevel,
		breakdown.BreakdownData, breakdown.AIProvider, breakdown.AIModel,
		breakdown.GeneratedAt, breakdown.UseCount,
		breakdown.CreatedAt, breakdown.UpdatedAt,
	)
	return err
}

func (r *repository) UpdateBreakdownUsage(ctx context.Context, id uuid.UUID) error {
	query := `
		UPDATE recipe_breakdowns
		SET use_count = use_count + 1, last_used_at = NOW(), updated_at = NOW()
		WHERE id = $1
	`
	_, err := r.db.ExecContext(ctx, query, id)
	return err
}

// Cooking Session operations

func (r *repository) CreateCookingSession(ctx context.Context, session *CookingSession) error {
	query := `
		INSERT INTO cooking_sessions (
			id, user_id, recipe_id, breakdown_id, meal_log_id,
			status, current_step_index, total_steps, started_at,
			total_pause_duration_seconds, energy_level_at_start,
			notes, body_doubling_room_id, created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
	`
	_, err := r.db.ExecContext(ctx, query,
		session.ID, session.UserID, session.RecipeID, session.BreakdownID,
		session.MealLogID, session.Status, session.CurrentStepIndex,
		session.TotalSteps, session.StartedAt, session.TotalPauseDurationSeconds,
		session.EnergyLevelAtStart, session.Notes, session.BodyDoublingRoomID,
		session.CreatedAt, session.UpdatedAt,
	)
	return err
}

func (r *repository) GetCookingSession(ctx context.Context, id uuid.UUID) (*CookingSession, error) {
	var session CookingSession
	query := `SELECT * FROM cooking_sessions WHERE id = $1`
	err := r.db.GetContext(ctx, &session, query, id)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("cooking session not found")
	}
	return &session, err
}

func (r *repository) GetCookingSessionByUserAndID(ctx context.Context, userID, sessionID uuid.UUID) (*CookingSession, error) {
	var session CookingSession
	query := `SELECT * FROM cooking_sessions WHERE id = $1 AND user_id = $2`
	err := r.db.GetContext(ctx, &session, query, sessionID, userID)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("cooking session not found")
	}
	return &session, err
}

func (r *repository) GetActiveCookingSession(ctx context.Context, userID uuid.UUID) (*CookingSession, error) {
	var session CookingSession
	query := `
		SELECT * FROM cooking_sessions
		WHERE user_id = $1 AND status IN ('active', 'paused')
		ORDER BY started_at DESC
		LIMIT 1
	`
	err := r.db.GetContext(ctx, &session, query, userID)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &session, err
}

func (r *repository) UpdateSessionProgress(ctx context.Context, id uuid.UUID, stepIndex int, notes string) error {
	query := `
		UPDATE cooking_sessions
		SET current_step_index = $1, notes = $2, updated_at = NOW()
		WHERE id = $3
	`
	_, err := r.db.ExecContext(ctx, query, stepIndex, notes, id)
	return err
}

func (r *repository) PauseSession(ctx context.Context, id uuid.UUID) error {
	query := `
		UPDATE cooking_sessions
		SET status = 'paused', paused_at = NOW(), updated_at = NOW()
		WHERE id = $1 AND status = 'active'
	`
	result, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return err
	}
	rows, _ := result.RowsAffected()
	if rows == 0 {
		return fmt.Errorf("session not found or not active")
	}
	return nil
}

func (r *repository) ResumeSession(ctx context.Context, id uuid.UUID) error {
	query := `
		UPDATE cooking_sessions
		SET status = 'active',
		    resumed_at = NOW(),
		    total_pause_duration_seconds = total_pause_duration_seconds +
		        EXTRACT(EPOCH FROM (NOW() - paused_at))::INTEGER,
		    updated_at = NOW()
		WHERE id = $1 AND status = 'paused'
	`
	result, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return err
	}
	rows, _ := result.RowsAffected()
	if rows == 0 {
		return fmt.Errorf("session not found or not paused")
	}
	return nil
}

func (r *repository) CompleteSession(ctx context.Context, id uuid.UUID) error {
	query := `
		UPDATE cooking_sessions
		SET status = 'completed', completed_at = NOW(), updated_at = NOW()
		WHERE id = $1 AND status IN ('active', 'paused')
	`
	result, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return err
	}
	rows, _ := result.RowsAffected()
	if rows == 0 {
		return fmt.Errorf("session not found or already completed")
	}
	return nil
}

func (r *repository) AbandonSession(ctx context.Context, id uuid.UUID) error {
	query := `
		UPDATE cooking_sessions
		SET status = 'abandoned', abandoned_at = NOW(), updated_at = NOW()
		WHERE id = $1 AND status IN ('active', 'paused')
	`
	result, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return err
	}
	rows, _ := result.RowsAffected()
	if rows == 0 {
		return fmt.Errorf("session not found or already finished")
	}
	return nil
}

func (r *repository) GetUserCookingSessions(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*CookingSession, error) {
	var sessions []*CookingSession
	query := `
		SELECT * FROM cooking_sessions
		WHERE user_id = $1
		ORDER BY started_at DESC
		LIMIT $2 OFFSET $3
	`
	err := r.db.SelectContext(ctx, &sessions, query, userID, limit, offset)
	return sessions, err
}

// Step Completion operations

func (r *repository) CompleteStep(ctx context.Context, completion *CookingStepCompletion) error {
	query := `
		INSERT INTO cooking_step_completions (
			id, cooking_session_id, step_index, step_text,
			completed_at, time_taken_seconds, skipped,
			difficulty_rating, notes, created_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		ON CONFLICT (cooking_session_id, step_index) DO UPDATE
		SET completed_at = $5, time_taken_seconds = $6, skipped = $7,
		    difficulty_rating = $8, notes = $9
	`
	_, err := r.db.ExecContext(ctx, query,
		completion.ID, completion.CookingSessionID, completion.StepIndex,
		completion.StepText, completion.CompletedAt, completion.TimeTakenSeconds,
		completion.Skipped, completion.DifficultyRating, completion.Notes,
		completion.CreatedAt,
	)
	return err
}

func (r *repository) GetSessionStepCompletions(ctx context.Context, sessionID uuid.UUID) ([]*CookingStepCompletion, error) {
	var completions []*CookingStepCompletion
	query := `
		SELECT * FROM cooking_step_completions
		WHERE cooking_session_id = $1
		ORDER BY step_index ASC
	`
	err := r.db.SelectContext(ctx, &completions, query, sessionID)
	return completions, err
}

// Timer operations

func (r *repository) CreateTimer(ctx context.Context, timer *CookingTimer) error {
	query := `
		INSERT INTO cooking_timers (
			id, cooking_session_id, step_index, name,
			duration_seconds, remaining_seconds, status, started_at,
			total_pause_duration_seconds, notification_sent,
			created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
	`
	_, err := r.db.ExecContext(ctx, query,
		timer.ID, timer.CookingSessionID, timer.StepIndex, timer.Name,
		timer.DurationSeconds, timer.RemainingSeconds, timer.Status,
		timer.StartedAt, timer.TotalPauseDurationSeconds,
		timer.NotificationSent, timer.CreatedAt, timer.UpdatedAt,
	)
	return err
}

func (r *repository) GetSessionTimers(ctx context.Context, sessionID uuid.UUID) ([]*CookingTimer, error) {
	var timers []*CookingTimer
	query := `
		SELECT * FROM cooking_timers
		WHERE cooking_session_id = $1
		ORDER BY created_at DESC
	`
	err := r.db.SelectContext(ctx, &timers, query, sessionID)
	return timers, err
}

func (r *repository) GetTimer(ctx context.Context, id uuid.UUID) (*CookingTimer, error) {
	var timer CookingTimer
	query := `SELECT * FROM cooking_timers WHERE id = $1`
	err := r.db.GetContext(ctx, &timer, query, id)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("timer not found")
	}
	return &timer, err
}

func (r *repository) UpdateTimer(ctx context.Context, timer *CookingTimer) error {
	query := `
		UPDATE cooking_timers
		SET remaining_seconds = $1, status = $2, updated_at = NOW()
		WHERE id = $3
	`
	_, err := r.db.ExecContext(ctx, query, timer.RemainingSeconds, timer.Status, timer.ID)
	return err
}

func (r *repository) PauseTimer(ctx context.Context, id uuid.UUID) error {
	query := `
		UPDATE cooking_timers
		SET status = 'paused', paused_at = NOW(), updated_at = NOW()
		WHERE id = $1 AND status = 'running'
	`
	result, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return err
	}
	rows, _ := result.RowsAffected()
	if rows == 0 {
		return fmt.Errorf("timer not found or not running")
	}
	return nil
}

func (r *repository) ResumeTimer(ctx context.Context, id uuid.UUID) error {
	query := `
		UPDATE cooking_timers
		SET status = 'running',
		    resumed_at = NOW(),
		    total_pause_duration_seconds = total_pause_duration_seconds +
		        EXTRACT(EPOCH FROM (NOW() - paused_at))::INTEGER,
		    updated_at = NOW()
		WHERE id = $1 AND status = 'paused'
	`
	result, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return err
	}
	rows, _ := result.RowsAffected()
	if rows == 0 {
		return fmt.Errorf("timer not found or not paused")
	}
	return nil
}

func (r *repository) CompleteTimer(ctx context.Context, id uuid.UUID) error {
	query := `
		UPDATE cooking_timers
		SET status = 'completed', completed_at = NOW(), updated_at = NOW()
		WHERE id = $1 AND status IN ('running', 'paused')
	`
	result, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return err
	}
	rows, _ := result.RowsAffected()
	if rows == 0 {
		return fmt.Errorf("timer not found or already completed")
	}
	return nil
}

func (r *repository) CancelTimer(ctx context.Context, id uuid.UUID) error {
	query := `
		UPDATE cooking_timers
		SET status = 'cancelled', cancelled_at = NOW(), updated_at = NOW()
		WHERE id = $1 AND status IN ('running', 'paused')
	`
	result, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return err
	}
	rows, _ := result.RowsAffected()
	if rows == 0 {
		return fmt.Errorf("timer not found or already finished")
	}
	return nil
}

// Body Doubling Room operations

func (r *repository) CreateRoom(ctx context.Context, room *BodyDoublingRoom) error {
	query := `
		INSERT INTO body_doubling_rooms (
			id, created_by, room_name, room_code, description,
			max_participants, is_public, password_hash, status,
			scheduled_start_time, created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
	`
	_, err := r.db.ExecContext(ctx, query,
		room.ID, room.CreatedBy, room.RoomName, room.RoomCode,
		room.Description, room.MaxParticipants, room.IsPublic,
		room.PasswordHash, room.Status, room.ScheduledStartTime,
		room.CreatedAt, room.UpdatedAt,
	)
	return err
}

func (r *repository) GetRoom(ctx context.Context, id uuid.UUID) (*BodyDoublingRoom, error) {
	var room BodyDoublingRoom
	query := `SELECT * FROM body_doubling_rooms WHERE id = $1`
	err := r.db.GetContext(ctx, &room, query, id)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("room not found")
	}
	return &room, err
}

func (r *repository) GetRoomByCode(ctx context.Context, code string) (*BodyDoublingRoom, error) {
	var room BodyDoublingRoom
	query := `SELECT * FROM body_doubling_rooms WHERE room_code = $1 AND status = 'active'`
	err := r.db.GetContext(ctx, &room, query, code)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &room, err
}

func (r *repository) GetPublicRooms(ctx context.Context, limit, offset int) ([]*BodyDoublingRoom, error) {
	var rooms []*BodyDoublingRoom
	query := `
		SELECT * FROM body_doubling_rooms
		WHERE is_public = true AND status = 'active'
		ORDER BY created_at DESC
		LIMIT $1 OFFSET $2
	`
	err := r.db.SelectContext(ctx, &rooms, query, limit, offset)
	return rooms, err
}

func (r *repository) EndRoom(ctx context.Context, id uuid.UUID) error {
	query := `
		UPDATE body_doubling_rooms
		SET status = 'ended', ended_at = NOW(), updated_at = NOW()
		WHERE id = $1 AND status = 'active'
	`
	result, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return err
	}
	rows, _ := result.RowsAffected()
	if rows == 0 {
		return fmt.Errorf("room not found or already ended")
	}
	return nil
}

// Body Doubling Participant operations

func (r *repository) JoinRoom(ctx context.Context, participant *BodyDoublingParticipant) error {
	query := `
		INSERT INTO body_doubling_participants (
			id, room_id, user_id, cooking_session_id, joined_at,
			is_active, recipe_name, current_step, energy_level,
			last_activity_at, message_count, created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
		ON CONFLICT (room_id, user_id) DO UPDATE
		SET is_active = true, left_at = NULL, cooking_session_id = $4,
		    recipe_name = $7, energy_level = $9, last_activity_at = NOW(),
		    updated_at = NOW()
	`
	_, err := r.db.ExecContext(ctx, query,
		participant.ID, participant.RoomID, participant.UserID,
		participant.CookingSessionID, participant.JoinedAt,
		participant.IsActive, participant.RecipeName, participant.CurrentStep,
		participant.EnergyLevel, participant.LastActivityAt,
		participant.MessageCount, participant.CreatedAt, participant.UpdatedAt,
	)
	return err
}

func (r *repository) LeaveRoom(ctx context.Context, roomID, userID uuid.UUID) error {
	query := `
		UPDATE body_doubling_participants
		SET is_active = false, left_at = NOW(), updated_at = NOW()
		WHERE room_id = $1 AND user_id = $2 AND is_active = true
	`
	result, err := r.db.ExecContext(ctx, query, roomID, userID)
	if err != nil {
		return err
	}
	rows, _ := result.RowsAffected()
	if rows == 0 {
		return fmt.Errorf("participant not found or already left")
	}
	return nil
}

func (r *repository) GetRoomParticipants(ctx context.Context, roomID uuid.UUID) ([]*BodyDoublingParticipant, error) {
	var participants []*BodyDoublingParticipant
	query := `
		SELECT * FROM body_doubling_participants
		WHERE room_id = $1 AND is_active = true
		ORDER BY joined_at ASC
	`
	err := r.db.SelectContext(ctx, &participants, query, roomID)
	return participants, err
}

func (r *repository) GetRoomParticipantCount(ctx context.Context, roomID uuid.UUID) (int, error) {
	var count int
	query := `
		SELECT COUNT(*) FROM body_doubling_participants
		WHERE room_id = $1 AND is_active = true
	`
	err := r.db.GetContext(ctx, &count, query, roomID)
	return count, err
}

func (r *repository) UpdateParticipantActivity(ctx context.Context, roomID, userID uuid.UUID, currentStep string, energyLevel *int) error {
	query := `
		UPDATE body_doubling_participants
		SET current_step = $1, energy_level = $2, last_activity_at = NOW(), updated_at = NOW()
		WHERE room_id = $3 AND user_id = $4 AND is_active = true
	`
	result, err := r.db.ExecContext(ctx, query, currentStep, energyLevel, roomID, userID)
	if err != nil {
		return err
	}
	rows, _ := result.RowsAffected()
	if rows == 0 {
		return fmt.Errorf("participant not found or not active in room")
	}
	return nil
}
