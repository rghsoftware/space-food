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

package shopping_list

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/rghsoftware/space-food/internal/database"
	"github.com/rghsoftware/space-food/internal/middleware"
)

// Handler handles shopping list HTTP requests
type Handler struct {
	db database.Database
}

// NewHandler creates a new shopping list handler
func NewHandler(db database.Database) *Handler {
	return &Handler{
		db: db,
	}
}

// RegisterRoutes registers shopping list routes
func (h *Handler) RegisterRoutes(router *gin.RouterGroup) {
	router.GET("", h.ListShoppingListItems)
	router.GET("/:id", h.GetShoppingListItem)
	router.POST("", h.CreateShoppingListItem)
	router.PUT("/:id", h.UpdateShoppingListItem)
	router.DELETE("/:id", h.DeleteShoppingListItem)
	router.PATCH("/:id/toggle", h.ToggleShoppingListItem)
}

// ListShoppingListItems lists all shopping list items for the authenticated user
func (h *Handler) ListShoppingListItems(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	filter := database.ShoppingListFilter{
		UserID: user.ID,
		Limit:  200,
		Offset: 0,
	}

	items, err := h.db.ListShoppingListItems(c.Request.Context(), filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, items)
}

// GetShoppingListItem retrieves a single shopping list item by ID
func (h *Handler) GetShoppingListItem(c *gin.Context) {
	id := c.Param("id")

	item, err := h.db.GetShoppingListItemByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "shopping list item not found"})
		return
	}

	c.JSON(http.StatusOK, item)
}

// CreateShoppingListItem creates a new shopping list item
func (h *Handler) CreateShoppingListItem(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	var item database.ShoppingListItem
	if err := c.ShouldBindJSON(&item); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	item.UserID = user.ID

	if err := h.db.CreateShoppingListItem(c.Request.Context(), &item); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, item)
}

// UpdateShoppingListItem updates an existing shopping list item
func (h *Handler) UpdateShoppingListItem(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	id := c.Param("id")

	// Verify ownership
	existing, err := h.db.GetShoppingListItemByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "shopping list item not found"})
		return
	}

	if existing.UserID != user.ID {
		c.JSON(http.StatusForbidden, gin.H{"error": "forbidden"})
		return
	}

	var item database.ShoppingListItem
	if err := c.ShouldBindJSON(&item); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	item.ID = id
	item.UserID = user.ID

	if err := h.db.UpdateShoppingListItem(c.Request.Context(), &item); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, item)
}

// DeleteShoppingListItem deletes a shopping list item
func (h *Handler) DeleteShoppingListItem(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	id := c.Param("id")

	// Verify ownership
	existing, err := h.db.GetShoppingListItemByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "shopping list item not found"})
		return
	}

	if existing.UserID != user.ID {
		c.JSON(http.StatusForbidden, gin.H{"error": "forbidden"})
		return
	}

	if err := h.db.DeleteShoppingListItem(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}

// ToggleShoppingListItem toggles the completed status of a shopping list item
func (h *Handler) ToggleShoppingListItem(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	id := c.Param("id")

	// Verify ownership
	existing, err := h.db.GetShoppingListItemByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "shopping list item not found"})
		return
	}

	if existing.UserID != user.ID {
		c.JSON(http.StatusForbidden, gin.H{"error": "forbidden"})
		return
	}

	existing.Completed = !existing.Completed

	if err := h.db.UpdateShoppingListItem(c.Request.Context(), existing); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, existing)
}
