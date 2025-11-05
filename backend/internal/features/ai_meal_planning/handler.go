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

package ai_meal_planning

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/rghsoftware/space-food/internal/ai"
)

// Handler handles AI-powered meal planning features
type Handler struct {
	aiService *ai.Service
}

// NewHandler creates a new AI meal planning handler
func NewHandler(aiService *ai.Service) *Handler {
	return &Handler{
		aiService: aiService,
	}
}

// RegisterRoutes registers AI meal planning routes
func (h *Handler) RegisterRoutes(router *gin.RouterGroup) {
	router.POST("/generate", h.GenerateMealPlan)
}

// GenerateMealPlan generates an AI-powered meal plan
// @Summary Generate meal plan
// @Tags ai-meal-planning
// @Accept json
// @Produce json
// @Param request body ai.MealPlanRequest true "Meal plan requirements"
// @Success 200 {object} ai.MealPlanSuggestion
// @Router /ai/meal-planning/generate [post]
func (h *Handler) GenerateMealPlan(c *gin.Context) {
	var req ai.MealPlanRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Validate request
	if req.Days <= 0 || req.Days > 30 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "days must be between 1 and 30"})
		return
	}

	if req.PeopleCount <= 0 || req.PeopleCount > 20 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "people count must be between 1 and 20"})
		return
	}

	suggestion, err := h.aiService.GenerateMealPlan(c.Request.Context(), req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, suggestion)
}
