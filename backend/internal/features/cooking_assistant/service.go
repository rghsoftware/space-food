// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

package cooking_assistant

import (
	"context"
	"crypto/rand"
	"fmt"
	"math/big"
	"strings"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

// Service defines the interface for cooking assistant business logic
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
	GetUserSessions(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*CookingSession, error)

	// Timer management
	CreateTimer(ctx context.Context, userID, sessionID uuid.UUID, req *CreateTimerRequest) (*CookingTimer, error)
	GetSessionTimers(ctx context.Context, userID, sessionID uuid.UUID) ([]*CookingTimer, error)
	UpdateTimerRemaining(ctx context.Context, userID, timerID uuid.UUID, remainingSeconds int) error
	PauseTimer(ctx context.Context, userID, timerID uuid.UUID) error
	ResumeTimer(ctx context.Context, userID, timerID uuid.UUID) error
	CompleteTimer(ctx context.Context, userID, timerID uuid.UUID) error
	CancelTimer(ctx context.Context, userID, timerID uuid.UUID) error

	// Body doubling
	CreateRoom(ctx context.Context, userID uuid.UUID, req *CreateBodyDoublingRoomRequest) (*BodyDoublingRoom, error)
	JoinRoom(ctx context.Context, userID uuid.UUID, req *JoinBodyDoublingRoomRequest) (*BodyDoublingRoom, error)
	LeaveRoom(ctx context.Context, userID, roomID uuid.UUID) error
	GetRoom(ctx context.Context, userID, roomID uuid.UUID) (*BodyDoublingRoom, error)
	GetRoomParticipants(ctx context.Context, userID, roomID uuid.UUID) ([]*BodyDoublingParticipant, error)
	GetPublicRooms(ctx context.Context, limit, offset int) ([]*BodyDoublingRoom, error)
	UpdateParticipantActivity(ctx context.Context, userID, roomID uuid.UUID, req *UpdateParticipantActivityRequest) error
}

type service struct {
	repo      Repository
	aiService AIService
	// We'll need a recipe repository to fetch recipe details
	// For now, we'll use a simple interface that can be injected
}

// NewService creates a new cooking assistant service
func NewService(repo Repository, aiService AIService) Service {
	return &service{
		repo:      repo,
		aiService: aiService,
	}
}

// Breakdown operations

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
	// TODO: Fetch recipe details from recipes repository
	// For now, we'll create a placeholder recipe
	// recipe := fetchRecipe(req.RecipeID)

	// Generate AI breakdown using the AI service
	breakdownData, err := s.aiService.GenerateRecipeBreakdown(ctx, req.RecipeID, req.GranularityLevel, req.EnergyLevel)
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

// Cooking Session operations

