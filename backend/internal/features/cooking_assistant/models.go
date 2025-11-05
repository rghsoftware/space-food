// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

package cooking_assistant

import (
	"database/sql/driver"
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// RecipeBreakdown represents an AI-generated recipe breakdown
type RecipeBreakdown struct {
	ID               uuid.UUID       `json:"id" db:"id"`
	RecipeID         uuid.UUID       `json:"recipe_id" db:"recipe_id"`
	UserID           *uuid.UUID      `json:"user_id,omitempty" db:"user_id"`
	GranularityLevel int             `json:"granularity_level" db:"granularity_level"`
	EnergyLevel      *int            `json:"energy_level,omitempty" db:"energy_level"`
	BreakdownData    BreakdownData   `json:"breakdown_data" db:"breakdown_data"`
	AIProvider       string          `json:"ai_provider" db:"ai_provider"`
	AIModel          string          `json:"ai_model" db:"ai_model"`
	GeneratedAt      time.Time       `json:"generated_at" db:"generated_at"`
	LastUsedAt       *time.Time      `json:"last_used_at,omitempty" db:"last_used_at"`
	UseCount         int             `json:"use_count" db:"use_count"`
	CreatedAt        time.Time       `json:"created_at" db:"created_at"`
	UpdatedAt        time.Time       `json:"updated_at" db:"updated_at"`
}

// BreakdownData represents the structured breakdown data
type BreakdownData struct {
	Steps             []BreakdownStep `json:"steps"`
	TotalTimeSeconds  int             `json:"total_time_seconds"`
	ActiveTimeSeconds int             `json:"active_time_seconds"`
	PrepSteps         []int           `json:"prep_steps,omitempty"`
	CookingSteps      []int           `json:"cooking_steps,omitempty"`
}

// BreakdownStep represents a single cooking step
type BreakdownStep struct {
	Index           int                  `json:"index"`
	Text            string               `json:"text"`
	DurationSeconds int                  `json:"duration_seconds"`
	Timers          []BreakdownTimer     `json:"timers,omitempty"`
	Dependencies    []int                `json:"dependencies,omitempty"`
	Tips            []string             `json:"tips,omitempty"`
	ImageURL        string               `json:"image_url,omitempty"`
}

// BreakdownTimer represents a timer in a breakdown step
type BreakdownTimer struct {
	Name            string `json:"name"`
	DurationSeconds int    `json:"duration_seconds"`
}

// Value implements driver.Valuer for BreakdownData
func (bd BreakdownData) Value() (driver.Value, error) {
	return json.Marshal(bd)
}

// Scan implements sql.Scanner for BreakdownData
func (bd *BreakdownData) Scan(value interface{}) error {
	if value == nil {
		return nil
	}
	bytes, ok := value.([]byte)
	if !ok {
		return json.Unmarshal([]byte(value.(string)), bd)
	}
	return json.Unmarshal(bytes, bd)
}

// CookingSession represents an active or completed cooking session
type CookingSession struct {
	ID                       uuid.UUID  `json:"id" db:"id"`
	UserID                   uuid.UUID  `json:"user_id" db:"user_id"`
	RecipeID                 uuid.UUID  `json:"recipe_id" db:"recipe_id"`
	BreakdownID              *uuid.UUID `json:"breakdown_id,omitempty" db:"breakdown_id"`
	MealLogID                *uuid.UUID `json:"meal_log_id,omitempty" db:"meal_log_id"`
	Status                   string     `json:"status" db:"status"`
	CurrentStepIndex         int        `json:"current_step_index" db:"current_step_index"`
	TotalSteps               int        `json:"total_steps" db:"total_steps"`
	StartedAt                time.Time  `json:"started_at" db:"started_at"`
	PausedAt                 *time.Time `json:"paused_at,omitempty" db:"paused_at"`
	ResumedAt                *time.Time `json:"resumed_at,omitempty" db:"resumed_at"`
	CompletedAt              *time.Time `json:"completed_at,omitempty" db:"completed_at"`
	AbandonedAt              *time.Time `json:"abandoned_at,omitempty" db:"abandoned_at"`
	TotalPauseDurationSeconds int       `json:"total_pause_duration_seconds" db:"total_pause_duration_seconds"`
	EnergyLevelAtStart       *int       `json:"energy_level_at_start,omitempty" db:"energy_level_at_start"`
	Notes                    string     `json:"notes,omitempty" db:"notes"`
	BodyDoublingRoomID       *uuid.UUID `json:"body_doubling_room_id,omitempty" db:"body_doubling_room_id"`
	CreatedAt                time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt                time.Time  `json:"updated_at" db:"updated_at"`
}

// CookingStepCompletion tracks step completion
type CookingStepCompletion struct {
	ID               uuid.UUID  `json:"id" db:"id"`
	CookingSessionID uuid.UUID  `json:"cooking_session_id" db:"cooking_session_id"`
	StepIndex        int        `json:"step_index" db:"step_index"`
	StepText         string     `json:"step_text" db:"step_text"`
	CompletedAt      time.Time  `json:"completed_at" db:"completed_at"`
	TimeTakenSeconds *int       `json:"time_taken_seconds,omitempty" db:"time_taken_seconds"`
	Skipped          bool       `json:"skipped" db:"skipped"`
	DifficultyRating *int       `json:"difficulty_rating,omitempty" db:"difficulty_rating"`
	Notes            string     `json:"notes,omitempty" db:"notes"`
	CreatedAt        time.Time  `json:"created_at" db:"created_at"`
}

// CookingTimer represents a timer during cooking
type CookingTimer struct {
	ID                       uuid.UUID  `json:"id" db:"id"`
	CookingSessionID         uuid.UUID  `json:"cooking_session_id" db:"cooking_session_id"`
	StepIndex                *int       `json:"step_index,omitempty" db:"step_index"`
	Name                     string     `json:"name" db:"name"`
	DurationSeconds          int        `json:"duration_seconds" db:"duration_seconds"`
	RemainingSeconds         int        `json:"remaining_seconds" db:"remaining_seconds"`
	Status                   string     `json:"status" db:"status"`
	StartedAt                time.Time  `json:"started_at" db:"started_at"`
	PausedAt                 *time.Time `json:"paused_at,omitempty" db:"paused_at"`
	ResumedAt                *time.Time `json:"resumed_at,omitempty" db:"resumed_at"`
	CompletedAt              *time.Time `json:"completed_at,omitempty" db:"completed_at"`
	CancelledAt              *time.Time `json:"cancelled_at,omitempty" db:"cancelled_at"`
	TotalPauseDurationSeconds int       `json:"total_pause_duration_seconds" db:"total_pause_duration_seconds"`
	NotificationSent         bool       `json:"notification_sent" db:"notification_sent"`
	NotificationSentAt       *time.Time `json:"notification_sent_at,omitempty" db:"notification_sent_at"`
	CreatedAt                time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt                time.Time  `json:"updated_at" db:"updated_at"`
}

// BodyDoublingRoom represents a virtual co-cooking room
type BodyDoublingRoom struct {
	ID                 uuid.UUID  `json:"id" db:"id"`
	CreatedBy          uuid.UUID  `json:"created_by" db:"created_by"`
	RoomName           string     `json:"room_name" db:"room_name"`
	RoomCode           string     `json:"room_code" db:"room_code"`
	Description        string     `json:"description,omitempty" db:"description"`
	MaxParticipants    int        `json:"max_participants" db:"max_participants"`
	IsPublic           bool       `json:"is_public" db:"is_public"`
	PasswordHash       string     `json:"-" db:"password_hash"`
	Status             string     `json:"status" db:"status"`
	ScheduledStartTime *time.Time `json:"scheduled_start_time,omitempty" db:"scheduled_start_time"`
	ActualStartTime    *time.Time `json:"actual_start_time,omitempty" db:"actual_start_time"`
	EndedAt            *time.Time `json:"ended_at,omitempty" db:"ended_at"`
	CreatedAt          time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt          time.Time  `json:"updated_at" db:"updated_at"`
}

// BodyDoublingParticipant tracks room membership
type BodyDoublingParticipant struct {
	ID               uuid.UUID  `json:"id" db:"id"`
	RoomID           uuid.UUID  `json:"room_id" db:"room_id"`
	UserID           uuid.UUID  `json:"user_id" db:"user_id"`
	CookingSessionID *uuid.UUID `json:"cooking_session_id,omitempty" db:"cooking_session_id"`
	JoinedAt         time.Time  `json:"joined_at" db:"joined_at"`
	LeftAt           *time.Time `json:"left_at,omitempty" db:"left_at"`
	IsActive         bool       `json:"is_active" db:"is_active"`
	RecipeName       string     `json:"recipe_name,omitempty" db:"recipe_name"`
	CurrentStep      string     `json:"current_step,omitempty" db:"current_step"`
	EnergyLevel      *int       `json:"energy_level,omitempty" db:"energy_level"`
	LastActivityAt   time.Time  `json:"last_activity_at" db:"last_activity_at"`
	MessageCount     int        `json:"message_count" db:"message_count"`
	CreatedAt        time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt        time.Time  `json:"updated_at" db:"updated_at"`
}

// Request/Response DTOs

// GenerateBreakdownRequest represents a request to generate an AI breakdown
type GenerateBreakdownRequest struct {
	RecipeID         uuid.UUID `json:"recipe_id" binding:"required"`
	GranularityLevel int       `json:"granularity_level" binding:"required,min=1,max=5"`
	EnergyLevel      *int      `json:"energy_level,omitempty" binding:"omitempty,min=1,max=5"`
}

// StartCookingSessionRequest represents a request to start a cooking session
type StartCookingSessionRequest struct {
	RecipeID     uuid.UUID  `json:"recipe_id" binding:"required"`
	BreakdownID  *uuid.UUID `json:"breakdown_id,omitempty"`
	EnergyLevel  *int       `json:"energy_level,omitempty" binding:"omitempty,min=1,max=5"`
	JoinRoomCode *string    `json:"join_room_code,omitempty"`
}

// UpdateSessionProgressRequest represents a request to update cooking progress
type UpdateSessionProgressRequest struct {
	CurrentStepIndex int    `json:"current_step_index" binding:"min=0"`
	Notes            string `json:"notes,omitempty"`
}

// CompleteStepRequest represents a request to mark a step as complete
type CompleteStepRequest struct {
	StepIndex        int    `json:"step_index" binding:"required,min=0"`
	StepText         string `json:"step_text" binding:"required"`
	TimeTakenSeconds *int   `json:"time_taken_seconds,omitempty"`
	Skipped          bool   `json:"skipped"`
	DifficultyRating *int   `json:"difficulty_rating,omitempty" binding:"omitempty,min=1,max=5"`
	Notes            string `json:"notes,omitempty"`
}

// CreateTimerRequest represents a request to create a timer
type CreateTimerRequest struct {
	StepIndex       *int   `json:"step_index,omitempty"`
	Name            string `json:"name" binding:"required"`
	DurationSeconds int    `json:"duration_seconds" binding:"required,min=1"`
}

// CreateBodyDoublingRoomRequest represents a request to create a room
type CreateBodyDoublingRoomRequest struct {
	RoomName           string     `json:"room_name" binding:"required"`
	Description        string     `json:"description,omitempty"`
	MaxParticipants    int        `json:"max_participants" binding:"min=2,max=50"`
	IsPublic           bool       `json:"is_public"`
	Password           string     `json:"password,omitempty"`
	ScheduledStartTime *time.Time `json:"scheduled_start_time,omitempty"`
}

// JoinBodyDoublingRoomRequest represents a request to join a room
type JoinBodyDoublingRoomRequest struct {
	RoomCode         string     `json:"room_code" binding:"required"`
	Password         string     `json:"password,omitempty"`
	CookingSessionID *uuid.UUID `json:"cooking_session_id,omitempty"`
	RecipeName       string     `json:"recipe_name,omitempty"`
}

// UpdateParticipantActivityRequest represents a request to update participant activity
type UpdateParticipantActivityRequest struct {
	CurrentStep string `json:"current_step,omitempty"`
	EnergyLevel *int   `json:"energy_level,omitempty" binding:"omitempty,min=1,max=5"`
}
