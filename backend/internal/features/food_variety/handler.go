// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

package food_variety

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// Handler handles HTTP requests for food variety
type Handler struct {
	service Service
}

// NewHandler creates a new food variety handler
func NewHandler(service Service) *Handler {
	return &Handler{service: service}
}

// RegisterRoutes registers all food variety routes
func (h *Handler) RegisterRoutes(r *gin.RouterGroup) {
	variety := r.Group("/food-variety")
	{
		// Hyperfixation tracking
		variety.GET("/hyperfixations", h.GetActiveHyperfixations)
		variety.POST("/hyperfixations", h.RecordHyperfixation)

		// Food chaining
		variety.POST("/chain-suggestions/generate", h.GenerateChainSuggestions)
		variety.GET("/chain-suggestions", h.GetUserChainSuggestions)
		variety.PUT("/chain-suggestions/:suggestion_id/feedback", h.RecordChainFeedback)

		// Variation ideas
		variety.GET("/variations/:food_name", h.GetVariationIdeas)

		// Variety analysis
		variety.GET("/analysis", h.GetVarietyAnalysis)

		// Nutrition settings
		variety.GET("/nutrition/settings", h.GetNutritionSettings)
		variety.PUT("/nutrition/settings", h.UpdateNutritionSettings)

		// Nutrition insights
		variety.GET("/nutrition/insights", h.GetWeeklyInsights)
		variety.POST("/nutrition/insights/generate", h.GenerateWeeklyInsights)
		variety.PUT("/nutrition/insights/:insight_id/dismiss", h.DismissInsight)

		// Rotation schedules
		variety.POST("/rotation-schedules", h.CreateRotationSchedule)
		variety.GET("/rotation-schedules", h.GetRotationSchedules)
		variety.PUT("/rotation-schedules/:schedule_id", h.UpdateRotationSchedule)
		variety.DELETE("/rotation-schedules/:schedule_id", h.DeleteRotationSchedule)
	}
}

// Hyperfixation handlers

// GetActiveHyperfixations godoc
// @Summary Get active food hyperfixations
// @Description Get list of foods currently being eaten frequently
// @Tags food-variety
// @Produce json
// @Success 200 {array} FoodHyperfixation
// @Failure 500 {object} map[string]string
// @Router /food-variety/hyperfixations [get]
func (h *Handler) GetActiveHyperfixations(c *gin.Context) {
	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	hyperfixations, err := h.service.GetActiveHyperfixations(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, hyperfixations)
}

// RecordHyperfixation godoc
// @Summary Manually record a food hyperfixation
// @Description Record that you're eating a particular food frequently
// @Tags food-variety
// @Accept json
// @Produce json
// @Param request body RecordHyperfixationRequest true "Hyperfixation data"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /food-variety/hyperfixations [post]
func (h *Handler) RecordHyperfixation(c *gin.Context) {
	var req RecordHyperfixationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	err = h.service.RecordHyperfixation(c.Request.Context(), userID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "hyperfixation recorded"})
}

// Food chaining handlers

// GenerateChainSuggestions godoc
// @Summary Generate food chaining suggestions
// @Description Get AI-generated suggestions for similar foods
// @Tags food-variety
// @Accept json
// @Produce json
// @Param request body GenerateChainSuggestionsRequest true "Chain suggestion request"
// @Success 200 {array} FoodChainSuggestion
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /food-variety/chain-suggestions/generate [post]
func (h *Handler) GenerateChainSuggestions(c *gin.Context) {
	var req GenerateChainSuggestionsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	// Default to 5 suggestions if not specified
	count := req.MaxSuggestions
	if count == 0 {
		count = 5
	}

	suggestions, err := h.service.GenerateChainSuggestions(c.Request.Context(), userID, req.FoodName, count)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, suggestions)
}

// GetUserChainSuggestions godoc
// @Summary Get user's chain suggestions
// @Description Get all chain suggestions for the user
// @Tags food-variety
// @Produce json
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {array} FoodChainSuggestion
// @Failure 500 {object} map[string]string
// @Router /food-variety/chain-suggestions [get]
func (h *Handler) GetUserChainSuggestions(c *gin.Context) {
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

	suggestions, err := h.service.GetUserChainSuggestions(c.Request.Context(), userID, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, suggestions)
}

// RecordChainFeedback godoc
// @Summary Record feedback on chain suggestion
// @Description Record whether a suggested food was liked
// @Tags food-variety
// @Accept json
// @Produce json
// @Param suggestion_id path string true "Suggestion ID"
// @Param request body RecordChainFeedbackRequest true "Feedback data"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /food-variety/chain-suggestions/{suggestion_id}/feedback [put]
func (h *Handler) RecordChainFeedback(c *gin.Context) {
	suggestionID, err := uuid.Parse(c.Param("suggestion_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid suggestion_id"})
		return
	}

	var req RecordChainFeedbackRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	err = h.service.RecordChainFeedback(c.Request.Context(), suggestionID, userID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "feedback recorded"})
}

// Variation handlers

// GetVariationIdeas godoc
// @Summary Get variation ideas for a food
// @Description Get simple variations (sauces, toppings, etc.) for a food
// @Tags food-variety
// @Produce json
// @Param food_name path string true "Food name"
// @Success 200 {array} FoodVariation
// @Failure 500 {object} map[string]string
// @Router /food-variety/variations/{food_name} [get]
func (h *Handler) GetVariationIdeas(c *gin.Context) {
	foodName := c.Param("food_name")

	variations, err := h.service.GetVariationIdeas(c.Request.Context(), foodName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, variations)
}