func (s *service) StartCookingSession(ctx context.Context, userID uuid.UUID, req *StartCookingSessionRequest) (*CookingSession, error) {
	// Get or generate breakdown
	var breakdownID *uuid.UUID
	var totalSteps int

	if req.BreakdownID != nil {
		// Use existing breakdown
		breakdown, err := s.repo.GetBreakdown(ctx, req.RecipeID, 3, nil) // Default to granularity 3
		if err != nil || breakdown == nil {
			return nil, fmt.Errorf("breakdown not found")
		}
		id := breakdown.ID
		breakdownID = &id
		totalSteps = len(breakdown.BreakdownData.Steps)
	} else {
		// Generate default breakdown based on energy level
		granularity := 3 // Default
		if req.EnergyLevel != nil {
			// Adjust granularity based on energy level
			// Low energy (1-2) = more detailed (1-2)
			// High energy (4-5) = less detailed (4-5)
			granularity = *req.EnergyLevel
		}

		breakdown, err := s.GetOrGenerateBreakdown(ctx, userID, req.RecipeID, granularity, req.EnergyLevel)
		if err != nil {
			return nil, err
		}
		id := breakdown.ID
		breakdownID = &id
		totalSteps = len(breakdown.BreakdownData.Steps)
	}

	// Join body doubling room if requested
	var roomID *uuid.UUID
	if req.JoinRoomCode != nil && *req.JoinRoomCode != "" {
		room, err := s.repo.GetRoomByCode(ctx, *req.JoinRoomCode)
		if err != nil || room == nil {
			return nil, fmt.Errorf("room not found: %s", *req.JoinRoomCode)
		}

		// Check if room is full
		count, err := s.repo.GetRoomParticipantCount(ctx, room.ID)
		if err != nil {
			return nil, err
		}
		if count >= room.MaxParticipants {
			return nil, fmt.Errorf("room is full")
		}

		roomID = &room.ID
	}

	session := &CookingSession{
		ID:                       uuid.New(),
		UserID:                   userID,
		RecipeID:                 req.RecipeID,
		BreakdownID:              breakdownID,
		Status:                   "active",
		CurrentStepIndex:         0,
		TotalSteps:               totalSteps,
		StartedAt:                time.Now(),
		TotalPauseDurationSeconds: 0,
		EnergyLevelAtStart:       req.EnergyLevel,
		BodyDoublingRoomID:       roomID,
		CreatedAt:                time.Now(),
		UpdatedAt:                time.Now(),
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
			MessageCount:     0,
			CreatedAt:        time.Now(),
			UpdatedAt:        time.Now(),
		}
		_ = s.repo.JoinRoom(ctx, participant)

		// Start room if it's the first participant
		room, _ := s.repo.GetRoom(ctx, *roomID)
		if room.ActualStartTime == nil {
			// TODO: Update room actual_start_time
		}
	}

	return session, nil
}

func (s *service) GetCookingSession(ctx context.Context, userID, sessionID uuid.UUID) (*CookingSession, error) {
	session, err := s.repo.GetCookingSessionByUserAndID(ctx, userID, sessionID)
	if err != nil {
		return nil, err
	}
	return session, nil
}

func (s *service) UpdateProgress(ctx context.Context, userID, sessionID uuid.UUID, req *UpdateSessionProgressRequest) error {
	// Verify session belongs to user
	session, err := s.repo.GetCookingSessionByUserAndID(ctx, userID, sessionID)
	if err != nil {
		return err
	}

	// Update session progress
	err = s.repo.UpdateSessionProgress(ctx, session.ID, req.CurrentStepIndex, req.Notes)
	if err != nil {
		return err
	}

	// If in a body doubling room, update participant activity
	if session.BodyDoublingRoomID != nil {
		// Get current step text from breakdown
		currentStep := fmt.Sprintf("Step %d of %d", req.CurrentStepIndex+1, session.TotalSteps)
		_ = s.repo.UpdateParticipantActivity(ctx, *session.BodyDoublingRoomID, userID, currentStep, session.EnergyLevelAtStart)
	}

	return nil
}

func (s *service) PauseCooking(ctx context.Context, userID, sessionID uuid.UUID) error {
	// Verify session belongs to user
	_, err := s.repo.GetCookingSessionByUserAndID(ctx, userID, sessionID)
	if err != nil {
		return err
	}

	return s.repo.PauseSession(ctx, sessionID)
}

func (s *service) ResumeCooking(ctx context.Context, userID, sessionID uuid.UUID) error {
	// Verify session belongs to user
	_, err := s.repo.GetCookingSessionByUserAndID(ctx, userID, sessionID)
	if err != nil {
		return err
	}

	return s.repo.ResumeSession(ctx, sessionID)
}

func (s *service) CompleteCooking(ctx context.Context, userID, sessionID uuid.UUID) error {
	// Verify session belongs to user
	session, err := s.repo.GetCookingSessionByUserAndID(ctx, userID, sessionID)
	if err != nil {
		return err
	}

	err = s.repo.CompleteSession(ctx, sessionID)
	if err != nil {
		return err
	}

	// Leave body doubling room if in one
	if session.BodyDoublingRoomID != nil {
		_ = s.repo.LeaveRoom(ctx, *session.BodyDoublingRoomID, userID)
	}

	return nil
}

