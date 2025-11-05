// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

package cooking_assistant

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// Handler handles HTTP requests for cooking assistant
type Handler struct {
	service Service
}

// NewHandler creates a new cooking assistant handler
func NewHandler(service Service) *Handler {
	return &Handler{service: service}
}

// RegisterRoutes registers all cooking assistant routes
func (h *Handler) RegisterRoutes(r *gin.RouterGroup) {
	cooking := r.Group("/cooking-assistant")
	{
		// Breakdowns
		cooking.POST("/breakdowns/generate", h.GenerateBreakdown)
		cooking.GET("/breakdowns/:recipe_id", h.GetBreakdown)

		// Sessions
		cooking.POST("/sessions", h.StartCookingSession)
		cooking.GET("/sessions/:session_id", h.GetCookingSession)
		cooking.GET("/sessions", h.GetUserSessions)
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
		cooking.PUT("/timers/:timer_id/cancel", h.CancelTimer)

		// Body Doubling
		cooking.POST("/rooms", h.CreateRoom)
		cooking.POST("/rooms/join", h.JoinRoom)
		cooking.POST("/rooms/:room_id/leave", h.LeaveRoom)
		cooking.GET("/rooms/:room_id", h.GetRoom)
		cooking.GET("/rooms/:room_id/participants", h.GetRoomParticipants)
		cooking.GET("/rooms/public", h.GetPublicRooms)
		cooking.PUT("/rooms/:room_id/activity", h.UpdateParticipantActivity)
	}
}

// Breakdown handlers

// GenerateBreakdown godoc
// @Summary Generate AI recipe breakdown
// @Description Generate a new AI-powered recipe breakdown with specified granularity
// @Tags cooking-assistant
// @Accept json
// @Produce json
// @Param request body GenerateBreakdownRequest true "Breakdown generation request"
// @Success 201 {object} RecipeBreakdown
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /cooking-assistant/breakdowns/generate [post]
func (h *Handler) GenerateBreakdown(c *gin.Context) {
	var req GenerateBreakdownRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	breakdown, err := h.service.GenerateBreakdown(c.Request.Context(), userID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, breakdown)
}

// GetBreakdown godoc
// @Summary Get or generate recipe breakdown
// @Description Get cached breakdown or generate new one
// @Tags cooking-assistant
// @Produce json
// @Param recipe_id path string true "Recipe ID"
// @Param granularity query int false "Granularity level (1-5)"
// @Param energy_level query int false "Energy level (1-5)"
// @Success 200 {object} RecipeBreakdown
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /cooking-assistant/breakdowns/{recipe_id} [get]
func (h *Handler) GetBreakdown(c *gin.Context) {
	recipeID, err := uuid.Parse(c.Param("recipe_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid recipe_id"})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	granularity := 3 // Default
	if g := c.Query("granularity"); g != "" {
		var tempGran int
		if _, err := fmt.Sscanf(g, "%d", &tempGran); err == nil && tempGran >= 1 && tempGran <= 5 {
			granularity = tempGran
		}
	}

	var energyLevel *int
	if e := c.Query("energy_level"); e != "" {
		var tempEnergy int
		if _, err := fmt.Sscanf(e, "%d", &tempEnergy); err == nil && tempEnergy >= 1 && tempEnergy <= 5 {
			energyLevel = &tempEnergy
		}
	}

	breakdown, err := h.service.GetOrGenerateBreakdown(c.Request.Context(), userID, recipeID, granularity, energyLevel)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, breakdown)
}

// Cooking Session handlers

// StartCookingSession godoc
// @Summary Start a cooking session
// @Description Start a new cooking session for a recipe
// @Tags cooking-assistant
// @Accept json
// @Produce json
// @Param request body StartCookingSessionRequest true "Session start request"
// @Success 201 {object} CookingSession
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /cooking-assistant/sessions [post]
func (h *Handler) StartCookingSession(c *gin.Context) {
	var req StartCookingSessionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	session, err := h.service.StartCookingSession(c.Request.Context(), userID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, session)
}

