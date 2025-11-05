// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

package cooking_assistant

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/google/uuid"
)

// AIService defines the interface for AI-powered recipe breakdown generation
type AIService interface {
	GenerateRecipeBreakdown(ctx context.Context, recipeID uuid.UUID, granularity int, energyLevel *int) (BreakdownData, error)
	GetProvider() string
	GetModel() string
}

// MockAIService provides a mock implementation for testing/development
type MockAIService struct {
	provider string
	model    string
}

// NewMockAIService creates a new mock AI service
func NewMockAIService() AIService {
	return &MockAIService{
		provider: "mock",
		model:    "mock-v1",
	}
}

func (m *MockAIService) GenerateRecipeBreakdown(ctx context.Context, recipeID uuid.UUID, granularity int, energyLevel *int) (BreakdownData, error) {
	// Generate mock breakdown based on granularity level
	steps := generateMockSteps(granularity, energyLevel)

	breakdown := BreakdownData{
		Steps:             steps,
		TotalTimeSeconds:  1800, // 30 minutes
		ActiveTimeSeconds: 1200, // 20 minutes
		PrepSteps:         []int{0, 1, 2},
		CookingSteps:      []int{3, 4, 5},
	}

	return breakdown, nil
}

func (m *MockAIService) GetProvider() string {
	return m.provider
}

func (m *MockAIService) GetModel() string {
	return m.model
}

