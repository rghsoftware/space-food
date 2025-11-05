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

package pantry

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/rghsoftware/space-food/internal/database"
	"github.com/rghsoftware/space-food/internal/middleware"
)

// Handler handles pantry HTTP requests
type Handler struct {
	db database.Database
}

// NewHandler creates a new pantry handler
func NewHandler(db database.Database) *Handler {
	return &Handler{
		db: db,
	}
}

// RegisterRoutes registers pantry routes
func (h *Handler) RegisterRoutes(router *gin.RouterGroup) {
	router.GET("", h.ListPantryItems)
	router.GET("/:id", h.GetPantryItem)
	router.POST("", h.CreatePantryItem)
	router.PUT("/:id", h.UpdatePantryItem)
	router.DELETE("/:id", h.DeletePantryItem)
}

// ListPantryItems lists all pantry items for the authenticated user
func (h *Handler) ListPantryItems(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	filter := database.PantryFilter{
		UserID: user.ID,
		Limit:  100,
		Offset: 0,
	}

	items, err := h.db.ListPantryItems(c.Request.Context(), filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, items)
}

// GetPantryItem retrieves a single pantry item by ID
func (h *Handler) GetPantryItem(c *gin.Context) {
	id := c.Param("id")

	item, err := h.db.GetPantryItemByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "pantry item not found"})
		return
	}

	c.JSON(http.StatusOK, item)
}

// CreatePantryItem creates a new pantry item
func (h *Handler) CreatePantryItem(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	var item database.PantryItem
	if err := c.ShouldBindJSON(&item); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	item.UserID = user.ID

	if err := h.db.CreatePantryItem(c.Request.Context(), &item); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, item)
}

// UpdatePantryItem updates an existing pantry item
func (h *Handler) UpdatePantryItem(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	id := c.Param("id")

	// Verify ownership
	existing, err := h.db.GetPantryItemByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "pantry item not found"})
		return
	}

	if existing.UserID != user.ID {
		c.JSON(http.StatusForbidden, gin.H{"error": "forbidden"})
		return
	}

	var item database.PantryItem
	if err := c.ShouldBindJSON(&item); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	item.ID = id
	item.UserID = user.ID

	if err := h.db.UpdatePantryItem(c.Request.Context(), &item); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, item)
}

// DeletePantryItem deletes a pantry item
func (h *Handler) DeletePantryItem(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	id := c.Param("id")

	// Verify ownership
	existing, err := h.db.GetPantryItemByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "pantry item not found"})
		return
	}

	if existing.UserID != user.ID {
		c.JSON(http.StatusForbidden, gin.H{"error": "forbidden"})
		return
	}

	if err := h.db.DeletePantryItem(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}