// GetCookingSession godoc
// @Summary Get cooking session details
// @Description Get details of a specific cooking session
// @Tags cooking-assistant
// @Produce json
// @Param session_id path string true "Session ID"
// @Success 200 {object} CookingSession
// @Failure 400 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Router /cooking-assistant/sessions/{session_id} [get]
func (h *Handler) GetCookingSession(c *gin.Context) {
	sessionID, err := uuid.Parse(c.Param("session_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid session_id"})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	session, err := h.service.GetCookingSession(c.Request.Context(), userID, sessionID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, session)
}

// GetUserSessions godoc
// @Summary Get user's cooking sessions
// @Description Get all cooking sessions for the current user
// @Tags cooking-assistant
// @Produce json
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {array} CookingSession
// @Failure 500 {object} map[string]string
// @Router /cooking-assistant/sessions [get]
func (h *Handler) GetUserSessions(c *gin.Context) {
	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	limit := 20
	offset := 0
	if l := c.Query("limit"); l != "" {
		fmt.Sscanf(l, "%d", &limit)
	}
	if o := c.Query("offset"); o != "" {
		fmt.Sscanf(o, "%d", &offset)
	}

	sessions, err := h.service.GetUserSessions(c.Request.Context(), userID, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, sessions)
}

// UpdateProgress godoc
// @Summary Update cooking progress
// @Description Update the current step and notes for a cooking session
// @Tags cooking-assistant
// @Accept json
// @Produce json
// @Param session_id path string true "Session ID"
// @Param request body UpdateSessionProgressRequest true "Progress update"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /cooking-assistant/sessions/{session_id}/progress [put]
func (h *Handler) UpdateProgress(c *gin.Context) {
	sessionID, err := uuid.Parse(c.Param("session_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid session_id"})
		return
	}

	var req UpdateSessionProgressRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	err = h.service.UpdateProgress(c.Request.Context(), userID, sessionID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "progress updated"})
}

// PauseSession godoc
// @Summary Pause cooking session
// @Description Pause an active cooking session
// @Tags cooking-assistant
// @Produce json
// @Param session_id path string true "Session ID"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /cooking-assistant/sessions/{session_id}/pause [post]
func (h *Handler) PauseSession(c *gin.Context) {
	sessionID, err := uuid.Parse(c.Param("session_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid session_id"})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	err = h.service.PauseCooking(c.Request.Context(), userID, sessionID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "session paused"})
}

// ResumeSession godoc
// @Summary Resume cooking session
// @Description Resume a paused cooking session
// @Tags cooking-assistant
// @Produce json
// @Param session_id path string true "Session ID"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /cooking-assistant/sessions/{session_id}/resume [post]
func (h *Handler) ResumeSession(c *gin.Context) {
	sessionID, err := uuid.Parse(c.Param("session_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid session_id"})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	err = h.service.ResumeCooking(c.Request.Context(), userID, sessionID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "session resumed"})
}

// CompleteSession godoc
// @Summary Complete cooking session
// @Description Mark a cooking session as completed
// @Tags cooking-assistant
// @Produce json
// @Param session_id path string true "Session ID"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /cooking-assistant/sessions/{session_id}/complete [post]
func (h *Handler) CompleteSession(c *gin.Context) {
	sessionID, err := uuid.Parse(c.Param("session_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid session_id"})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	err = h.service.CompleteCooking(c.Request.Context(), userID, sessionID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "session completed"})
}

// AbandonSession godoc
// @Summary Abandon cooking session
// @Description Mark a cooking session as abandoned (no shame!)
// @Tags cooking-assistant
// @Produce json
// @Param session_id path string true "Session ID"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /cooking-assistant/sessions/{session_id}/abandon [post]
func (h *Handler) AbandonSession(c *gin.Context) {
	sessionID, err := uuid.Parse(c.Param("session_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid session_id"})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	err = h.service.AbandonCooking(c.Request.Context(), userID, sessionID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "session abandoned"})
}

