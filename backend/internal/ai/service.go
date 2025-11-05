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
	"encoding/json"
	"fmt"
	"strings"
)

// Service provides high-level AI features
type Service struct {
	provider Provider
}

// NewService creates a new AI service
func NewService(provider Provider) *Service {
	return &Service{
		provider: provider,
	}
}

// SuggestRecipe generates recipe suggestions based on requirements
func (s *Service) SuggestRecipe(ctx context.Context, req RecipeSuggestionRequest) (*RecipeSuggestion, error) {
	prompt := s.buildRecipeSuggestionPrompt(req)

	genReq := GenerateRequest{
		Prompt:      prompt,
		MaxTokens:   2000,
		Temperature: 0.7,
		SystemMsg:   "You are a professional chef and recipe expert. Provide detailed, practical recipes in JSON format.",
	}

	resp, err := s.provider.Generate(ctx, genReq)
	if err != nil {
		return nil, fmt.Errorf("failed to generate recipe: %w", err)
	}

	// Parse the response as JSON
	var suggestion RecipeSuggestion
	if err := s.parseJSONResponse(resp.Text, &suggestion); err != nil {
		return nil, fmt.Errorf("failed to parse recipe suggestion: %w", err)
	}

	return &suggestion, nil
}

// GenerateMealPlan generates a meal plan based on requirements
func (s *Service) GenerateMealPlan(ctx context.Context, req MealPlanRequest) (*MealPlanSuggestion, error) {
	prompt := s.buildMealPlanPrompt(req)

	genReq := GenerateRequest{
		Prompt:      prompt,
		MaxTokens:   3000,
		Temperature: 0.7,
		SystemMsg:   "You are a professional meal planner and nutritionist. Create balanced, practical meal plans in JSON format.",
	}

	resp, err := s.provider.Generate(ctx, genReq)
	if err != nil {
		return nil, fmt.Errorf("failed to generate meal plan: %w", err)
	}

	// Parse the response as JSON
	var suggestion MealPlanSuggestion
	if err := s.parseJSONResponse(resp.Text, &suggestion); err != nil {
		return nil, fmt.Errorf("failed to parse meal plan: %w", err)
	}

	return &suggestion, nil
}

// GenerateRecipeVariation generates variations of an existing recipe
func (s *Service) GenerateRecipeVariation(ctx context.Context, req RecipeVariationRequest) ([]*RecipeSuggestion, error) {
	prompt := fmt.Sprintf(`Given this recipe:
%s

Generate %d variations with the following modifications: %s

Return as a JSON array of recipe objects with title, description, ingredients, instructions, prep_time, cook_time, servings, and difficulty.`,
		req.OriginalRecipe,
		len(req.Variations),
		strings.Join(req.Variations, ", "),
	)

	genReq := GenerateRequest{
		Prompt:      prompt,
		MaxTokens:   2500,
		Temperature: 0.8,
		SystemMsg:   "You are a creative chef who specializes in recipe adaptations.",
	}

	resp, err := s.provider.Generate(ctx, genReq)
	if err != nil {
		return nil, fmt.Errorf("failed to generate variations: %w", err)
	}

	var variations []*RecipeSuggestion
	if err := s.parseJSONResponse(resp.Text, &variations); err != nil {
		return nil, fmt.Errorf("failed to parse variations: %w", err)
	}

	return variations, nil
}

// AnalyzeNutrition estimates nutrition information for a recipe
func (s *Service) AnalyzeNutrition(ctx context.Context, recipeName string, ingredients []string) (map[string]float64, error) {
	prompt := fmt.Sprintf(`Analyze the nutritional content of this recipe:
Recipe: %s
Ingredients:
%s

Provide estimated nutrition per serving in JSON format with keys: calories, protein, carbohydrates, fat, fiber, sugar, sodium.
All values should be numbers (grams except calories).`,
		recipeName,
		strings.Join(ingredients, "\n"),
	)

	genReq := GenerateRequest{
		Prompt:      prompt,
		MaxTokens:   500,
		Temperature: 0.3,
		SystemMsg:   "You are a nutrition expert. Provide accurate nutritional estimates.",
	}

	resp, err := s.provider.Generate(ctx, genReq)
	if err != nil {
		return nil, fmt.Errorf("failed to analyze nutrition: %w", err)
	}

	var nutrition map[string]float64
	if err := s.parseJSONResponse(resp.Text, &nutrition); err != nil {
		return nil, fmt.Errorf("failed to parse nutrition data: %w", err)
	}

	return nutrition, nil
}