func (s *service) AbandonCooking(ctx context.Context, userID, sessionID uuid.UUID) error {
	// Verify session belongs to user
	session, err := s.repo.GetCookingSessionByUserAndID(ctx, userID, sessionID)
	if err != nil {
		return err
	}

	err = s.repo.AbandonSession(ctx, sessionID)
	if err != nil {
		return err
	}

	// Leave body doubling room if in one
	if session.BodyDoublingRoomID != nil {
		_ = s.repo.LeaveRoom(ctx, *session.BodyDoublingRoomID, userID)
	}

	return nil
}

func (s *service) CompleteStep(ctx context.Context, userID, sessionID uuid.UUID, req *CompleteStepRequest) error {
	// Verify session belongs to user
	_, err := s.repo.GetCookingSessionByUserAndID(ctx, userID, sessionID)
	if err != nil {
		return err
	}

	completion := &CookingStepCompletion{
		ID:               uuid.New(),
		CookingSessionID: sessionID,
		StepIndex:        req.StepIndex,
		StepText:         req.StepText,
		CompletedAt:      time.Now(),
		TimeTakenSeconds: req.TimeTakenSeconds,
		Skipped:          req.Skipped,
		DifficultyRating: req.DifficultyRating,
		Notes:            req.Notes,
		CreatedAt:        time.Now(),
	}

	return s.repo.CompleteStep(ctx, completion)
}

func (s *service) GetUserSessions(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*CookingSession, error) {
	return s.repo.GetUserCookingSessions(ctx, userID, limit, offset)
}

// Timer operations

func (s *service) CreateTimer(ctx context.Context, userID, sessionID uuid.UUID, req *CreateTimerRequest) (*CookingTimer, error) {
	// Verify session belongs to user
	_, err := s.repo.GetCookingSessionByUserAndID(ctx, userID, sessionID)
	if err != nil {
		return nil, err
	}

	timer := &CookingTimer{
		ID:                       uuid.New(),
		CookingSessionID:         sessionID,
		StepIndex:                req.StepIndex,
		Name:                     req.Name,
		DurationSeconds:          req.DurationSeconds,
		RemainingSeconds:         req.DurationSeconds,
		Status:                   "running",
		StartedAt:                time.Now(),
		TotalPauseDurationSeconds: 0,
		NotificationSent:         false,
		CreatedAt:                time.Now(),
		UpdatedAt:                time.Now(),
	}

	err = s.repo.CreateTimer(ctx, timer)
	if err != nil {
		return nil, err
	}

	return timer, nil
}

func (s *service) GetSessionTimers(ctx context.Context, userID, sessionID uuid.UUID) ([]*CookingTimer, error) {
	// Verify session belongs to user
	_, err := s.repo.GetCookingSessionByUserAndID(ctx, userID, sessionID)
	if err != nil {
		return nil, err
	}

	return s.repo.GetSessionTimers(ctx, sessionID)
}

func (s *service) UpdateTimerRemaining(ctx context.Context, userID, timerID uuid.UUID, remainingSeconds int) error {
	timer, err := s.repo.GetTimer(ctx, timerID)
	if err != nil {
		return err
	}

	// Verify timer belongs to user's session
	_, err = s.repo.GetCookingSessionByUserAndID(ctx, userID, timer.CookingSessionID)
	if err != nil {
		return err
	}

	timer.RemainingSeconds = remainingSeconds
	if remainingSeconds <= 0 {
		timer.Status = "completed"
	}

	return s.repo.UpdateTimer(ctx, timer)
}

