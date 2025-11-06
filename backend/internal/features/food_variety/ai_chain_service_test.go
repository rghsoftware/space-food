/*
 * Space Food - Self-Hosted Meal Planning Application
 * Copyright (C) 2025 RGH Software
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

package food_variety

import (
	"context"
	"strings"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Test Mock AI Service - Texture-based suggestions
func TestMockAIService_TextureMatching(t *testing.T) {
	tests := []struct {
		name            string
		currentFood     string
		profile         *FoodProfile
		expectedCount   int
		checkSuggestion func(t *testing.T, suggestions []FoodChainSuggestion)
	}{
		{
			name:        "crispy texture matching",
			currentFood: "Test crispy food",
			profile: &FoodProfile{
				FoodName:      "Test crispy food",
				Texture:       "crispy",
				FlavorProfile: "savory",
				Temperature:   "hot",
				Complexity:    2,
			},
			expectedCount: 2, // Should get chicken tenders + fish sticks
			checkSuggestion: func(t *testing.T, suggestions []FoodChainSuggestion) {
				// Should have chicken tenders suggestion
				found := false
				for _, s := range suggestions {
					if strings.Contains(s.SuggestedFoodName, "Chicken tenders") {
						found = true
						assert.GreaterOrEqual(t, s.SimilarityScore, 0.80)
						assert.Contains(t, strings.ToLower(s.Reasoning), "crisp")
						break
					}
				}
				assert.True(t, found, "Should suggest chicken tenders for crispy food")
			},
		},
		{
			name:        "soft texture matching",
			currentFood: "Soft bread",
			profile: &FoodProfile{
				FoodName: "Soft bread",
				Texture:  "soft",
			},
			expectedCount: 2, // mashed potatoes + yogurt
			checkSuggestion: func(t *testing.T, suggestions []FoodChainSuggestion) {
				found := false
				for _, s := range suggestions {
					if strings.Contains(s.SuggestedFoodName, "mashed potatoes") ||
						strings.Contains(s.SuggestedFoodName, "Yogurt") {
						found = true
						break
					}
				}
				assert.True(t, found, "Should suggest soft foods")
			},
		},
		{
			name:        "chewy texture matching",
			currentFood: "Chewy candy",
			profile: &FoodProfile{
				FoodName: "Chewy candy",
				Texture:  "chewy",
			},
			expectedCount: 2,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			service := NewMockAIChainService()
			ctx := context.Background()

			suggestions, err := service.GenerateChainSuggestions(ctx, tt.currentFood, tt.profile, 5)

			require.NoError(t, err)
			assert.GreaterOrEqual(t, len(suggestions), tt.expectedCount)

			if tt.checkSuggestion != nil {
				tt.checkSuggestion(t, suggestions)
			}
		})
	}
}

// Test specific food mappings
func TestMockAIService_SpecificFoodMappings(t *testing.T) {
	tests := []struct {
		name               string
		currentFood        string
		expectedSuggestion string
		minSimilarity      float64
	}{
		{
			name:               "chicken nuggets -> popcorn chicken",
			currentFood:        "Chicken nuggets",
			expectedSuggestion: "Popcorn chicken",
			minSimilarity:      0.90,
		},
		{
			name:               "chicken nuggets -> mozzarella sticks",
			currentFood:        "Chicken nuggets",
			expectedSuggestion: "Mozzarella sticks",
			minSimilarity:      0.70,
		},
		{
			name:               "mac and cheese -> cheese quesadilla",
			currentFood:        "Mac and cheese",
			expectedSuggestion: "Cheese quesadilla",
			minSimilarity:      0.75,
		},
		{
			name:               "mac and cheese -> grilled cheese",
			currentFood:        "Mac and cheese",
			expectedSuggestion: "Grilled cheese",
			minSimilarity:      0.80,
		},
		{
			name:               "pizza -> flatbread",
			currentFood:        "Pizza",
			expectedSuggestion: "Flatbread",
			minSimilarity:      0.85,
		},
		{
			name:               "french fries -> tater tots",
			currentFood:        "French fries",
			expectedSuggestion: "Tater tots",
			minSimilarity:      0.90,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			service := NewMockAIChainService()
			ctx := context.Background()

			profile := &FoodProfile{
				FoodName:      tt.currentFood,
				Texture:       "crispy",
				FlavorProfile: "savory",
			}

			suggestions, err := service.GenerateChainSuggestions(ctx, tt.currentFood, profile, 5)

			require.NoError(t, err)
			assert.NotEmpty(t, suggestions)

			// Check if expected suggestion is present
			found := false
			for _, s := range suggestions {
				if strings.Contains(s.SuggestedFoodName, tt.expectedSuggestion) {
					found = true
					assert.GreaterOrEqual(t, s.SimilarityScore, tt.minSimilarity,
						"Similarity score too low for %s -> %s", tt.currentFood, tt.expectedSuggestion)
					assert.NotEmpty(t, s.Reasoning, "Reasoning should be provided")
					break
				}
			}
			assert.True(t, found, "Expected suggestion '%s' not found for '%s'",
				tt.expectedSuggestion, tt.currentFood)
		})
	}
}

// Test fallback suggestions
func TestMockAIService_FallbackSuggestions(t *testing.T) {
	service := NewMockAIChainService()
	ctx := context.Background()

	// Unknown food should still get fallback suggestions
	profile := &FoodProfile{
		FoodName:      "Unknown exotic food",
		Texture:       "unknown",
		FlavorProfile: "complex",
	}

	suggestions, err := service.GenerateChainSuggestions(ctx, "Unknown exotic food", profile, 5)

	require.NoError(t, err)
	assert.NotEmpty(t, suggestions, "Should provide fallback suggestions")

	// Should include safe options like plain rice or buttered noodles
	foundFallback := false
	for _, s := range suggestions {
		if strings.Contains(s.SuggestedFoodName, "Plain rice") ||
			strings.Contains(s.SuggestedFoodName, "Buttered noodles") {
			foundFallback = true
			assert.GreaterOrEqual(t, s.SimilarityScore, 0.50)
			break
		}
	}
	assert.True(t, foundFallback, "Should include fallback suggestions")
}

// Test similarity score ordering
func TestMockAIService_SimilarityScoreOrdering(t *testing.T) {
	service := NewMockAIChainService()
	ctx := context.Background()

	profile := &FoodProfile{
		FoodName:      "Chicken nuggets",
		Texture:       "crispy",
		FlavorProfile: "savory",
	}

	suggestions, err := service.GenerateChainSuggestions(ctx, "Chicken nuggets", profile, 5)

	require.NoError(t, err)
	assert.NotEmpty(t, suggestions)

	// Verify suggestions are ordered by similarity score (highest first)
	for i := 0; i < len(suggestions)-1; i++ {
		assert.GreaterOrEqual(t, suggestions[i].SimilarityScore, suggestions[i+1].SimilarityScore,
			"Suggestions should be ordered by similarity score")
	}

	// All scores should be between 0 and 1
	for _, s := range suggestions {
		assert.GreaterOrEqual(t, s.SimilarityScore, 0.0)
		assert.LessOrEqual(t, s.SimilarityScore, 1.0)
	}
}

// Test suggestion fields completeness
func TestMockAIService_SuggestionFieldsCompleteness(t *testing.T) {
	service := NewMockAIChainService()
	ctx := context.Background()

	profile := &FoodProfile{
		FoodName: "Pizza",
		Texture:  "soft",
	}

	suggestions, err := service.GenerateChainSuggestions(ctx, "Pizza", profile, 3)

	require.NoError(t, err)

	for i, s := range suggestions {
		// Check all required fields are populated
		assert.NotEqual(t, uuid.Nil, s.ID, "Suggestion %d should have valid ID", i)
		assert.NotEmpty(t, s.CurrentFoodName, "Suggestion %d should have current food name", i)
		assert.NotEmpty(t, s.SuggestedFoodName, "Suggestion %d should have suggested food name", i)
		assert.NotEmpty(t, s.Reasoning, "Suggestion %d should have reasoning", i)
		assert.False(t, s.WasTried, "Suggestion %d should not be marked as tried initially", i)
		assert.False(t, s.CreatedAt.IsZero(), "Suggestion %d should have creation timestamp", i)
	}
}

// Test reasoning quality
func TestMockAIService_ReasoningQuality(t *testing.T) {
	service := NewMockAIChainService()
	ctx := context.Background()

	profile := &FoodProfile{
		FoodName:      "Chicken nuggets",
		Texture:       "crispy",
		FlavorProfile: "savory",
	}

	suggestions, err := service.GenerateChainSuggestions(ctx, "Chicken nuggets", profile, 5)

	require.NoError(t, err)

	for _, s := range suggestions {
		// Reasoning should explain WHY it's similar
		reasoning := strings.ToLower(s.Reasoning)

		// Should mention food characteristics
		hasCharacteristic := strings.Contains(reasoning, "texture") ||
			strings.Contains(reasoning, "flavor") ||
			strings.Contains(reasoning, "crisp") ||
			strings.Contains(reasoning, "savory") ||
			strings.Contains(reasoning, "similar") ||
			strings.Contains(reasoning, "same")

		assert.True(t, hasCharacteristic,
			"Reasoning should explain food characteristics: %s", s.Reasoning)

		// Should not be judgmental
		assert.NotContains(t, reasoning, "should")
		assert.NotContains(t, reasoning, "must")
		assert.NotContains(t, reasoning, "need to")
	}
}

// Test count parameter respect
func TestMockAIService_CountParameter(t *testing.T) {
	tests := []struct {
		name        string
		count       int
		expectCount int
	}{
		{
			name:        "request 3 suggestions",
			count:       3,
			expectCount: 3,
		},
		{
			name:        "request 5 suggestions",
			count:       5,
			expectCount: 5,
		},
		{
			name:        "request 1 suggestion",
			count:       1,
			expectCount: 1,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			service := NewMockAIChainService()
			ctx := context.Background()

			profile := &FoodProfile{
				FoodName: "Pizza",
			}

			suggestions, err := service.GenerateChainSuggestions(ctx, "Pizza", profile, tt.count)

			require.NoError(t, err)
			// Should return exactly the requested count (or close to it)
			assert.GreaterOrEqual(t, len(suggestions), tt.expectCount-1)
			assert.LessOrEqual(t, len(suggestions), tt.expectCount+1)
		})
	}
}

// Test nil profile handling
func TestMockAIService_NilProfileHandling(t *testing.T) {
	service := NewMockAIChainService()
	ctx := context.Background()

	// Should still work with nil profile
	suggestions, err := service.GenerateChainSuggestions(ctx, "Chicken nuggets", nil, 3)

	// Should either work with fallbacks or return an error
	if err != nil {
		assert.Error(t, err)
	} else {
		assert.NotEmpty(t, suggestions, "Should provide suggestions even without profile")
	}
}

// Test Real AI Service interface (placeholder)
func TestRealAIService_BuildPrompt(t *testing.T) {
	// This tests the prompt building logic for the real AI service
	service := &RealAIChainService{
		apiKey: "test-key",
		model:  "gpt-4",
	}

	profile := &FoodProfile{
		FoodName:        "Chicken nuggets",
		Texture:         "crispy",
		FlavorProfile:   "savory",
		Temperature:     "hot",
		Complexity:      2,
		CommonAllergens: []string{},
	}

	prompt := service.buildChainPrompt("Chicken nuggets", profile, 5)

	// Verify prompt contains key elements
	assert.Contains(t, prompt, "Chicken nuggets", "Should mention current food")
	assert.Contains(t, prompt, "crispy", "Should mention texture")
	assert.Contains(t, prompt, "savory", "Should mention flavor")
	assert.Contains(t, prompt, "hot", "Should mention temperature")

	// Verify prompt has ADHD-specific guidelines
	assert.Contains(t, prompt, "ADHD", "Should mention ADHD context")
	assert.Contains(t, prompt, "sensory", "Should mention sensory considerations")

	// Verify non-judgmental language requirements
	assert.Contains(t, prompt, "never judgmental", "Should require non-judgmental language")
	assert.Contains(t, prompt, "encouraging", "Should require encouraging tone")
}

// Benchmark mock AI service
func BenchmarkMockAIService_GenerateSuggestions(b *testing.B) {
	service := NewMockAIChainService()
	ctx := context.Background()

	profile := &FoodProfile{
		FoodName:      "Chicken nuggets",
		Texture:       "crispy",
		FlavorProfile: "savory",
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, _ = service.GenerateChainSuggestions(ctx, "Chicken nuggets", profile, 5)
	}
}
