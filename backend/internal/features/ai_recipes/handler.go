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

package ai_recipes

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/rghsoftware/space-food/internal/ai"
)

// Handler handles AI-powered recipe features
type Handler struct {
	aiService *ai.Service
}

// NewHandler creates a new AI recipes handler
func NewHandler(aiService *ai.Service) *Handler {
	return &Handler{
		aiService: aiService,
	}
}

// RegisterRoutes registers AI recipe routes
func (h *Handler) RegisterRoutes(router *gin.RouterGroup) {
	router.POST("/suggest", h.SuggestRecipe)
	router.POST("/variations", h.GenerateVariations)
	router.POST("/analyze-nutrition", h.AnalyzeNutrition)
	router.POST("/substitutions", h.SuggestSubstitutions)
}

// SuggestRecipe generates AI-powered recipe suggestions
// @Summary Generate recipe suggestion
// @Tags ai-recipes
// @Accept json
// @Produce json
// @Param request body ai.RecipeSuggestionRequest true "Recipe requirements"
// @Success 200 {object} ai.RecipeSuggestion
// @Router /ai/recipes/suggest [post]
func (h *Handler) SuggestRecipe(c *gin.Context) {
	var req ai.RecipeSuggestionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	suggestion, err := h.aiService.SuggestRecipe(c.Request.Context(), req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, suggestion)
}

// GenerateVariations generates variations of an existing recipe
// @Summary Generate recipe variations
// @Tags ai-recipes
// @Accept json
// @Produce json
// @Param request body ai.RecipeVariationRequest true "Variation request"
// @Success 200 {array} ai.RecipeSuggestion
// @Router /ai/recipes/variations [post]
func (h *Handler) GenerateVariations(c *gin.Context) {
	var req ai.RecipeVariationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	variations, err := h.aiService.GenerateRecipeVariation(c.Request.Context(), req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, variations)
}

// AnalyzeNutrition estimates nutrition information for a recipe
// @Summary Analyze recipe nutrition
// @Tags ai-recipes
// @Accept json
// @Produce json
// @Param request body object true "Recipe details"
// @Success 200 {object} map[string]float64
// @Router /ai/recipes/analyze-nutrition [post]
func (h *Handler) AnalyzeNutrition(c *gin.Context) {
	var req struct {
		RecipeName  string   `json:"recipe_name" binding:"required"`
		Ingredients []string `json:"ingredients" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	nutrition, err := h.aiService.AnalyzeNutrition(c.Request.Context(), req.RecipeName, req.Ingredients)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"nutrition": nutrition})
}

// SuggestSubstitutions suggests ingredient substitutions
// @Summary Suggest ingredient substitutions
// @Tags ai-recipes
// @Accept json
// @Produce json
// @Param request body object true "Substitution request"
// @Success 200 {array} string
// @Router /ai/recipes/substitutions [post]
func (h *Handler) SuggestSubstitutions(c *gin.Context) {
	var req struct {
		Ingredient string `json:"ingredient" binding:"required"`
		Reason     string `json:"reason"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	substitutions, err := h.aiService.SuggestSubstitutions(c.Request.Context(), req.Ingredient, req.Reason)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"substitutions": substitutions})
}