func (s *service) PauseTimer(ctx context.Context, userID, timerID uuid.UUID) error {
	timer, err := s.repo.GetTimer(ctx, timerID)
	if err != nil {
		return err
	}

	// Verify timer belongs to user's session
	_, err = s.repo.GetCookingSessionByUserAndID(ctx, userID, timer.CookingSessionID)
	if err != nil {
		return err
	}

	return s.repo.PauseTimer(ctx, timerID)
}

func (s *service) ResumeTimer(ctx context.Context, userID, timerID uuid.UUID) error {
	timer, err := s.repo.GetTimer(ctx, timerID)
	if err != nil {
		return err
	}

	// Verify timer belongs to user's session
	_, err = s.repo.GetCookingSessionByUserAndID(ctx, userID, timer.CookingSessionID)
	if err != nil {
		return err
	}

	return s.repo.ResumeTimer(ctx, timerID)
}

func (s *service) CompleteTimer(ctx context.Context, userID, timerID uuid.UUID) error {
	timer, err := s.repo.GetTimer(ctx, timerID)
	if err != nil {
		return err
	}

	// Verify timer belongs to user's session
	_, err = s.repo.GetCookingSessionByUserAndID(ctx, userID, timer.CookingSessionID)
	if err != nil {
		return err
	}

	return s.repo.CompleteTimer(ctx, timerID)
}

func (s *service) CancelTimer(ctx context.Context, userID, timerID uuid.UUID) error {
	timer, err := s.repo.GetTimer(ctx, timerID)
	if err != nil {
		return err
	}

	// Verify timer belongs to user's session
	_, err = s.repo.GetCookingSessionByUserAndID(ctx, userID, timer.CookingSessionID)
	if err != nil {
		return err
	}

	return s.repo.CancelTimer(ctx, timerID)
}

// Body Doubling operations

func (s *service) CreateRoom(ctx context.Context, userID uuid.UUID, req *CreateBodyDoublingRoomRequest) (*BodyDoublingRoom, error) {
	// Generate room code
	roomCode := generateRoomCode()

	// Hash password if provided
	var passwordHash string
	if req.Password != "" {
		hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
		if err != nil {
			return nil, fmt.Errorf("failed to hash password: %w", err)
		}
		passwordHash = string(hash)
	}

	room := &BodyDoublingRoom{
		ID:                 uuid.New(),
		CreatedBy:          userID,
		RoomName:           req.RoomName,
		RoomCode:           roomCode,
		Description:        req.Description,
		MaxParticipants:    req.MaxParticipants,
		IsPublic:           req.IsPublic,
		PasswordHash:       passwordHash,
		Status:             "active",
		ScheduledStartTime: req.ScheduledStartTime,
		CreatedAt:          time.Now(),
		UpdatedAt:          time.Now(),
	}

	err := s.repo.CreateRoom(ctx, room)
	if err != nil {
		return nil, err
	}

	// Creator automatically joins the room
	participant := &BodyDoublingParticipant{
		ID:             uuid.New(),
		RoomID:         room.ID,
		UserID:         userID,
		JoinedAt:       time.Now(),
		IsActive:       true,
		LastActivityAt: time.Now(),
		MessageCount:   0,
		CreatedAt:      time.Now(),
		UpdatedAt:      time.Now(),
	}
	_ = s.repo.JoinRoom(ctx, participant)

	return room, nil
}

