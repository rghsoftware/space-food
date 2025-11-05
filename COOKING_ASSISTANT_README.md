# AI-Powered Cooking Assistant - Implementation Guide

## Overview

The AI-Powered Cooking Assistant provides ADHD-friendly cooking support through:
- **AI Recipe Breakdown**: Adjustable granularity (1-5 levels) for step-by-step guidance
- **Multi-Timer Management**: Named timers with pause/resume and visual countdowns
- **Progress Tracking**: Visual step completion without shame-based metrics
- **Body Doubling Sessions**: Virtual co-cooking rooms for social support

## ADHD-Specific Design Benefits

### 1. Adjustable Cognitive Load
- **Granularity Level 1**: Very detailed steps for low-energy/high-support days
  - "Get a large pot from the cabinet below the stove"
  - "Turn the front-right burner to high heat"
  - "Wait for bubbles to appear (about 5-7 minutes)"
- **Granularity Level 5**: Minimal steps for experienced/high-energy days
  - "Boil water, add pasta, cook 9 minutes"

### 2. Working Memory Support
- **Multi-Timer Management**: Tracks multiple tasks simultaneously
  - Visual countdown for each timer
  - Named timers ("Pasta", "Sauce", "Garlic bread")
  - Automatic notifications when timers complete
- **No Mental Math**: App calculates all timing automatically

### 3. Body Doubling
- **Virtual Co-Cooking**: Join rooms with others cooking at the same time
- **Parallel Play**: See others' progress without direct interaction required
- **Accountability Without Pressure**: Knowing others are cooking helps motivation
- **Easy Join**: Room codes like "PASTA-2024" instead of complex URLs

### 4. Progress Visualization
- **Step-by-Step Completion**: Check off steps as you go
- **Visual Progress Bar**: See how far you've come
- **Pause/Resume**: Life happens - pause cooking and resume later
- **No Judgment**: Steps can be skipped without shame

## Database Schema

### Tables Created

#### 1. `recipe_breakdowns`
AI-generated recipe breakdowns, cached for performance.

```sql
CREATE TABLE recipe_breakdowns (
    id UUID PRIMARY KEY,
    recipe_id UUID NOT NULL REFERENCES recipes(id),
    user_id UUID REFERENCES users(id),
    granularity_level INTEGER NOT NULL CHECK (granularity_level BETWEEN 1 AND 5),
    energy_level INTEGER CHECK (energy_level BETWEEN 1 AND 5),
    breakdown_data JSONB NOT NULL,
    ai_provider VARCHAR(50),
    ai_model VARCHAR(100),
    generated_at TIMESTAMP NOT NULL,
    last_used_at TIMESTAMP,
    use_count INTEGER DEFAULT 0,
    UNIQUE(recipe_id, granularity_level, energy_level)
);
```

**Granularity Levels**:
1. Very Detailed - Every micro-step explained (ADHD-friendly)
2. Detailed - More context and tips
3. Standard - Normal recipe instructions
4. Concise - Experienced cook level
5. Minimal - Just the essentials

**breakdown_data JSONB Structure**:
```json
{
  "steps": [
    {
      "index": 0,
      "text": "Preheat oven to 375°F (190°C)",
      "duration_seconds": 600,
      "timers": [
        {
          "name": "Oven preheating",
          "duration_seconds": 600
        }
      ],
      "dependencies": [],
      "tips": ["Use oven thermometer for accuracy"],
      "image_url": null
    }
  ],
  "total_time_seconds": 2700,
  "active_time_seconds": 1200,
  "prep_steps": [0, 1, 2],
  "cooking_steps": [3, 4, 5]
}
```

#### 2. `cooking_sessions`
Active and historical cooking sessions with progress tracking.

```sql
CREATE TABLE cooking_sessions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id),
    recipe_id UUID NOT NULL REFERENCES recipes(id),
    breakdown_id UUID REFERENCES recipe_breakdowns(id),
    meal_log_id UUID REFERENCES meal_logs(id),
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    current_step_index INTEGER DEFAULT 0,
    total_steps INTEGER NOT NULL,
    started_at TIMESTAMP NOT NULL,
    paused_at TIMESTAMP,
    resumed_at TIMESTAMP,
    completed_at TIMESTAMP,
    abandoned_at TIMESTAMP,
    total_pause_duration_seconds INTEGER DEFAULT 0,
    energy_level_at_start INTEGER CHECK (energy_level_at_start BETWEEN 1 AND 5),
    notes TEXT,
    body_doubling_room_id UUID REFERENCES body_doubling_rooms(id)
);
```

**Status Values**:
- `active`: Currently cooking
- `paused`: Temporarily paused
- `completed`: Successfully finished
- `abandoned`: Stopped before completion (no shame!)

#### 3. `cooking_step_completions`
Track which steps have been completed in a session.

```sql
CREATE TABLE cooking_step_completions (
    id UUID PRIMARY KEY,
    cooking_session_id UUID NOT NULL REFERENCES cooking_sessions(id),
    step_index INTEGER NOT NULL,
    step_text TEXT NOT NULL,
    completed_at TIMESTAMP NOT NULL,
    time_taken_seconds INTEGER,
    skipped BOOLEAN DEFAULT false,
    difficulty_rating INTEGER CHECK (difficulty_rating BETWEEN 1 AND 5),
    notes TEXT,
    UNIQUE(cooking_session_id, step_index)
);
```

**Purpose**: Analytics and learning user patterns for future AI adaptations.

#### 4. `cooking_timers`
Multi-timer management with pause/resume support.

