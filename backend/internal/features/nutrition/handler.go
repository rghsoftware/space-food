/*
 * Space Food - Self-Hosted Meal Planning Application
 * Copyright (C) 2025 RGH Software
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

package nutrition

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/rghsoftware/space-food/internal/config"
	"github.com/rghsoftware/space-food/internal/database"
	"github.com/rghsoftware/space-food/internal/middleware"
)

// Handler handles nutrition tracking HTTP requests
type Handler struct {
	db         database.Database
	usdaClient *USDAClient
}

// NewHandler creates a new nutrition handler
func NewHandler(db database.Database, cfg *config.Config) *Handler {
	var usdaClient *USDAClient
	if cfg.Nutrition.USDAAPIKey != "" {
		usdaClient = NewUSDAClient(cfg.Nutrition.USDAAPIKey)
	}
	return &Handler{
		db:         db,
		usdaClient: usdaClient,
	}
}

// RegisterRoutes registers nutrition routes
func (h *Handler) RegisterRoutes(router *gin.RouterGroup) {
	router.GET("/logs", h.ListNutritionLogs)
	router.GET("/logs/today", h.GetTodayNutritionLog)
	router.POST("/logs", h.CreateNutritionLog)
	router.GET("/summary", h.GetNutritionSummary)

	// USDA FoodData routes (if USDA client is available)
	if h.usdaClient != nil {
		router.GET("/foods/search", h.SearchFoods)
		router.GET("/foods/:fdcId", h.GetFoodDetail)
	}
}

// ListNutritionLogs lists nutrition logs for the authenticated user
func (h *Handler) ListNutritionLogs(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	// Default to last 30 days
	startDate := time.Now().AddDate(0, 0, -30)
	endDate := time.Now()

	filter := database.NutritionFilter{
		UserID:    user.ID,
		StartDate: startDate,
		EndDate:   endDate,
		Limit:     100,
		Offset:    0,
	}

	logs, err := h.db.ListNutritionLogs(c.Request.Context(), filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, logs)
}

// GetTodayNutritionLog retrieves nutrition logs for today
func (h *Handler) GetTodayNutritionLog(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	today := time.Now().Truncate(24 * time.Hour)

	logs, err := h.db.GetNutritionLog(c.Request.Context(), user.ID, today)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, logs)
}

// CreateNutritionLog creates a new nutrition log entry
func (h *Handler) CreateNutritionLog(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	var log database.NutritionLog
	if err := c.ShouldBindJSON(&log); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	log.UserID = user.ID

	if err := h.db.CreateNutritionLog(c.Request.Context(), &log); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, log)
}

// GetNutritionSummary returns aggregated nutrition summary for a date range
func (h *Handler) GetNutritionSummary(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	// Default to last 7 days
	startDate := time.Now().AddDate(0, 0, -7)
	endDate := time.Now()

	filter := database.NutritionFilter{
		UserID:    user.ID,
		StartDate: startDate,
		EndDate:   endDate,
		Limit:     1000,
		Offset:    0,
	}

	logs, err := h.db.ListNutritionLogs(c.Request.Context(), filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Calculate summary
	summary := make(map[string]*database.NutritionInfo)
	for _, log := range logs {
		dateKey := log.Date.Format("2006-01-02")
		if summary[dateKey] == nil {
			summary[dateKey] = &database.NutritionInfo{}
		}
		summary[dateKey].Calories += log.NutritionInfo.Calories * log.Servings
		summary[dateKey].Protein += log.NutritionInfo.Protein * log.Servings
		summary[dateKey].Carbohydrates += log.NutritionInfo.Carbohydrates * log.Servings
		summary[dateKey].Fat += log.NutritionInfo.Fat * log.Servings
		summary[dateKey].Fiber += log.NutritionInfo.Fiber * log.Servings
		summary[dateKey].Sugar += log.NutritionInfo.Sugar * log.Servings
		summary[dateKey].Sodium += log.NutritionInfo.Sodium * log.Servings
	}

	c.JSON(http.StatusOK, gin.H{"summary": summary})
}

// SearchFoods searches for foods in the USDA database
// @Summary Search USDA foods
// @Tags nutrition
// @Accept json
// @Produce json
// @Param query query string true "Search query"
// @Param pageSize query int false "Number of results (default 10, max 50)"
// @Success 200 {array} FoodSearchResult
// @Router /nutrition/foods/search [get]
func (h *Handler) SearchFoods(c *gin.Context) {
	query := c.Query("query")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "query parameter is required"})
		return
	}

	pageSize := 10
	if pageSizeStr := c.Query("pageSize"); pageSizeStr != "" {
		if ps, err := strconv.Atoi(pageSizeStr); err == nil && ps > 0 && ps <= 50 {
			pageSize = ps
		}
	}

	foods, err := h.usdaClient.SearchFoods(c.Request.Context(), query, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, foods)
}

// GetFoodDetail retrieves detailed nutrition information for a specific food
// @Summary Get food detail
// @Tags nutrition
// @Accept json
// @Produce json
// @Param fdcId path int true "USDA FDC ID"
// @Success 200 {object} FoodDetail
// @Router /nutrition/foods/{fdcId} [get]
func (h *Handler) GetFoodDetail(c *gin.Context) {
	fdcIDStr := c.Param("fdcId")
	fdcID, err := strconv.Atoi(fdcIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid fdcId"})
		return
	}

	detail, err := h.usdaClient.GetFoodDetail(c.Request.Context(), fdcID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, detail)
}