func (s *service) JoinRoom(ctx context.Context, userID uuid.UUID, req *JoinBodyDoublingRoomRequest) (*BodyDoublingRoom, error) {
	// Get room by code
	room, err := s.repo.GetRoomByCode(ctx, req.RoomCode)
	if err != nil {
		return nil, err
	}
	if room == nil {
		return nil, fmt.Errorf("room not found or inactive")
	}

	// Check if room is full
	count, err := s.repo.GetRoomParticipantCount(ctx, room.ID)
	if err != nil {
		return nil, err
	}
	if count >= room.MaxParticipants {
		return nil, fmt.Errorf("room is full")
	}

	// Verify password if required
	if room.PasswordHash != "" {
		if req.Password == "" {
			return nil, fmt.Errorf("password required")
		}
		err = bcrypt.CompareHashAndPassword([]byte(room.PasswordHash), []byte(req.Password))
		if err != nil {
			return nil, fmt.Errorf("incorrect password")
		}
	}

	// Join the room
	participant := &BodyDoublingParticipant{
		ID:               uuid.New(),
		RoomID:           room.ID,
		UserID:           userID,
		CookingSessionID: req.CookingSessionID,
		JoinedAt:         time.Now(),
		IsActive:         true,
		RecipeName:       req.RecipeName,
		LastActivityAt:   time.Now(),
		MessageCount:     0,
		CreatedAt:        time.Now(),
		UpdatedAt:        time.Now(),
	}

	err = s.repo.JoinRoom(ctx, participant)
	if err != nil {
		return nil, err
	}

	return room, nil
}

func (s *service) LeaveRoom(ctx context.Context, userID, roomID uuid.UUID) error {
	return s.repo.LeaveRoom(ctx, roomID, userID)
}

func (s *service) GetRoom(ctx context.Context, userID, roomID uuid.UUID) (*BodyDoublingRoom, error) {
	return s.repo.GetRoom(ctx, roomID)
}

func (s *service) GetRoomParticipants(ctx context.Context, userID, roomID uuid.UUID) ([]*BodyDoublingParticipant, error) {
	// Verify user has access to room (is a participant or room is public)
	room, err := s.repo.GetRoom(ctx, roomID)
	if err != nil {
		return nil, err
	}

	if !room.IsPublic {
		// Check if user is a participant
		participants, err := s.repo.GetRoomParticipants(ctx, roomID)
		if err != nil {
			return nil, err
		}

		isParticipant := false
		for _, p := range participants {
			if p.UserID == userID {
				isParticipant = true
				break
			}
		}

		if !isParticipant && room.CreatedBy != userID {
			return nil, fmt.Errorf("access denied")
		}
	}

	return s.repo.GetRoomParticipants(ctx, roomID)
}

func (s *service) GetPublicRooms(ctx context.Context, limit, offset int) ([]*BodyDoublingRoom, error) {
	return s.repo.GetPublicRooms(ctx, limit, offset)
}

func (s *service) UpdateParticipantActivity(ctx context.Context, userID, roomID uuid.UUID, req *UpdateParticipantActivityRequest) error {
	return s.repo.UpdateParticipantActivity(ctx, roomID, userID, req.CurrentStep, req.EnergyLevel)
}

// Helper functions

func generateRoomCode() string {
	words := []string{
		"PASTA", "PIZZA", "SALAD", "SOUP", "STIR", "BAKE",
		"GRILL", "ROAST", "FRY", "STEAM", "TACO", "CURRY",
		"RICE", "NOODLE", "BREAD", "CAKE", "PIE", "STEW",
	}

	// Select random word
	idx, _ := rand.Int(rand.Reader, big.NewInt(int64(len(words))))
	word := words[idx.Int64()]

	// Add year
	year := time.Now().Year()

	return fmt.Sprintf("%s-%d", word, year)
}

// ensureUniqueRoomCode checks if room code exists and generates a new one if needed
func (s *service) ensureUniqueRoomCode(ctx context.Context, code string) (string, error) {
	for i := 0; i < 10; i++ { // Try up to 10 times
		existing, err := s.repo.GetRoomByCode(ctx, code)
		if err != nil {
			return "", err
		}
		if existing == nil {
			return code, nil
		}
		// Generate new code with random suffix
		suffix, _ := rand.Int(rand.Reader, big.NewInt(100))
		code = strings.TrimSuffix(code, fmt.Sprintf("-%d", suffix.Int64()))
		code = fmt.Sprintf("%s-%d", code, suffix.Int64())
	}
	return "", fmt.Errorf("failed to generate unique room code")
}