// Variety analysis handler

// GetVarietyAnalysis godoc
// @Summary Get variety analysis
// @Description Get comprehensive variety metrics and suggestions
// @Tags food-variety
// @Produce json
// @Success 200 {object} VarietyAnalysis
// @Failure 500 {object} map[string]string
// @Router /food-variety/analysis [get]
func (h *Handler) GetVarietyAnalysis(c *gin.Context) {
	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	analysis, err := h.service.GetVarietyAnalysis(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, analysis)
}

// Nutrition settings handlers

// GetNutritionSettings godoc
// @Summary Get nutrition tracking settings
// @Description Get user's nutrition tracking preferences
// @Tags food-variety
// @Produce json
// @Success 200 {object} NutritionTrackingSettings
// @Failure 500 {object} map[string]string
// @Router /food-variety/nutrition/settings [get]
func (h *Handler) GetNutritionSettings(c *gin.Context) {
	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	settings, err := h.service.GetNutritionSettings(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, settings)
}

// UpdateNutritionSettings godoc
// @Summary Update nutrition tracking settings
// @Description Update nutrition tracking preferences
// @Tags food-variety
// @Accept json
// @Produce json
// @Param request body UpdateNutritionSettingsRequest true "Settings update"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /food-variety/nutrition/settings [put]
func (h *Handler) UpdateNutritionSettings(c *gin.Context) {
	var req UpdateNutritionSettingsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	err = h.service.UpdateNutritionSettings(c.Request.Context(), userID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "settings updated"})
}

// Nutrition insight handlers

// GetWeeklyInsights godoc
// @Summary Get weekly nutrition insights
// @Description Get gentle nutrition insights for current week
// @Tags food-variety
// @Produce json
// @Success 200 {array} NutritionInsight
// @Failure 500 {object} map[string]string
// @Router /food-variety/nutrition/insights [get]
func (h *Handler) GetWeeklyInsights(c *gin.Context) {
	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	insights, err := h.service.GetWeeklyInsights(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, insights)
}

// GenerateWeeklyInsights godoc
// @Summary Generate weekly nutrition insights
// @Description Manually trigger generation of weekly insights
// @Tags food-variety
// @Produce json
// @Success 200 {array} NutritionInsight
// @Failure 500 {object} map[string]string
// @Router /food-variety/nutrition/insights/generate [post]
func (h *Handler) GenerateWeeklyInsights(c *gin.Context) {
	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	insights, err := h.service.GenerateWeeklyInsights(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, insights)
}

// DismissInsight godoc
// @Summary Dismiss a nutrition insight
// @Description Mark an insight as dismissed
// @Tags food-variety
// @Produce json
// @Param insight_id path string true "Insight ID"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /food-variety/nutrition/insights/{insight_id}/dismiss [put]
func (h *Handler) DismissInsight(c *gin.Context) {
	insightID, err := uuid.Parse(c.Param("insight_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid insight_id"})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	err = h.service.DismissInsight(c.Request.Context(), insightID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "insight dismissed"})
}

// Rotation schedule handlers

// CreateRotationSchedule godoc
// @Summary Create food rotation schedule
// @Description Create a structured food rotation schedule
// @Tags food-variety
// @Accept json
// @Produce json
// @Param request body CreateRotationScheduleRequest true "Schedule data"
// @Success 201 {object} FoodRotationSchedule
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /food-variety/rotation-schedules [post]
func (h *Handler) CreateRotationSchedule(c *gin.Context) {
	var req CreateRotationScheduleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	schedule, err := h.service.CreateRotationSchedule(c.Request.Context(), userID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, schedule)
}

// GetRotationSchedules godoc
// @Summary Get rotation schedules
// @Description Get all rotation schedules for user
// @Tags food-variety
// @Produce json
// @Success 200 {array} FoodRotationSchedule
// @Failure 500 {object} map[string]string
// @Router /food-variety/rotation-schedules [get]
func (h *Handler) GetRotationSchedules(c *gin.Context) {
	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	schedules, err := h.service.GetRotationSchedules(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, schedules)
}

// UpdateRotationSchedule godoc
// @Summary Update rotation schedule
// @Description Update an existing rotation schedule
// @Tags food-variety
// @Accept json
// @Produce json
// @Param schedule_id path string true "Schedule ID"
// @Param request body UpdateRotationScheduleRequest true "Schedule update"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /food-variety/rotation-schedules/{schedule_id} [put]
func (h *Handler) UpdateRotationSchedule(c *gin.Context) {
	scheduleID, err := uuid.Parse(c.Param("schedule_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid schedule_id"})
		return
	}

	var req UpdateRotationScheduleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	err = h.service.UpdateRotationSchedule(c.Request.Context(), scheduleID, userID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "schedule updated"})
}

// DeleteRotationSchedule godoc
// @Summary Delete rotation schedule
// @Description Delete a rotation schedule
// @Tags food-variety
// @Produce json
// @Param schedule_id path string true "Schedule ID"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /food-variety/rotation-schedules/{schedule_id} [delete]
func (h *Handler) DeleteRotationSchedule(c *gin.Context) {
	scheduleID, err := uuid.Parse(c.Param("schedule_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid schedule_id"})
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	err = h.service.DeleteRotationSchedule(c.Request.Context(), scheduleID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "schedule deleted"})
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