```sql
CREATE TABLE cooking_timers (
    id UUID PRIMARY KEY,
    cooking_session_id UUID NOT NULL REFERENCES cooking_sessions(id),
    step_index INTEGER,
    name VARCHAR(100) NOT NULL,
    duration_seconds INTEGER NOT NULL,
    remaining_seconds INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'running',
    started_at TIMESTAMP NOT NULL,
    paused_at TIMESTAMP,
    resumed_at TIMESTAMP,
    completed_at TIMESTAMP,
    cancelled_at TIMESTAMP,
    total_pause_duration_seconds INTEGER DEFAULT 0,
    notification_sent BOOLEAN DEFAULT false,
    notification_sent_at TIMESTAMP
);
```

**Timer States**:
- `running`: Actively counting down
- `paused`: Temporarily stopped
- `completed`: Time elapsed
- `cancelled`: User cancelled

#### 5. `body_doubling_rooms`
Virtual co-cooking sessions for social accountability.

```sql
CREATE TABLE body_doubling_rooms (
    id UUID PRIMARY KEY,
    created_by UUID NOT NULL REFERENCES users(id),
    room_name VARCHAR(200) NOT NULL,
    room_code VARCHAR(20) UNIQUE NOT NULL,
    description TEXT,
    max_participants INTEGER DEFAULT 10,
    is_public BOOLEAN DEFAULT false,
    password_hash VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    scheduled_start_time TIMESTAMP,
    actual_start_time TIMESTAMP,
    ended_at TIMESTAMP
);
```

**Room Codes**: Easy-to-share codes like "PASTA-2024", "STIR-2025"

#### 6. `body_doubling_participants`
Track who is in which body doubling room.

```sql
CREATE TABLE body_doubling_participants (
    id UUID PRIMARY KEY,
    room_id UUID NOT NULL REFERENCES body_doubling_rooms(id),
    user_id UUID NOT NULL REFERENCES users(id),
    cooking_session_id UUID REFERENCES cooking_sessions(id),
    joined_at TIMESTAMP NOT NULL,
    left_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    recipe_name VARCHAR(300),
    current_step TEXT,
    energy_level INTEGER CHECK (energy_level BETWEEN 1 AND 5),
    last_activity_at TIMESTAMP,
    message_count INTEGER DEFAULT 0,
    UNIQUE(room_id, user_id)
);
```

## Backend Implementation

### Directory Structure
```
backend/internal/features/cooking_assistant/
├── models.go           # Data structures
├── repository.go       # Database operations
├── service.go          # Business logic + AI integration
├── handler.go          # HTTP endpoints
└── ai_breakdown.go     # AI recipe breakdown logic
```

### 1. Models (`models.go`)

```go
package cooking_assistant

import (
    "time"
    "github.com/google/uuid"
)

// RecipeBreakdown represents an AI-generated recipe breakdown
type RecipeBreakdown struct {
    ID               uuid.UUID              `json:"id" db:"id"`
    RecipeID         uuid.UUID              `json:"recipe_id" db:"recipe_id"`
    UserID           *uuid.UUID             `json:"user_id,omitempty" db:"user_id"`
    GranularityLevel int                    `json:"granularity_level" db:"granularity_level"`
    EnergyLevel      *int                   `json:"energy_level,omitempty" db:"energy_level"`
    BreakdownData    map[string]interface{} `json:"breakdown_data" db:"breakdown_data"`
    AIProvider       string                 `json:"ai_provider" db:"ai_provider"`
    AIModel          string                 `json:"ai_model" db:"ai_model"`
    GeneratedAt      time.Time              `json:"generated_at" db:"generated_at"`
    LastUsedAt       *time.Time             `json:"last_used_at,omitempty" db:"last_used_at"`
    UseCount         int                    `json:"use_count" db:"use_count"`
    CreatedAt        time.Time              `json:"created_at" db:"created_at"`
    UpdatedAt        time.Time              `json:"updated_at" db:"updated_at"`
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

type GenerateBreakdownRequest struct {
    RecipeID         uuid.UUID `json:"recipe_id" binding:"required"`
    GranularityLevel int       `json:"granularity_level" binding:"required,min=1,max=5"`
    EnergyLevel      *int      `json:"energy_level,omitempty" binding:"omitempty,min=1,max=5"`
}

type StartCookingSessionRequest struct {
    RecipeID       uuid.UUID  `json:"recipe_id" binding:"required"`
    BreakdownID    *uuid.UUID `json:"breakdown_id,omitempty"`
    EnergyLevel    *int       `json:"energy_level,omitempty" binding:"omitempty,min=1,max=5"`
    JoinRoomCode   *string    `json:"join_room_code,omitempty"`
}

type UpdateSessionProgressRequest struct {
    CurrentStepIndex int    `json:"current_step_index" binding:"min=0"`
    Notes            string `json:"notes,omitempty"`
}

type CompleteStepRequest struct {
    StepIndex        int    `json:"step_index" binding:"required,min=0"`
    StepText         string `json:"step_text" binding:"required"`
    TimeTakenSeconds *int   `json:"time_taken_seconds,omitempty"`
    Skipped          bool   `json:"skipped"`
    DifficultyRating *int   `json:"difficulty_rating,omitempty" binding:"omitempty,min=1,max=5"`
    Notes            string `json:"notes,omitempty"`
}

type CreateTimerRequest struct {
    StepIndex       *int   `json:"step_index,omitempty"`
    Name            string `json:"name" binding:"required"`
    DurationSeconds int    `json:"duration_seconds" binding:"required,min=1"`
}

type CreateBodyDoublingRoomRequest struct {
    RoomName           string     `json:"room_name" binding:"required"`
    Description        string     `json:"description,omitempty"`
    MaxParticipants    int        `json:"max_participants" binding:"min=2,max=50"`
    IsPublic           bool       `json:"is_public"`
    Password           string     `json:"password,omitempty"`
    ScheduledStartTime *time.Time `json:"scheduled_start_time,omitempty"`
}

type JoinBodyDoublingRoomRequest struct {
    RoomCode         string     `json:"room_code" binding:"required"`
    Password         string     `json:"password,omitempty"`
    CookingSessionID *uuid.UUID `json:"cooking_session_id,omitempty"`
    RecipeName       string     `json:"recipe_name,omitempty"`
}
```