// generateMockSteps creates mock cooking steps based on granularity
func generateMockSteps(granularity int, energyLevel *int) []BreakdownStep {
	switch granularity {
	case 1: // Very detailed - ADHD-friendly
		return []BreakdownStep{
			{
				Index:           0,
				Text:            "Open the cabinet below your stove",
				DurationSeconds: 10,
				Timers:          []BreakdownTimer{},
				Dependencies:    []int{},
				Tips:            []string{"The large pot should be on the bottom shelf"},
			},
			{
				Index:           1,
				Text:            "Get out the large silver pot (the 8-quart one)",
				DurationSeconds: 10,
				Timers:          []BreakdownTimer{},
				Dependencies:    []int{0},
				Tips:            []string{"It has a glass lid"},
			},
			{
				Index:           2,
				Text:            "Carry the pot to the sink",
				DurationSeconds: 5,
				Timers:          []BreakdownTimer{},
				Dependencies:    []int{1},
				Tips:            []string{"Hold with both hands"},
			},
			{
				Index:           3,
				Text:            "Turn on the cold water tap",
				DurationSeconds: 2,
				Timers:          []BreakdownTimer{},
				Dependencies:    []int{2},
				Tips:            []string{},
			},
			{
				Index:           4,
				Text:            "Fill pot about 3/4 full (about 6 quarts)",
				DurationSeconds: 30,
				Timers:          []BreakdownTimer{},
				Dependencies:    []int{3},
				Tips:            []string{"Stop when water reaches the second line inside the pot"},
			},
			{
				Index:           5,
				Text:            "Turn off the water tap",
				DurationSeconds: 2,
				Timers:          []BreakdownTimer{},
				Dependencies:    []int{4},
				Tips:            []string{},
			},
			{
				Index:           6,
				Text:            "Carry pot carefully to the stove",
				DurationSeconds: 10,
				Timers:          []BreakdownTimer{},
				Dependencies:    []int{5},
				Tips:            []string{"Water is heavy! Go slowly to avoid spilling"},
			},
			{
				Index:           7,
				Text:            "Place pot on the front-right burner",
				DurationSeconds: 5,
				Timers:          []BreakdownTimer{},
				Dependencies:    []int{6},
				Tips:            []string{"Center it on the burner"},
			},
			{
				Index:           8,
				Text:            "Turn the dial to 'HIGH' position",
				DurationSeconds: 2,
				Timers:          []BreakdownTimer{},
				Dependencies:    []int{7},
				Tips:            []string{"You'll hear a click when it lights"},
			},
			{
				Index:           9,
				Text:            "Wait for bubbles to appear (this takes about 7 minutes)",
				DurationSeconds: 420,
				Timers: []BreakdownTimer{
					{Name: "Water boiling", DurationSeconds: 420},
				},
				Dependencies: []int{8},
				Tips:         []string{"This is a good time to prep other ingredients"},
			},
		}

	case 2: // Detailed
		return []BreakdownStep{
			{
				Index:           0,
				Text:            "Get a large pot (8-quart) from below the stove",
				DurationSeconds: 20,
				Timers:          []BreakdownTimer{},
				Dependencies:    []int{},
				Tips:            []string{"The pot with the glass lid works best"},
			},
			{
				Index:           1,
				Text:            "Fill pot 3/4 full with cold water (about 6 quarts)",
				DurationSeconds: 40,
				Timers:          []BreakdownTimer{},
				Dependencies:    []int{0},
				Tips:            []string{"Cold water boils clearer than hot tap water"},
			},
			{
				Index:           2,
				Text:            "Place pot on stove and turn burner to HIGH",
				DurationSeconds: 20,
				Timers:          []BreakdownTimer{},
				Dependencies:    []int{1},
				Tips:            []string{"Use the largest burner for faster boiling"},
			},
			{
				Index:           3,
				Text:            "Wait for water to reach a rolling boil (about 7 minutes)",
				DurationSeconds: 420,
				Timers: []BreakdownTimer{
					{Name: "Water boiling", DurationSeconds: 420},
				},
				Dependencies: []int{2},
				Tips:         []string{"You'll see large bubbles breaking the surface", "This is a good time to prepare sauce"},
			},
			{
				Index:           4,
				Text:            "Add 1 tablespoon of salt to the boiling water",
				DurationSeconds: 10,
				Timers:          []BreakdownTimer{},
				Dependencies:    []int{3},
				Tips:            []string{"Salt enhances pasta flavor"},
			},
		}

	case 3: // Standard
		return []BreakdownStep{
			{
				Index:           0,
				Text:            "Fill large pot with water and bring to a boil",
				DurationSeconds: 480,
				Timers: []BreakdownTimer{
					{Name: "Water boiling", DurationSeconds: 480},
				},
				Dependencies: []int{},
				Tips:         []string{"Use about 6 quarts of water for 1 pound of pasta"},
			},
			{
				Index:           1,
				Text:            "Add salt and pasta to boiling water",
				DurationSeconds: 30,
				Timers:          []BreakdownTimer{},
				Dependencies:    []int{0},
				Tips:            []string{"Stir immediately to prevent sticking"},
			},
			{
				Index:           2,
				Text:            "Cook pasta according to package directions (usually 8-12 minutes)",
				DurationSeconds: 600,
				Timers: []BreakdownTimer{
					{Name: "Pasta cooking", DurationSeconds: 600},
				},
				Dependencies: []int{1},
				Tips:         []string{"Test for doneness 2 minutes before package time", "Should be al dente"},
			},
			{
				Index:           3,
				Text:            "Drain pasta and serve",
				DurationSeconds: 60,
				Timers:          []BreakdownTimer{},
				Dependencies:    []int{2},
				Tips:            []string{"Reserve 1 cup of pasta water for sauce if needed"},
			},
		}

	case 4: // Concise
		return []BreakdownStep{
			{
				Index:           0,
				Text:            "Boil salted water",
				DurationSeconds: 480,
				Timers: []BreakdownTimer{
					{Name: "Water", DurationSeconds: 480},
				},
				Dependencies: []int{},
				Tips:         []string{},
			},
			{
				Index:           1,
				Text:            "Cook pasta 8-12 minutes",
				DurationSeconds: 600,
				Timers: []BreakdownTimer{
					{Name: "Pasta", DurationSeconds: 600},
				},
				Dependencies: []int{0},
				Tips:         []string{"Test for doneness"},
			},
			{
				Index:           2,
				Text:            "Drain and serve",
				DurationSeconds: 60,
				Timers:          []BreakdownTimer{},
				Dependencies:    []int{1},
				Tips:            []string{},
			},
		}

	case 5: // Minimal
		return []BreakdownStep{
			{
				Index:           0,
				Text:            "Boil water, cook pasta 10 minutes, drain",
				DurationSeconds: 1200,
				Timers: []BreakdownTimer{
					{Name: "Total", DurationSeconds: 1200},
				},
				Dependencies: []int{},
				Tips:         []string{},
			},
		}

	default:
		return generateMockSteps(3, energyLevel) // Default to standard
	}
}

