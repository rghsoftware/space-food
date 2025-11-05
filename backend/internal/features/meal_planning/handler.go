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

package meal_planning

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/rghsoftware/space-food/internal/database"
	"github.com/rghsoftware/space-food/internal/middleware"
)

// Handler handles meal planning HTTP requests
type Handler struct {
	db database.Database
}

// NewHandler creates a new meal planning handler
func NewHandler(db database.Database) *Handler {
	return &Handler{
		db: db,
	}
}

// RegisterRoutes registers meal planning routes
func (h *Handler) RegisterRoutes(router *gin.RouterGroup) {
	router.GET("", h.ListMealPlans)
	router.GET("/:id", h.GetMealPlan)
	router.POST("", h.CreateMealPlan)
	router.PUT("/:id", h.UpdateMealPlan)
	router.DELETE("/:id", h.DeleteMealPlan)
}

// ListMealPlans lists all meal plans for the authenticated user
func (h *Handler) ListMealPlans(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	startDate := time.Now().AddDate(0, -1, 0) // Last month
	endDate := time.Now().AddDate(0, 3, 0)   // Next 3 months

	filter := database.MealPlanFilter{
		UserID:    user.ID,
		StartDate: startDate,
		EndDate:   endDate,
		Limit:     50,
		Offset:    0,
	}

	plans, err := h.db.ListMealPlans(c.Request.Context(), filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, plans)
}

// GetMealPlan retrieves a single meal plan by ID
func (h *Handler) GetMealPlan(c *gin.Context) {
	id := c.Param("id")

	plan, err := h.db.GetMealPlanByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "meal plan not found"})
		return
	}

	c.JSON(http.StatusOK, plan)
}

// CreateMealPlan creates a new meal plan
func (h *Handler) CreateMealPlan(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	var plan database.MealPlan
	if err := c.ShouldBindJSON(&plan); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	plan.UserID = user.ID

	if err := h.db.CreateMealPlan(c.Request.Context(), &plan); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, plan)
}

// UpdateMealPlan updates an existing meal plan
func (h *Handler) UpdateMealPlan(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	id := c.Param("id")

	// Verify ownership
	existing, err := h.db.GetMealPlanByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "meal plan not found"})
		return
	}

	if existing.UserID != user.ID {
		c.JSON(http.StatusForbidden, gin.H{"error": "forbidden"})
		return
	}

	var plan database.MealPlan
	if err := c.ShouldBindJSON(&plan); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	plan.ID = id
	plan.UserID = user.ID

	if err := h.db.UpdateMealPlan(c.Request.Context(), &plan); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, plan)
}

// DeleteMealPlan deletes a meal plan
func (h *Handler) DeleteMealPlan(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	id := c.Param("id")

	// Verify ownership
	existing, err := h.db.GetMealPlanByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "meal plan not found"})
		return
	}

	if existing.UserID != user.ID {
		c.JSON(http.StatusForbidden, gin.H{"error": "forbidden"})
		return
	}

	if err := h.db.DeleteMealPlan(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}