### 2. Repository (`repository.go`)

```go
package cooking_assistant

import (
    "context"
    "database/sql"
    "encoding/json"
    "github.com/google/uuid"
    "github.com/jmoiron/sqlx"
)

type Repository interface {
    // Breakdowns
    GetBreakdown(ctx context.Context, recipeID uuid.UUID, granularity int, energyLevel *int) (*RecipeBreakdown, error)
    CreateBreakdown(ctx context.Context, breakdown *RecipeBreakdown) error
    UpdateBreakdownUsage(ctx context.Context, id uuid.UUID) error

    // Cooking Sessions
    CreateCookingSession(ctx context.Context, session *CookingSession) error
    GetCookingSession(ctx context.Context, id uuid.UUID) (*CookingSession, error)
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
    UpdateParticipantActivity(ctx context.Context, roomID, userID uuid.UUID, currentStep string) error
}

type repository struct {
    db *sqlx.DB
}

func NewRepository(db *sqlx.DB) Repository {
    return &repository{db: db}
}

// Implementation examples for key methods

func (r *repository) GetBreakdown(ctx context.Context, recipeID uuid.UUID, granularity int, energyLevel *int) (*RecipeBreakdown, error) {
    var breakdown RecipeBreakdown
    query := `
        SELECT * FROM recipe_breakdowns
        WHERE recipe_id = $1 AND granularity_level = $2 AND energy_level IS NOT DISTINCT FROM $3
    `
    err := r.db.GetContext(ctx, &breakdown, query, recipeID, granularity, energyLevel)
    if err == sql.ErrNoRows {
        return nil, nil
    }
    return &breakdown, err
}

func (r *repository) CreateBreakdown(ctx context.Context, breakdown *RecipeBreakdown) error {
    breakdownJSON, err := json.Marshal(breakdown.BreakdownData)
    if err != nil {
        return err
    }

    query := `
        INSERT INTO recipe_breakdowns (
            id, recipe_id, user_id, granularity_level, energy_level,
            breakdown_data, ai_provider, ai_model, generated_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
    `
    _, err = r.db.ExecContext(ctx, query,
        breakdown.ID, breakdown.RecipeID, breakdown.UserID,
        breakdown.GranularityLevel, breakdown.EnergyLevel,
        breakdownJSON, breakdown.AIProvider, breakdown.AIModel,
        breakdown.GeneratedAt,
    )
    return err
}

func (r *repository) CreateCookingSession(ctx context.Context, session *CookingSession) error {
    query := `
        INSERT INTO cooking_sessions (
            id, user_id, recipe_id, breakdown_id, status,
            current_step_index, total_steps, started_at,
            energy_level_at_start, body_doubling_room_id
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
    `
    _, err := r.db.ExecContext(ctx, query,
        session.ID, session.UserID, session.RecipeID, session.BreakdownID,
        session.Status, session.CurrentStepIndex, session.TotalSteps,
        session.StartedAt, session.EnergyLevelAtStart, session.BodyDoublingRoomID,
    )
    return err
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

func (r *repository) CreateTimer(ctx context.Context, timer *CookingTimer) error {
    query := `
        INSERT INTO cooking_timers (
            id, cooking_session_id, step_index, name,
            duration_seconds, remaining_seconds, status, started_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
    `
    _, err := r.db.ExecContext(ctx, query,
        timer.ID, timer.CookingSessionID, timer.StepIndex, timer.Name,
        timer.DurationSeconds, timer.RemainingSeconds, timer.Status,
        timer.StartedAt,
    )
    return err
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

func (r *repository) JoinRoom(ctx context.Context, participant *BodyDoublingParticipant) error {
    query := `
        INSERT INTO body_doubling_participants (
            id, room_id, user_id, cooking_session_id, joined_at,
            is_active, recipe_name, energy_level, last_activity_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        ON CONFLICT (room_id, user_id) DO UPDATE
        SET is_active = true, left_at = NULL, last_activity_at = NOW()
    `
    _, err := r.db.ExecContext(ctx, query,
        participant.ID, participant.RoomID, participant.UserID,
        participant.CookingSessionID, participant.JoinedAt,
        participant.IsActive, participant.RecipeName,
        participant.EnergyLevel, participant.LastActivityAt,
    )
    return err
}
```

### 3. Service with AI Integration (`service.go`)

```go
package cooking_assistant

import (
    "context"
    "fmt"
    "time"
    "github.com/google/uuid"
)

type Service interface {
    // Breakdown generation
    GenerateBreakdown(ctx context.Context, userID uuid.UUID, req *GenerateBreakdownRequest) (*RecipeBreakdown, error)
    GetOrGenerateBreakdown(ctx context.Context, userID uuid.UUID, recipeID uuid.UUID, granularity int, energyLevel *int) (*RecipeBreakdown, error)

    // Cooking sessions
    StartCookingSession(ctx context.Context, userID uuid.UUID, req *StartCookingSessionRequest) (*CookingSession, error)
    GetCookingSession(ctx context.Context, userID, sessionID uuid.UUID) (*CookingSession, error)
    UpdateProgress(ctx context.Context, userID, sessionID uuid.UUID, req *UpdateSessionProgressRequest) error
    PauseCooking(ctx context.Context, userID, sessionID uuid.UUID) error
    ResumeCooking(ctx context.Context, userID, sessionID uuid.UUID) error
    CompleteCooking(ctx context.Context, userID, sessionID uuid.UUID) error
    AbandonCooking(ctx context.Context, userID, sessionID uuid.UUID) error
    CompleteStep(ctx context.Context, userID, sessionID uuid.UUID, req *CompleteStepRequest) error

    // Timer management
    CreateTimer(ctx context.Context, userID, sessionID uuid.UUID, req *CreateTimerRequest) (*CookingTimer, error)
    GetSessionTimers(ctx context.Context, userID, sessionID uuid.UUID) ([]*CookingTimer, error)
    UpdateTimerRemaining(ctx context.Context, userID, timerID uuid.UUID, remainingSeconds int) error
    PauseTimer(ctx context.Context, userID, timerID uuid.UUID) error
    ResumeTimer(ctx context.Context, userID, timerID uuid.UUID) error
    CompleteTimer(ctx context.Context, userID, timerID uuid.UUID) error

    // Body doubling
    CreateRoom(ctx context.Context, userID uuid.UUID, req *CreateBodyDoublingRoomRequest) (*BodyDoublingRoom, error)
    JoinRoom(ctx context.Context, userID uuid.UUID, req *JoinBodyDoublingRoomRequest) (*BodyDoublingRoom, error)
    LeaveRoom(ctx context.Context, userID, roomID uuid.UUID) error
    GetRoomParticipants(ctx context.Context, userID, roomID uuid.UUID) ([]*BodyDoublingParticipant, error)
    GetPublicRooms(ctx context.Context, limit, offset int) ([]*BodyDoublingRoom, error)
}

type service struct {
    repo      Repository
    aiService AIService // Interface to AI providers
}

func NewService(repo Repository, aiService AIService) Service {
    return &service{
        repo:      repo,
        aiService: aiService,
    }
}

func (s *service) GetOrGenerateBreakdown(ctx context.Context, userID uuid.UUID, recipeID uuid.UUID, granularity int, energyLevel *int) (*RecipeBreakdown, error) {
    // Try to get cached breakdown
    breakdown, err := s.repo.GetBreakdown(ctx, recipeID, granularity, energyLevel)
    if err != nil {
        return nil, err
    }

    if breakdown != nil {
        // Update usage stats
        _ = s.repo.UpdateBreakdownUsage(ctx, breakdown.ID)
        return breakdown, nil
    }

    // Generate new breakdown
    req := &GenerateBreakdownRequest{
        RecipeID:         recipeID,
        GranularityLevel: granularity,
        EnergyLevel:      energyLevel,
    }
    return s.GenerateBreakdown(ctx, userID, req)
}

func (s *service) GenerateBreakdown(ctx context.Context, userID uuid.UUID, req *GenerateBreakdownRequest) (*RecipeBreakdown, error) {
    // Fetch recipe details
    // ... (get recipe from recipes repository)

    // Generate AI breakdown
    breakdownData, err := s.aiService.GenerateRecipeBreakdown(ctx, recipe, req.GranularityLevel, req.EnergyLevel)
    if err != nil {
        return nil, fmt.Errorf("AI generation failed: %w", err)
    }

    breakdown := &RecipeBreakdown{
        ID:               uuid.New(),
        RecipeID:         req.RecipeID,
        UserID:           &userID,
        GranularityLevel: req.GranularityLevel,
        EnergyLevel:      req.EnergyLevel,
        BreakdownData:    breakdownData,
        AIProvider:       s.aiService.GetProvider(),
        AIModel:          s.aiService.GetModel(),
        GeneratedAt:      time.Now(),
        UseCount:         0,
        CreatedAt:        time.Now(),
        UpdatedAt:        time.Now(),
    }

    err = s.repo.CreateBreakdown(ctx, breakdown)
    if err != nil {
        return nil, err
    }

    return breakdown, nil
}

func (s *service) StartCookingSession(ctx context.Context, userID uuid.UUID, req *StartCookingSessionRequest) (*CookingSession, error) {
    // Get or generate breakdown
    var breakdownID *uuid.UUID
    var totalSteps int

    if req.BreakdownID != nil {
        breakdownID = req.BreakdownID
        breakdown, err := s.repo.GetBreakdown(ctx, req.RecipeID, 3, nil) // Default granularity
        if err != nil {
            return nil, err
        }
        steps := breakdown.BreakdownData["steps"].([]interface{})
        totalSteps = len(steps)
    } else {
        // Generate default breakdown
        breakdown, err := s.GetOrGenerateBreakdown(ctx, userID, req.RecipeID, 3, req.EnergyLevel)
        if err != nil {
            return nil, err
        }
        id := breakdown.ID
        breakdownID = &id
        steps := breakdown.BreakdownData["steps"].([]interface{})
        totalSteps = len(steps)
    }

    // Join body doubling room if requested
    var roomID *uuid.UUID
    if req.JoinRoomCode != nil {
        room, err := s.repo.GetRoomByCode(ctx, *req.JoinRoomCode)
        if err != nil || room == nil {
            return nil, fmt.Errorf("room not found: %s", *req.JoinRoomCode)
        }
        roomID = &room.ID
    }

    session := &CookingSession{
        ID:                 uuid.New(),
        UserID:             userID,
        RecipeID:           req.RecipeID,
        BreakdownID:        breakdownID,
        Status:             "active",
        CurrentStepIndex:   0,
        TotalSteps:         totalSteps,
        StartedAt:          time.Now(),
        EnergyLevelAtStart: req.EnergyLevel,
        BodyDoublingRoomID: roomID,
        CreatedAt:          time.Now(),
        UpdatedAt:          time.Now(),
    }

    err := s.repo.CreateCookingSession(ctx, session)
    if err != nil {
        return nil, err
    }

    // Join room if specified
    if roomID != nil {
        participant := &BodyDoublingParticipant{
            ID:               uuid.New(),
            RoomID:           *roomID,
            UserID:           userID,
            CookingSessionID: &session.ID,
            JoinedAt:         time.Now(),
            IsActive:         true,
            EnergyLevel:      req.EnergyLevel,
            LastActivityAt:   time.Now(),
            CreatedAt:        time.Now(),
            UpdatedAt:        time.Now(),
        }
        _ = s.repo.JoinRoom(ctx, participant)
    }

    return session, nil
}

func (s *service) CreateRoom(ctx context.Context, userID uuid.UUID, req *CreateBodyDoublingRoomRequest) (*BodyDoublingRoom, error) {
    // Generate room code
    roomCode := generateRoomCode()

    room := &BodyDoublingRoom{
        ID:                 uuid.New(),
        CreatedBy:          userID,
        RoomName:           req.RoomName,
        RoomCode:           roomCode,
        Description:        req.Description,
        MaxParticipants:    req.MaxParticipants,
        IsPublic:           req.IsPublic,
        Status:             "active",
        ScheduledStartTime: req.ScheduledStartTime,
        CreatedAt:          time.Now(),
        UpdatedAt:          time.Now(),
    }

    if req.Password != "" {
        // Hash password
        // room.PasswordHash = hashPassword(req.Password)
    }

    err := s.repo.CreateRoom(ctx, room)
    if err != nil {
        return nil, err
    }

    return room, nil
}
```

### 4. AI Service Interface (`ai_breakdown.go`)

```go
package cooking_assistant

import (
    "context"
    "fmt"
)

type AIService interface {
    GenerateRecipeBreakdown(ctx context.Context, recipe *Recipe, granularity int, energyLevel *int) (map[string]interface{}, error)
    GetProvider() string
    GetModel() string
}

type openAIService struct {
    apiKey string
    model  string
}

func NewOpenAIService(apiKey string) AIService {
    return &openAIService{
        apiKey: apiKey,
        model:  "gpt-4o",
    }
}

func (ai *openAIService) GenerateRecipeBreakdown(ctx context.Context, recipe *Recipe, granularity int, energyLevel *int) (map[string]interface{}, error) {
    prompt := buildPrompt(recipe, granularity, energyLevel)

    // Call OpenAI API
    // response := callOpenAI(prompt)

    // Parse structured response into breakdown_data format
    breakdownData := map[string]interface{}{
        "steps":               parseSteps(response),
        "total_time_seconds":  recipe.TotalTimeMinutes * 60,
        "active_time_seconds": recipe.ActiveTimeMinutes * 60,
        "prep_steps":          []int{},
        "cooking_steps":       []int{},
    }

    return breakdownData, nil
}

func buildPrompt(recipe *Recipe, granularity int, energyLevel *int) string {
    var detailLevel string
    switch granularity {
    case 1:
        detailLevel = "EXTREMELY DETAILED - Break down every single micro-step. Assume the cook has ADHD and low executive function. Be explicit about every action, location, and timing."
    case 2:
        detailLevel = "DETAILED - Provide more context and tips than a normal recipe. Include preparation reminders and timing notes."
    case 3:
        detailLevel = "STANDARD - Normal recipe instruction level."
    case 4:
        detailLevel = "CONCISE - Assume experienced cook. Combine steps where logical."
    case 5:
        detailLevel = "MINIMAL - Just the essential steps. Assume expert level."
    }

    energyContext := ""
    if energyLevel != nil {
        energyContext = fmt.Sprintf("\nUser's current energy level: %d/5. Adapt complexity accordingly.", *energyLevel)
    }

    return fmt.Sprintf(`Break down this recipe into step-by-step instructions.
Detail Level: %s%s

Recipe: %s
Instructions: %s

Return JSON format:
{
  "steps": [
    {
      "index": 0,
      "text": "Step description",
      "duration_seconds": 300,
      "timers": [{"name": "Timer name", "duration_seconds": 300}],
      "dependencies": [],
      "tips": ["Helpful tip"]
    }
  ]
}`, detailLevel, energyContext, recipe.Name, recipe.Instructions)
}

func (ai *openAIService) GetProvider() string {
    return "openai"
}

func (ai *openAIService) GetModel() string {
    return ai.model
}
```

### 5. HTTP Handler (`handler.go`)

```go
package cooking_assistant

import (
    "net/http"
    "github.com/gin-gonic/gin"
    "github.com/google/uuid"
)

type Handler struct {
    service Service
}

func NewHandler(service Service) *Handler {
    return &Handler{service: service}
}

func (h *Handler) RegisterRoutes(r *gin.RouterGroup) {
    cooking := r.Group("/cooking-assistant")
    {
        // Breakdowns
        cooking.POST("/breakdowns/generate", h.GenerateBreakdown)
        cooking.GET("/breakdowns/:recipe_id", h.GetBreakdown)

        // Sessions
        cooking.POST("/sessions", h.StartCookingSession)
        cooking.GET("/sessions/:session_id", h.GetCookingSession)
        cooking.PUT("/sessions/:session_id/progress", h.UpdateProgress)
        cooking.POST("/sessions/:session_id/pause", h.PauseSession)
        cooking.POST("/sessions/:session_id/resume", h.ResumeSession)
        cooking.POST("/sessions/:session_id/complete", h.CompleteSession)
        cooking.POST("/sessions/:session_id/abandon", h.AbandonSession)
        cooking.POST("/sessions/:session_id/steps/complete", h.CompleteStep)

        // Timers
        cooking.POST("/sessions/:session_id/timers", h.CreateTimer)
        cooking.GET("/sessions/:session_id/timers", h.GetSessionTimers)
        cooking.PUT("/timers/:timer_id/pause", h.PauseTimer)
        cooking.PUT("/timers/:timer_id/resume", h.ResumeTimer)
        cooking.PUT("/timers/:timer_id/complete", h.CompleteTimer)

        // Body Doubling
        cooking.POST("/rooms", h.CreateRoom)
        cooking.POST("/rooms/join", h.JoinRoom)
        cooking.POST("/rooms/:room_id/leave", h.LeaveRoom)
        cooking.GET("/rooms/:room_id/participants", h.GetRoomParticipants)
        cooking.GET("/rooms/public", h.GetPublicRooms)
    }
}

// Handler implementations

func (h *Handler) GenerateBreakdown(c *gin.Context) {
    var req GenerateBreakdownRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    userID := c.GetString("user_id") // From auth middleware
    uid, _ := uuid.Parse(userID)

    breakdown, err := h.service.GenerateBreakdown(c.Request.Context(), uid, &req)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusCreated, breakdown)
}

func (h *Handler) StartCookingSession(c *gin.Context) {
    var req StartCookingSessionRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    userID := c.GetString("user_id")
    uid, _ := uuid.Parse(userID)

    session, err := h.service.StartCookingSession(c.Request.Context(), uid, &req)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusCreated, session)
}

func (h *Handler) CreateTimer(c *gin.Context) {
    sessionID, err := uuid.Parse(c.Param("session_id"))
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "invalid session_id"})
        return
    }

    var req CreateTimerRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    userID := c.GetString("user_id")
    uid, _ := uuid.Parse(userID)

    timer, err := h.service.CreateTimer(c.Request.Context(), uid, sessionID, &req)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusCreated, timer)
}

func (h *Handler) CreateRoom(c *gin.Context) {
    var req CreateBodyDoublingRoomRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    userID := c.GetString("user_id")
    uid, _ := uuid.Parse(userID)

    room, err := h.service.CreateRoom(c.Request.Context(), uid, &req)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusCreated, room)
}
```

## Frontend Implementation (Flutter)

### Directory Structure
```
app/lib/src/features/cooking_assistant/
├── data/
│   ├── models/
│   │   ├── recipe_breakdown.dart
│   │   ├── cooking_session.dart
│   │   ├── cooking_timer.dart
│   │   └── body_doubling_room.dart
│   ├── local/
│   │   └── cooking_assistant_database.dart
│   ├── remote/
│   │   └── cooking_assistant_api_client.dart
│   └── repositories/
│       └── cooking_assistant_repository.dart
└── presentation/
    ├── screens/
    │   ├── cooking_session_screen.dart
    │   ├── room_lobby_screen.dart
    │   └── recipe_breakdown_preview_screen.dart
    ├── widgets/
    │   ├── step_card.dart
    │   ├── timer_widget.dart
    │   ├── progress_bar.dart
    │   └── participant_list.dart
    └── providers/
        └── cooking_assistant_providers.dart
```

### Key Screens

#### 1. Cooking Session Screen
```dart
class CookingSessionScreen extends ConsumerStatefulWidget {
  final String sessionId;

  @override
  ConsumerState<CookingSessionScreen> createState() => _CookingSessionScreenState();
}

class _CookingSessionScreenState extends ConsumerState<CookingSessionScreen> {
  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(cookingSessionProvider(widget.sessionId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Cooking...'),
        actions: [
          IconButton(
            icon: Icon(Icons.pause),
            onPressed: () => ref.read(cookingSessionControllerProvider.notifier)
                .pauseSession(widget.sessionId),
          ),
        ],
      ),
      body: sessionAsync.when(
        data: (session) => Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: session.currentStepIndex / session.totalSteps,
            ),
            Text('Step ${session.currentStepIndex + 1} of ${session.totalSteps}'),

            // Current step card
            Expanded(
              child: StepCard(
                step: session.currentStep,
                onComplete: () => _completeStep(session),
                onSkip: () => _skipStep(session),
              ),
            ),

            // Timers
            TimerListWidget(sessionId: widget.sessionId),

            // Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: session.currentStepIndex > 0 ? () => _previousStep() : null,
                  child: Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: () => _nextStep(),
                  child: Text('Next'),
                ),
              ],
            ),
          ],
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
```

#### 2. Body Doubling Room Screen
```dart
class BodyDoublingRoomScreen extends ConsumerWidget {
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(bodyDoublingRoomProvider(roomId));
    final participantsAsync = ref.watch(roomParticipantsProvider(roomId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Cooking Together'),
      ),
      body: Column(
        children: [
          // Room info card
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: roomAsync.when(
                data: (room) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(room.roomName, style: Theme.of(context).textTheme.headlineSmall),
                    Text('Room Code: ${room.roomCode}'),
                    if (room.description != null) Text(room.description!),
                  ],
                ),
                loading: () => CircularProgressIndicator(),
                error: (err, _) => Text('Error loading room'),
              ),
            ),
          ),

          // Participants list
          Expanded(
            child: participantsAsync.when(
              data: (participants) => ListView.builder(
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  final p = participants[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(p.userName[0].toUpperCase()),
                    ),
                    title: Text(p.userName),
                    subtitle: p.recipeName != null
                        ? Text('Cooking: ${p.recipeName}')
                        : Text('Preparing...'),
                    trailing: p.currentStep != null
                        ? Text(p.currentStep!, maxLines: 1, overflow: TextOverflow.ellipsis)
                        : null,
                  );
                },
              ),
              loading: () => Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading participants')),
            ),
          ),

          // Leave room button
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => ref.read(bodyDoublingControllerProvider.notifier)
                  .leaveRoom(roomId),
              child: Text('Leave Room'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

## API Endpoints

### Recipe Breakdown

#### Generate Breakdown
```
POST /api/cooking-assistant/breakdowns/generate
Authorization: Bearer {token}

Request:
{
  "recipe_id": "uuid",
  "granularity_level": 2,
  "energy_level": 3
}

Response: 201 Created
{
  "id": "uuid",
  "recipe_id": "uuid",
  "granularity_level": 2,
  "energy_level": 3,
  "breakdown_data": {
    "steps": [...],
    "total_time_seconds": 2700,
    "active_time_seconds": 1200
  },
  "ai_provider": "openai",
  "ai_model": "gpt-4",
  "generated_at": "2025-01-15T10:00:00Z"
}
```

### Cooking Sessions

#### Start Cooking Session
```
POST /api/cooking-assistant/sessions
Authorization: Bearer {token}

Request:
{
  "recipe_id": "uuid",
  "breakdown_id": "uuid",
  "energy_level": 3,
  "join_room_code": "PASTA-2024"
}

Response: 201 Created
{
  "id": "uuid",
  "user_id": "uuid",
  "recipe_id": "uuid",
  "breakdown_id": "uuid",
  "status": "active",
  "current_step_index": 0,
  "total_steps": 12,
  "started_at": "2025-01-15T10:00:00Z",
  "energy_level_at_start": 3,
  "body_doubling_room_id": "uuid"
}
```

#### Update Progress
```
PUT /api/cooking-assistant/sessions/:session_id/progress
Authorization: Bearer {token}

Request:
{
  "current_step_index": 3,
  "notes": "Pasta is boiling"
}

Response: 200 OK
```

#### Complete Step
```
POST /api/cooking-assistant/sessions/:session_id/steps/complete
Authorization: Bearer {token}

Request:
{
  "step_index": 2,
  "step_text": "Boil water in large pot",
  "time_taken_seconds": 420,
  "skipped": false,
  "difficulty_rating": 2,
  "notes": "Took longer than expected"
}

Response: 201 Created
```

### Timers

#### Create Timer
```
POST /api/cooking-assistant/sessions/:session_id/timers
Authorization: Bearer {token}

Request:
{
  "step_index": 3,
  "name": "Pasta boiling",
  "duration_seconds": 540
}

Response: 201 Created
{
  "id": "uuid",
  "cooking_session_id": "uuid",
  "step_index": 3,
  "name": "Pasta boiling",
  "duration_seconds": 540,
  "remaining_seconds": 540,
  "status": "running",
  "started_at": "2025-01-15T10:05:00Z"
}
```

#### Get Session Timers
```
GET /api/cooking-assistant/sessions/:session_id/timers
Authorization: Bearer {token}

Response: 200 OK
[
  {
    "id": "uuid",
    "name": "Pasta boiling",
    "duration_seconds": 540,
    "remaining_seconds": 320,
    "status": "running"
  },
  {
    "id": "uuid",
    "name": "Sauce simmering",
    "duration_seconds": 900,
    "remaining_seconds": 720,
    "status": "running"
  }
]
```

### Body Doubling

#### Create Room
```
POST /api/cooking-assistant/rooms
Authorization: Bearer {token}

Request:
{
  "room_name": "Evening Dinner Prep",
  "description": "Cooking dinner together",
  "max_participants": 6,
  "is_public": true,
  "password": null,
  "scheduled_start_time": "2025-01-15T18:00:00Z"
}

Response: 201 Created
{
  "id": "uuid",
  "created_by": "uuid",
  "room_name": "Evening Dinner Prep",
  "room_code": "PASTA-2024",
  "description": "Cooking dinner together",
  "max_participants": 6,
  "is_public": true,
  "status": "active",
  "scheduled_start_time": "2025-01-15T18:00:00Z",
  "created_at": "2025-01-15T10:00:00Z"
}
```

#### Join Room
```
POST /api/cooking-assistant/rooms/join
Authorization: Bearer {token}

Request:
{
  "room_code": "PASTA-2024",
  "password": null,
  "cooking_session_id": "uuid",
  "recipe_name": "Spaghetti Carbonara"
}

Response: 200 OK
{
  "room": {...},
  "participant": {
    "id": "uuid",
    "room_id": "uuid",
    "user_id": "uuid",
    "joined_at": "2025-01-15T10:00:00Z",
    "is_active": true,
    "recipe_name": "Spaghetti Carbonara"
  }
}
```

#### Get Room Participants
```
GET /api/cooking-assistant/rooms/:room_id/participants
Authorization: Bearer {token}

Response: 200 OK
[
  {
    "id": "uuid",
    "user_id": "uuid",
    "user_name": "Alice",
    "recipe_name": "Spaghetti Carbonara",
    "current_step": "Boiling pasta",
    "energy_level": 3,
    "joined_at": "2025-01-15T10:00:00Z",
    "is_active": true
  },
  {
    "id": "uuid",
    "user_id": "uuid",
    "user_name": "Bob",
    "recipe_name": "Chicken Stir Fry",
    "current_step": "Chopping vegetables",
    "energy_level": 4,
    "joined_at": "2025-01-15T10:05:00Z",
    "is_active": true
  }
]
```

## Usage Scenarios

### Scenario 1: Low Energy Day - Need Maximum Support

**Context**: User has ADHD, energy level 2/5, wants to cook but feeling overwhelmed.

**Flow**:
1. User selects "Spaghetti Carbonara" recipe
2. App detects energy level 2, suggests granularity level 1 (very detailed)
3. User starts cooking session with detailed breakdown
4. Breakdown includes micro-steps:
   - "Open the cabinet under your stove"
   - "Get out the large silver pot (the 8-quart one)"
   - "Carry the pot to the sink"
   - "Turn on the cold water tap"
   - "Fill pot about 3/4 full (about 6 quarts)"
   - "Carry pot carefully to the stove"
   - "Place pot on the front-right burner"
   - "Turn dial to 'HIGH' position"
   - "Wait for bubbles to appear (this takes about 7 minutes)"
5. Each step has:
   - Clear, specific instructions
   - Visual timer when applicable
   - No assumptions about what user knows
6. User joins body doubling room "DINNER-2024" for motivation
7. Progress tracked step-by-step without judgment

**Result**: Successfully completes meal with reduced cognitive load and external support.

### Scenario 2: Experienced Cook - High Energy Day

**Context**: User feeling energized (level 5/5), knows the recipe well, just needs timing reminders.

**Flow**:
1. User selects familiar "Chicken Stir Fry" recipe
2. Chooses granularity level 5 (minimal)
3. Breakdown shows only essential steps:
   - "Prep all ingredients (10 min)"
   - "High heat, cook chicken, set aside (5 min)"
   - "Stir fry vegetables (4 min)"
   - "Combine, add sauce (2 min)"
4. User creates multiple timers:
   - "Chicken" - 5 minutes
   - "Vegetables" - 4 minutes
   - "Rice cooking" - 15 minutes
5. Monitors all three timers simultaneously
6. Completes meal quickly with just timing support

**Result**: Efficient cooking with minimal hand-holding, just the automation needed.

### Scenario 3: Body Doubling Session

**Context**: User struggles with cooking alone due to ADHD paralysis, but thrives with others.

**Flow**:
1. User creates public body doubling room "TACO TUESDAY"
2. Room code auto-generated: "TACO-2024"
3. User shares code in ADHD Discord community
4. Three others join the room
5. Each person cooking different meals:
   - Alice: Fish tacos
   - Bob: Beef tacos
   - Charlie: Vegetarian tacos
   - Dana: Quesadillas
6. Room shows everyone's current step:
   - Alice: "Seasoning fish"
   - Bob: "Chopping onions"
   - Charlie: "Preparing beans"
   - Dana: "Grating cheese"
7. Parallel cooking creates accountability
8. Optional chat for quick questions
9. Everyone completes their meals together

**Result**: Social support reduces ADHD paralysis, completion rate increases dramatically.

### Scenario 4: Mid-Cooking Interruption

**Context**: User is cooking, child needs attention, must pause.

**Flow**:
1. User mid-way through "Lasagna" (step 8 of 15)
2. Has three active timers:
   - "Sauce simmering" - 12 minutes remaining
   - "Pasta boiling" - 3 minutes remaining
   - "Oven preheating" - 5 minutes remaining
3. User taps "Pause Cooking"
4. All timers pause automatically
5. Session status changes to "paused"
6. User deals with interruption (15 minutes)
7. Returns to app, taps "Resume Cooking"
8. All timers resume from where they stopped
9. Current step still visible
10. User continues cooking seamlessly

**Result**: Handles real-life interruptions without losing place or burning food.

## Testing Strategy

### Unit Tests
- AI breakdown generation with different granularity levels
- Pattern detection in step completions
- Timer pause/resume calculations
- Room code generation uniqueness

### Integration Tests
- End-to-end cooking session flow
- Multi-timer coordination
- Body doubling room join/leave mechanics
- Offline sync for session data

### User Experience Tests
- Granularity level differences clearly visible
- Timer notifications arrive on time
- Progress saves correctly after interruptions
- Room participants update in real-time

## Performance Considerations

### AI Breakdown Caching
- Cache breakdowns by (recipe_id, granularity, energy_level)
- Reduces API costs significantly
- Pre-generate popular recipes at all granularity levels
- Track use_count for cache optimization

### Real-Time Updates
- WebSocket connections for body doubling rooms
- Push notifications for timer completions
- Efficient polling for timer remaining_seconds
- Battery-conscious background timer updates

### Offline Support
- All cooking sessions work offline
- Sync to server when connection restored
- Local Drift database for session state
- Timer calculations use device time

## Success Metrics

### Completion Rates
- Session completion rate (target: >80%)
- Step skip rate (target: <15%)
- Abandonment analysis by granularity level
- Energy level correlation with completion

### Engagement
- Body doubling room usage
- Average participants per room
- Timer creation frequency
- Breakdown regeneration rate

### ADHD-Specific Metrics
- Completion rate on low-energy days
- Session pause/resume frequency
- Time-to-completion vs estimated time
- Difficulty ratings by step type

## Future Enhancements

1. **Voice Control**: "Alexa, next step" for hands-free cooking
2. **Video Steps**: Short video clips for complex techniques
3. **Adaptive Learning**: AI learns user's skill level over time
4. **Substitution Suggestions**: "Out of eggs? Here's what to use"
5. **Equipment Detection**: "This step requires a stand mixer - do you have one?"
6. **Skill Building**: Track mastery of techniques across recipes
7. **Social Features**: Follow friends, share successful sessions
8. **Gamification**: Achievements for trying new techniques (shame-free!)

## Build Instructions

### Backend
```bash
# Apply migration
cd backend
psql -U postgres -d spacefood -f internal/database/postgres/migrations/005_cooking_assistant.sql

# Build and run
go build -o bin/server cmd/server/main.go
./bin/server
```

### Frontend
```bash
cd app

# Generate code
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Run app
flutter run
```

## Environment Variables

```bash
# Backend
OPENAI_API_KEY=sk-...
AI_PROVIDER=openai  # or 'anthropic', 'google'
AI_MODEL=gpt-4o

# Timer notifications
ENABLE_TIMER_NOTIFICATIONS=true
NOTIFICATION_CHECK_INTERVAL_SECONDS=5

# Body doubling
WEBSOCKET_ENABLED=true
MAX_ROOM_PARTICIPANTS=10
```

## License

Copyright (C) 2025 RGH Software
Licensed under AGPL-3.0
