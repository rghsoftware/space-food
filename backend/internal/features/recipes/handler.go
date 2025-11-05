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
	"fmt"
	"net/http"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/rghsoftware/space-food/internal/database"
	"github.com/rghsoftware/space-food/internal/middleware"
	"github.com/rghsoftware/space-food/internal/storage"
)

// Handler handles recipe HTTP requests
type Handler struct {
	db             database.Database
	scraper        *Scraper
	storageProvider storage.Provider
}

// NewHandler creates a new recipe handler
func NewHandler(db database.Database, storageProvider storage.Provider) *Handler {
	return &Handler{
		db:              db,
		scraper:         NewScraper(),
		storageProvider: storageProvider,
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
	router.POST("/import", h.ImportFromURL)
	router.POST("/:id/image", h.UploadImage)
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

// ImportFromURL imports a recipe from a URL
// @Summary Import recipe from URL
// @Tags recipes
// @Accept json
// @Produce json
// @Param request body object true "Import request with URL"
// @Success 200 {object} Recipe
// @Router /recipes/import [post]
func (h *Handler) ImportFromURL(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	var req struct {
		URL string `json:"url" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Scrape recipe from URL
	recipe, err := h.scraper.ScrapeRecipe(c.Request.Context(), req.URL)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("failed to import recipe: %v", err)})
		return
	}

	// Set user ID and generate IDs for ingredients
	recipe.UserID = user.ID
	recipe.ID = uuid.New().String()
	recipe.CreatedAt = time.Now()
	recipe.UpdatedAt = time.Now()

	for i := range recipe.Ingredients {
		recipe.Ingredients[i].ID = uuid.New().String()
		recipe.Ingredients[i].RecipeID = recipe.ID
	}

	// Save to database
	if err := h.db.CreateRecipe(c.Request.Context(), recipe); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, recipe)
}

// UploadImage uploads an image for a recipe
// @Summary Upload recipe image
// @Tags recipes
// @Accept multipart/form-data
// @Produce json
// @Param id path string true "Recipe ID"
// @Param image formData file true "Image file"
// @Success 200 {object} object
// @Router /recipes/{id}/image [post]
func (h *Handler) UploadImage(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	id := c.Param("id")

	// Verify ownership
	recipe, err := h.db.GetRecipeByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "recipe not found"})
		return
	}

	if recipe.UserID != user.ID {
		c.JSON(http.StatusForbidden, gin.H{"error": "forbidden"})
		return
	}

	// Get uploaded file
	file, err := c.FormFile("image")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "no image file provided"})
		return
	}

	// Validate file type
	ext := strings.ToLower(filepath.Ext(file.Filename))
	allowedExts := map[string]bool{
		".jpg":  true,
		".jpeg": true,
		".png":  true,
		".gif":  true,
		".webp": true,
	}

	if !allowedExts[ext] {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid file type, allowed: jpg, jpeg, png, gif, webp"})
		return
	}

	// Validate file size (max 10MB)
	if file.Size > 10*1024*1024 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "file too large, maximum size is 10MB"})
		return
	}

	// Open file
	f, err := file.Open()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to read file"})
		return
	}
	defer f.Close()

	// Determine content type
	contentType := "image/jpeg"
	switch ext {
	case ".png":
		contentType = "image/png"
	case ".gif":
		contentType = "image/gif"
	case ".webp":
		contentType = "image/webp"
	}

	// Delete old image if exists
	if recipe.ImageURL != "" {
		h.storageProvider.Delete(c.Request.Context(), recipe.ImageURL)
	}

	// Upload file
	imageURL, err := h.storageProvider.Upload(c.Request.Context(), file.Filename, contentType, f)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("failed to upload image: %v", err)})
		return
	}

	// Update recipe with image URL
	recipe.ImageURL = imageURL
	if err := h.db.UpdateRecipe(c.Request.Context(), recipe); err != nil {
		// Try to delete uploaded file on error
		h.storageProvider.Delete(c.Request.Context(), imageURL)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update recipe"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"image_url": imageURL})
}