// SuggestSubstitutions suggests ingredient substitutions
func (s *Service) SuggestSubstitutions(ctx context.Context, ingredient string, reason string) ([]string, error) {
	prompt := fmt.Sprintf(`Suggest 5 substitutions for this ingredient: %s
Reason for substitution: %s

Return as a JSON array of strings, each being a viable substitution with a brief explanation.`,
		ingredient,
		reason,
	)

	genReq := GenerateRequest{
		Prompt:      prompt,
		MaxTokens:   300,
		Temperature: 0.6,
		SystemMsg:   "You are a culinary expert knowledgeable about ingredient substitutions.",
	}

	resp, err := s.provider.Generate(ctx, genReq)
	if err != nil {
		return nil, fmt.Errorf("failed to generate substitutions: %w", err)
	}

	var substitutions []string
	if err := s.parseJSONResponse(resp.Text, &substitutions); err != nil {
		return nil, fmt.Errorf("failed to parse substitutions: %w", err)
	}

	return substitutions, nil
}

func (s *Service) buildRecipeSuggestionPrompt(req RecipeSuggestionRequest) string {
	var parts []string

	parts = append(parts, "Generate a recipe with the following requirements:")

	if len(req.Ingredients) > 0 {
		parts = append(parts, fmt.Sprintf("- Must use these ingredients: %s", strings.Join(req.Ingredients, ", ")))
	}

	if len(req.DietaryReqs) > 0 {
		parts = append(parts, fmt.Sprintf("- Dietary requirements: %s", strings.Join(req.DietaryReqs, ", ")))
	}

	if req.Cuisine != "" {
		parts = append(parts, fmt.Sprintf("- Cuisine type: %s", req.Cuisine))
	}

	if req.MaxPrepTime > 0 {
		parts = append(parts, fmt.Sprintf("- Maximum prep time: %d minutes", req.MaxPrepTime))
	}

	if req.ServingSize > 0 {
		parts = append(parts, fmt.Sprintf("- Servings: %d", req.ServingSize))
	}

	if req.SkillLevel != "" {
		parts = append(parts, fmt.Sprintf("- Skill level: %s", req.SkillLevel))
	}

	parts = append(parts, "\nReturn the recipe as JSON with: title, description, ingredients (array of strings), instructions (array of strings), prep_time, cook_time, servings, difficulty, estimated_cost")

	return strings.Join(parts, "\n")
}

func (s *Service) buildMealPlanPrompt(req MealPlanRequest) string {
	var parts []string

	parts = append(parts, fmt.Sprintf("Generate a %d-day meal plan for %d people with:", req.Days, req.PeopleCount))

	if len(req.DietaryReqs) > 0 {
		parts = append(parts, fmt.Sprintf("- Dietary requirements: %s", strings.Join(req.DietaryReqs, ", ")))
	}

	if req.CalorieTarget > 0 {
		parts = append(parts, fmt.Sprintf("- Daily calorie target: %d", req.CalorieTarget))
	}

	if req.Budget > 0 {
		parts = append(parts, fmt.Sprintf("- Budget: $%.2f", req.Budget))
	}

	var skipMeals []string
	if req.SkipBreakfast {
		skipMeals = append(skipMeals, "breakfast")
	}
	if req.SkipLunch {
		skipMeals = append(skipMeals, "lunch")
	}
	if req.SkipDinner {
		skipMeals = append(skipMeals, "dinner")
	}
	if len(skipMeals) > 0 {
		parts = append(parts, fmt.Sprintf("- Skip: %s", strings.Join(skipMeals, ", ")))
	}

	if len(req.Preferences) > 0 {
		parts = append(parts, fmt.Sprintf("- Preferences: %s", strings.Join(req.Preferences, ", ")))
	}

	parts = append(parts, "\nReturn as JSON with days array, each containing breakfast, lunch, dinner (each with title, description, ingredients, instructions, prep_time, cook_time, servings)")

	return strings.Join(parts, "\n")
}

func (s *Service) parseJSONResponse(text string, v interface{}) error {
	// Try to extract JSON from markdown code blocks if present
	text = strings.TrimSpace(text)

	// Remove markdown code fences
	if strings.HasPrefix(text, "```json") {
		text = strings.TrimPrefix(text, "```json")
		text = strings.TrimSuffix(text, "```")
	} else if strings.HasPrefix(text, "```") {
		text = strings.TrimPrefix(text, "```")
		text = strings.TrimSuffix(text, "```")
	}

	text = strings.TrimSpace(text)

	// Try to find JSON object or array
	startIdx := strings.Index(text, "{")
	if startIdx == -1 {
		startIdx = strings.Index(text, "[")
	}
	if startIdx != -1 {
		text = text[startIdx:]
	}

	endIdx := strings.LastIndex(text, "}")
	if endIdx == -1 {
		endIdx = strings.LastIndex(text, "]")
	}
	if endIdx != -1 {
		text = text[:endIdx+1]
	}

	return json.Unmarshal([]byte(text), v)
}