// CompleteStep godoc
// @Summary Complete a cooking step
// @Description Mark a step as completed with optional feedback
// @Tags cooking-assistant
// @Accept json
// @Produce json
// @Param session_id path string true "Session ID"
// @Param request body CompleteStepRequest true "Step completion data"
// @Success 201 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /cooking-assistant/sessions/{session_id}/steps/complete [post]
func (h *Handler) CompleteStep(c *gin.Context) {
	sessionID, err := uuid.Parse(c.Param("session_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid session_id"})
		return
	}

	var req CompleteStepRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	err = h.service.CompleteStep(c.Request.Context(), userID, sessionID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "step completed"})
}

// Timer handlers

// CreateTimer godoc
// @Summary Create a cooking timer
// @Description Create a new timer for a cooking session
// @Tags cooking-assistant
// @Accept json
// @Produce json
// @Param session_id path string true "Session ID"
// @Param request body CreateTimerRequest true "Timer data"
// @Success 201 {object} CookingTimer
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /cooking-assistant/sessions/{session_id}/timers [post]
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

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	timer, err := h.service.CreateTimer(c.Request.Context(), userID, sessionID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, timer)
}

// GetSessionTimers godoc
// @Summary Get session timers
// @Description Get all timers for a cooking session
// @Tags cooking-assistant
// @Produce json
// @Param session_id path string true "Session ID"
// @Success 200 {array} CookingTimer
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /cooking-assistant/sessions/{session_id}/timers [get]
func (h *Handler) GetSessionTimers(c *gin.Context) {
	sessionID, err := uuid.Parse(c.Param("session_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid session_id"})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	timers, err := h.service.GetSessionTimers(c.Request.Context(), userID, sessionID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, timers)
}

// PauseTimer godoc
// @Summary Pause a timer
// @Description Pause a running timer
// @Tags cooking-assistant
// @Produce json
// @Param timer_id path string true "Timer ID"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /cooking-assistant/timers/{timer_id}/pause [put]
func (h *Handler) PauseTimer(c *gin.Context) {
	timerID, err := uuid.Parse(c.Param("timer_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid timer_id"})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	err = h.service.PauseTimer(c.Request.Context(), userID, timerID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "timer paused"})
}

// ResumeTimer godoc
// @Summary Resume a timer
// @Description Resume a paused timer
// @Tags cooking-assistant
// @Produce json
// @Param timer_id path string true "Timer ID"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /cooking-assistant/timers/{timer_id}/resume [put]
func (h *Handler) ResumeTimer(c *gin.Context) {
	timerID, err := uuid.Parse(c.Param("timer_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid timer_id"})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	err = h.service.ResumeTimer(c.Request.Context(), userID, timerID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "timer resumed"})
}

// CompleteTimer godoc
// @Summary Complete a timer
// @Description Mark a timer as completed
// @Tags cooking-assistant
// @Produce json
// @Param timer_id path string true "Timer ID"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /cooking-assistant/timers/{timer_id}/complete [put]
func (h *Handler) CompleteTimer(c *gin.Context) {
	timerID, err := uuid.Parse(c.Param("timer_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid timer_id"})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	err = h.service.CompleteTimer(c.Request.Context(), userID, timerID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "timer completed"})
}

// CancelTimer godoc
// @Summary Cancel a timer
// @Description Cancel a timer
// @Tags cooking-assistant
// @Produce json
// @Param timer_id path string true "Timer ID"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /cooking-assistant/timers/{timer_id}/cancel [put]
func (h *Handler) CancelTimer(c *gin.Context) {
	timerID, err := uuid.Parse(c.Param("timer_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid timer_id"})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	err = h.service.CancelTimer(c.Request.Context(), userID, timerID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "timer cancelled"})
}

// Body Doubling handlers

// CreateRoom godoc
// @Summary Create a body doubling room
// @Description Create a new virtual co-cooking room
// @Tags cooking-assistant
// @Accept json
// @Produce json
// @Param request body CreateBodyDoublingRoomRequest true "Room data"
// @Success 201 {object} BodyDoublingRoom
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /cooking-assistant/rooms [post]
func (h *Handler) CreateRoom(c *gin.Context) {
	var req CreateBodyDoublingRoomRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	room, err := h.service.CreateRoom(c.Request.Context(), userID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, room)
}

