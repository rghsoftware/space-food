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

package recipes

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/rghsoftware/space-food/internal/database"
	"github.com/rghsoftware/space-food/internal/middleware"
)

// Handler handles recipe HTTP requests
type Handler struct {
	db database.Database
}

// NewHandler creates a new recipe handler
func NewHandler(db database.Database) *Handler {
	return &Handler{
		db: db,
	}
}

// RegisterRoutes registers recipe routes
func (h *Handler) RegisterRoutes(router *gin.RouterGroup) {
	router.GET("", h.ListRecipes)
	router.GET("/:id", h.GetRecipe)
	router.POST("", h.CreateRecipe)
	router.PUT("/:id", h.UpdateRecipe)
	router.DELETE("/:id", h.DeleteRecipe)
	router.GET("/search", h.SearchRecipes)
}

// ListRecipes lists all recipes for the authenticated user
// @Summary List recipes
// @Tags recipes
// @Produce json
// @Success 200 {array} Recipe
// @Router /recipes [get]
func (h *Handler) ListRecipes(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	filter := database.RecipeFilter{
		UserID: user.ID,
		Limit:  50,
		Offset: 0,
	}

	recipes, err := h.db.ListRecipes(c.Request.Context(), filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, recipes)
}

// GetRecipe retrieves a single recipe by ID
// @Summary Get recipe
// @Tags recipes
// @Produce json
// @Param id path string true "Recipe ID"
// @Success 200 {object} Recipe
// @Router /recipes/{id} [get]
func (h *Handler) GetRecipe(c *gin.Context) {
	id := c.Param("id")

	recipe, err := h.db.GetRecipeByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "recipe not found"})
		return
	}

	c.JSON(http.StatusOK, recipe)
}

// CreateRecipe creates a new recipe
// @Summary Create recipe
// @Tags recipes
// @Accept json
// @Produce json
// @Param recipe body Recipe true "Recipe"
// @Success 201 {object} Recipe
// @Router /recipes [post]
func (h *Handler) CreateRecipe(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	var recipe database.Recipe
	if err := c.ShouldBindJSON(&recipe); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	recipe.UserID = user.ID

	if err := h.db.CreateRecipe(c.Request.Context(), &recipe); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, recipe)
}

// UpdateRecipe updates an existing recipe
// @Summary Update recipe
// @Tags recipes
// @Accept json
// @Produce json
// @Param id path string true "Recipe ID"
// @Param recipe body Recipe true "Recipe"
// @Success 200 {object} Recipe
// @Router /recipes/{id} [put]
func (h *Handler) UpdateRecipe(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	id := c.Param("id")

	// Verify ownership
	existing, err := h.db.GetRecipeByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "recipe not found"})
		return
	}

	if existing.UserID != user.ID {
		c.JSON(http.StatusForbidden, gin.H{"error": "forbidden"})
		return
	}

	var recipe database.Recipe
	if err := c.ShouldBindJSON(&recipe); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	recipe.ID = id
	recipe.UserID = user.ID

	if err := h.db.UpdateRecipe(c.Request.Context(), &recipe); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, recipe)
}

// DeleteRecipe deletes a recipe
// @Summary Delete recipe
// @Tags recipes
// @Param id path string true "Recipe ID"
// @Success 204
// @Router /recipes/{id} [delete]
func (h *Handler) DeleteRecipe(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	id := c.Param("id")

	// Verify ownership
	existing, err := h.db.GetRecipeByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "recipe not found"})
		return
	}

	if existing.UserID != user.ID {
		c.JSON(http.StatusForbidden, gin.H{"error": "forbidden"})
		return
	}

	if err := h.db.DeleteRecipe(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}

// SearchRecipes searches recipes
// @Summary Search recipes
// @Tags recipes
// @Produce json
// @Param q query string true "Search query"
// @Success 200 {array} Recipe
// @Router /recipes/search [get]
func (h *Handler) SearchRecipes(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "query parameter required"})
		return
	}

	recipes, err := h.db.SearchRecipes(c.Request.Context(), query)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, recipes)
}
