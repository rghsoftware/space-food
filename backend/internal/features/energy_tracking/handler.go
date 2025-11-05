// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

package energy_tracking

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// Handler handles HTTP requests for energy tracking
type Handler struct {
	service *Service
}

// NewHandler creates a new energy tracking handler
func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

// RegisterRoutes registers all energy tracking routes
func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	energy := rg.Group("/energy")
	{
		energy.POST("/record", h.RecordEnergy)
		energy.GET("/history", h.GetEnergyHistory)
		energy.GET("/patterns", h.GetEnergyPatterns)
		energy.GET("/recommendations", h.GetRecommendations)
		energy.GET("/recipes", h.GetRecipesByEnergy)
	}

	favorites := rg.Group("/favorite-meals")
	{
		favorites.POST("", h.SaveFavoriteMeal)
		favorites.GET("", h.GetFavoriteMeals)
		favorites.GET("/:id", h.GetFavoriteMeal)
		favorites.PUT("/:id", h.UpdateFavoriteMeal)
		favorites.POST("/:id/eaten", h.MarkEaten)
		favorites.DELETE("/:id", h.DeleteFavoriteMeal)
	}
}

// RecordEnergy records the user's current energy level
func (h *Handler) RecordEnergy(c *gin.Context) {
	var req RecordEnergyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := c.GetString("user_id")
	uid, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user ID"})
		return
	}

	snapshot, err := h.service.RecordEnergy(c.Request.Context(), uid, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, snapshot)
}

// GetEnergyHistory retrieves energy snapshots within a date range
func (h *Handler) GetEnergyHistory(c *gin.Context) {
	userID := c.GetString("user_id")
	uid, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user ID"})
		return
	}

	// Default to 30 days
	days := 30
	if daysStr := c.Query("days"); daysStr != "" {
		if d, err := strconv.Atoi(daysStr); err == nil && d > 0 && d <= 365 {
			days = d
		}
	}

	history, err := h.service.GetEnergyHistory(c.Request.Context(), uid, days)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, history)
}

// GetEnergyPatterns retrieves learned energy patterns for a user
func (h *Handler) GetEnergyPatterns(c *gin.Context) {
	userID := c.GetString("user_id")
	uid, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user ID"})
		return
	}

	patterns, err := h.service.GetEnergyPatterns(c.Request.Context(), uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"patterns": patterns})
}

// GetRecommendations provides meal recommendations based on energy
func (h *Handler) GetRecommendations(c *gin.Context) {
	userID := c.GetString("user_id")
	uid, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user ID"})
		return
	}

	var energyLevel *int
	if energyStr := c.Query("energy_level"); energyStr != "" {
		if e, err := strconv.Atoi(energyStr); err == nil && e >= 1 && e <= 5 {
			energyLevel = &e
		}
	}

	recommendations, err := h.service.GetEnergyBasedRecommendations(c.Request.Context(), uid, energyLevel)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, recommendations)
}

// GetRecipesByEnergy retrieves recipes filtered by energy level
func (h *Handler) GetRecipesByEnergy(c *gin.Context) {
	userID := c.GetString("user_id")
	uid, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user ID"})
		return
	}

	maxEnergy := 3 // Default to moderate
	if maxStr := c.Query("max_energy_level"); maxStr != "" {
		if e, err := strconv.Atoi(maxStr); err == nil && e >= 1 && e <= 5 {
			maxEnergy = e
		}
	}

	limit := 20
	if limitStr := c.Query("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 && l <= 100 {
			limit = l
		}
	}

	recipes, err := h.service.GetRecipesByEnergy(c.Request.Context(), uid, maxEnergy, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"recipes": recipes})
}

// SaveFavoriteMeal creates a new favorite meal
func (h *Handler) SaveFavoriteMeal(c *gin.Context) {
	var req SaveFavoriteMealRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := c.GetString("user_id")
	uid, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user ID"})
		return
	}

	meal, err := h.service.SaveFavoriteMeal(c.Request.Context(), uid, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, meal)
}

// GetFavoriteMeal retrieves a specific favorite meal
func (h *Handler) GetFavoriteMeal(c *gin.Context) {
	mealID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid meal ID"})
		return
	}

	userID := c.GetString("user_id")
	uid, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user ID"})
		return
	}

	meal, err := h.service.GetFavoriteMeal(c.Request.Context(), mealID, uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if meal == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "meal not found"})
		return
	}

	c.JSON(http.StatusOK, meal)
}

// GetFavoriteMeals retrieves favorite meals with optional filtering
func (h *Handler) GetFavoriteMeals(c *gin.Context) {
	userID := c.GetString("user_id")
	uid, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user ID"})
		return
	}

	var req GetMealsRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	meals, err := h.service.GetFavoriteMeals(c.Request.Context(), uid, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"meals": meals})
}

// UpdateFavoriteMeal updates an existing favorite meal
func (h *Handler) UpdateFavoriteMeal(c *gin.Context) {
	mealID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid meal ID"})
		return
	}

	var req UpdateFavoriteMealRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := c.GetString("user_id")
	uid, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user ID"})
		return
	}

	meal, err := h.service.UpdateFavoriteMeal(c.Request.Context(), mealID, uid, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, meal)
}

// MarkEaten increments frequency score and updates last eaten time
func (h *Handler) MarkEaten(c *gin.Context) {
	mealID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid meal ID"})
		return
	}

	userID := c.GetString("user_id")
	uid, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user ID"})
		return
	}

	if err := h.service.MarkMealEaten(c.Request.Context(), mealID, uid); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "meal marked as eaten"})
}

// DeleteFavoriteMeal deletes a favorite meal
func (h *Handler) DeleteFavoriteMeal(c *gin.Context) {
	mealID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid meal ID"})
		return
	}

	userID := c.GetString("user_id")
	uid, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user ID"})
		return
	}

	if err := h.service.DeleteFavoriteMeal(c.Request.Context(), mealID, uid); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "meal deleted"})
}