// OpenAIService implements AIService using OpenAI's API
// This is a placeholder for actual OpenAI integration
type OpenAIService struct {
	apiKey   string
	model    string
	provider string
}

// NewOpenAIService creates a new OpenAI service
func NewOpenAIService(apiKey string) AIService {
	return &OpenAIService{
		apiKey:   apiKey,
		model:    "gpt-4o",
		provider: "openai",
	}
}

func (o *OpenAIService) GenerateRecipeBreakdown(ctx context.Context, recipeID uuid.UUID, granularity int, energyLevel *int) (BreakdownData, error) {
	// TODO: Implement actual OpenAI API call
	// For now, return mock data
	mock := NewMockAIService()
	return mock.GenerateRecipeBreakdown(ctx, recipeID, granularity, energyLevel)
}

func (o *OpenAIService) GetProvider() string {
	return o.provider
}

func (o *OpenAIService) GetModel() string {
	return o.model
}

// buildAIPrompt constructs the prompt for AI breakdown generation
func buildAIPrompt(recipeName, recipeInstructions string, granularity int, energyLevel *int) string {
	var detailLevel string
	switch granularity {
	case 1:
		detailLevel = "EXTREMELY DETAILED - Break down every single micro-step. Assume the cook has ADHD and low executive function. Be explicit about every action, location, and timing. Include where to find items, how to hold them, and what success looks like at each step."
	case 2:
		detailLevel = "DETAILED - Provide more context and tips than a normal recipe. Include preparation reminders, timing notes, and helpful tips. Break complex steps into 2-3 smaller steps."
	case 3:
		detailLevel = "STANDARD - Normal recipe instruction level. Clear, step-by-step instructions with timing."
	case 4:
		detailLevel = "CONCISE - Assume experienced cook. Combine steps where logical. Focus on key timing and technique."
	case 5:
		detailLevel = "MINIMAL - Just the essential steps. Assume expert level. Focus only on critical steps and timing."
	}

	energyContext := ""
	if energyLevel != nil {
		energyContext = fmt.Sprintf("\n\nUser's current energy level: %d/5. ", *energyLevel)
		if *energyLevel <= 2 {
			energyContext += "Adapt for low energy - use simpler language, shorter steps, more encouragement."
		} else if *energyLevel >= 4 {
			energyContext += "User has high energy - can handle more complex instructions and parallel tasks."
		}
	}

	prompt := fmt.Sprintf(`You are a cooking assistant helping create step-by-step recipe instructions.

Detail Level: %s%s

Recipe: %s
Original Instructions: %s

Generate a detailed breakdown in the following JSON format:
{
  "steps": [
    {
      "index": 0,
      "text": "Step description (clear, actionable, specific)",
      "duration_seconds": 300,
      "timers": [
        {
          "name": "Timer name (e.g., 'Pasta boiling')",
          "duration_seconds": 300
        }
      ],
      "dependencies": [previous_step_indices],
      "tips": ["Helpful tip or note"],
      "image_url": null
    }
  ],
  "total_time_seconds": 1800,
  "active_time_seconds": 1200,
  "prep_steps": [0, 1, 2],
  "cooking_steps": [3, 4, 5]
}

Important:
- Each step should be actionable and clear
- duration_seconds should be realistic
- timers should be included for any waiting/cooking periods
- dependencies show which previous steps must be completed first
- tips should be genuinely helpful, not just restating the step
- prep_steps vs cooking_steps helps users understand the workflow`,
		detailLevel, energyContext, recipeName, recipeInstructions)

	return prompt
}

// parseAIResponse parses the AI JSON response into BreakdownData
func parseAIResponse(response string) (BreakdownData, error) {
	var breakdown BreakdownData
	err := json.Unmarshal([]byte(response), &breakdown)
	if err != nil {
		return BreakdownData{}, fmt.Errorf("failed to parse AI response: %w", err)
	}
	return breakdown, nil
}