// JoinRoom godoc
// @Summary Join a body doubling room
// @Description Join an existing room using room code
// @Tags cooking-assistant
// @Accept json
// @Produce json
// @Param request body JoinBodyDoublingRoomRequest true "Join room data"
// @Success 200 {object} BodyDoublingRoom
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /cooking-assistant/rooms/join [post]
func (h *Handler) JoinRoom(c *gin.Context) {
	var req JoinBodyDoublingRoomRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	room, err := h.service.JoinRoom(c.Request.Context(), userID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, room)
}

// LeaveRoom godoc
// @Summary Leave a body doubling room
// @Description Leave a room you're currently in
// @Tags cooking-assistant
// @Produce json
// @Param room_id path string true "Room ID"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /cooking-assistant/rooms/{room_id}/leave [post]
func (h *Handler) LeaveRoom(c *gin.Context) {
	roomID, err := uuid.Parse(c.Param("room_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid room_id"})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	err = h.service.LeaveRoom(c.Request.Context(), userID, roomID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "left room"})
}

// GetRoom godoc
// @Summary Get room details
// @Description Get details of a body doubling room
// @Tags cooking-assistant
// @Produce json
// @Param room_id path string true "Room ID"
// @Success 200 {object} BodyDoublingRoom
// @Failure 400 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Router /cooking-assistant/rooms/{room_id} [get]
func (h *Handler) GetRoom(c *gin.Context) {
	roomID, err := uuid.Parse(c.Param("room_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid room_id"})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	room, err := h.service.GetRoom(c.Request.Context(), userID, roomID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, room)
}

// GetRoomParticipants godoc
// @Summary Get room participants
// @Description Get all active participants in a room
// @Tags cooking-assistant
// @Produce json
// @Param room_id path string true "Room ID"
// @Success 200 {array} BodyDoublingParticipant
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /cooking-assistant/rooms/{room_id}/participants [get]
func (h *Handler) GetRoomParticipants(c *gin.Context) {
	roomID, err := uuid.Parse(c.Param("room_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid room_id"})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	participants, err := h.service.GetRoomParticipants(c.Request.Context(), userID, roomID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, participants)
}

// GetPublicRooms godoc
// @Summary Get public rooms
// @Description Get list of public body doubling rooms
// @Tags cooking-assistant
// @Produce json
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {array} BodyDoublingRoom
// @Failure 500 {object} map[string]string
// @Router /cooking-assistant/rooms/public [get]
func (h *Handler) GetPublicRooms(c *gin.Context) {
	limit := 20
	offset := 0
	if l := c.Query("limit"); l != "" {
		fmt.Sscanf(l, "%d", &limit)
	}
	if o := c.Query("offset"); o != "" {
		fmt.Sscanf(o, "%d", &offset)
	}

	rooms, err := h.service.GetPublicRooms(c.Request.Context(), limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, rooms)
}

// UpdateParticipantActivity godoc
// @Summary Update participant activity
// @Description Update your current step and activity in a room
// @Tags cooking-assistant
// @Accept json
// @Produce json
// @Param room_id path string true "Room ID"
// @Param request body UpdateParticipantActivityRequest true "Activity update"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /cooking-assistant/rooms/{room_id}/activity [put]
func (h *Handler) UpdateParticipantActivity(c *gin.Context) {
	roomID, err := uuid.Parse(c.Param("room_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid room_id"})
		return
	}

	var req UpdateParticipantActivityRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	err = h.service.UpdateParticipantActivity(c.Request.Context(), userID, roomID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "activity updated"})
}

// Helper functions

func getUserID(c *gin.Context) (uuid.UUID, error) {
	// Get user ID from auth middleware context
	userIDStr, exists := c.Get("user_id")
	if !exists {
		return uuid.Nil, fmt.Errorf("user_id not found in context")
	}

	// Try to parse as UUID
	if uid, ok := userIDStr.(uuid.UUID); ok {
		return uid, nil
	}

	// Try to parse as string
	if uidStr, ok := userIDStr.(string); ok {
		return uuid.Parse(uidStr)
	}

	return uuid.Nil, fmt.Errorf("invalid user_id type")
}
