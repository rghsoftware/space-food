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

package ai

import (
	"context"
)

// Provider defines the interface for AI providers
type Provider interface {
	// Generate generates text completion based on a prompt
	Generate(ctx context.Context, req GenerateRequest) (*GenerateResponse, error)

	// Chat performs a chat-based conversation
	Chat(ctx context.Context, req ChatRequest) (*ChatResponse, error)

	// Stream generates text with streaming response
	Stream(ctx context.Context, req GenerateRequest, callback func(string) error) error

	// GetName returns the provider name
	GetName() string

	// IsAvailable checks if the provider is available and configured
	IsAvailable() bool
}

// GenerateRequest represents a text generation request
type GenerateRequest struct {
	Prompt      string
	MaxTokens   int
	Temperature float64
	SystemMsg   string
}

// GenerateResponse represents a text generation response
type GenerateResponse struct {
	Text         string
	TokensUsed   int
	FinishReason string
}

// ChatRequest represents a chat conversation request
type ChatRequest struct {
	Messages    []Message
	MaxTokens   int
	Temperature float64
	SystemMsg   string
}

// ChatResponse represents a chat conversation response
type ChatResponse struct {
	Message      Message
	TokensUsed   int
	FinishReason string
}

// Message represents a chat message
type Message struct {
	Role    string // "user", "assistant", "system"
	Content string
}

// RecipeSuggestionRequest for AI-powered recipe suggestions
type RecipeSuggestionRequest struct {
	Ingredients    []string
	DietaryReqs    []string // vegetarian, vegan, gluten-free, etc.
	Cuisine        string
	MaxPrepTime    int // minutes
	ServingSize    int
	SkillLevel     string // beginner, intermediate, advanced
	ExcludeRecipes []string
}

// RecipeSuggestion represents an AI-generated recipe suggestion
type RecipeSuggestion struct {
	Title          string
	Description    string
	Ingredients    []string
	Instructions   []string
	PrepTime       int
	CookTime       int
	Servings       int
	Difficulty     string
	EstimatedCost  string
	NutritionEst   map[string]float64
}

// MealPlanRequest for AI-powered meal plan generation
type MealPlanRequest struct {
	Days           int
	PeopleCount    int
	DietaryReqs    []string
	CalorieTarget  int
	Budget         float64
	SkipBreakfast  bool
	SkipLunch      bool
	SkipDinner     bool
	ExcludeRecipes []string
	Preferences    []string
}

// MealPlanSuggestion represents an AI-generated meal plan
type MealPlanSuggestion struct {
	Days        []DayPlan
	TotalCost   float64
	Description string
}

// DayPlan represents meals for a single day
type DayPlan struct {
	Day       int
	Breakfast *RecipeSuggestion
	Lunch     *RecipeSuggestion
	Dinner    *RecipeSuggestion
	Snacks    []*RecipeSuggestion
}

// RecipeVariationRequest for generating recipe variations
type RecipeVariationRequest struct {
	OriginalRecipe string
	Variations     []string // "healthier", "faster", "cheaper", "vegetarian"
}
