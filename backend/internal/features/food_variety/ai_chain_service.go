// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

package food_variety

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
)

// AIChainService defines the interface for AI-powered food chaining
type AIChainService interface {
	GenerateChainSuggestions(ctx context.Context, currentFood string, profile *FoodProfile, count int) ([]FoodChainSuggestion, error)
	GenerateVariationIdeas(ctx context.Context, baseFood string) ([]FoodVariation, error)
}

// MockAIChainService provides a mock implementation for testing/development
type MockAIChainService struct{}

// NewMockAIChainService creates a new mock AI chain service
func NewMockAIChainService() AIChainService {
	return &MockAIChainService{}
}

func (s *MockAIChainService) GenerateChainSuggestions(ctx context.Context, currentFood string, profile *FoodProfile, count int) ([]FoodChainSuggestion, error) {
	// Generate mock suggestions based on food characteristics
	suggestions := s.generateMockSuggestions(currentFood, profile)

	if len(suggestions) > count {
		suggestions = suggestions[:count]
	}

	return suggestions, nil
}

func (s *MockAIChainService) GenerateVariationIdeas(ctx context.Context, baseFood string) ([]FoodVariation, error) {
	// Generate mock variations
	variations := s.generateMockVariations(baseFood)
	return variations, nil
}

func (s *MockAIChainService) generateMockSuggestions(currentFood string, profile *FoodProfile) []FoodChainSuggestion {
	foodLower := strings.ToLower(currentFood)
	suggestions := []FoodChainSuggestion{}

	// Food chaining logic based on characteristics
	if profile != nil {
		switch profile.Texture {
		case "crispy":
			suggestions = append(suggestions,
				FoodChainSuggestion{
					SuggestedFoodName: "Chicken tenders",
					SimilarityScore:   0.85,
					Reasoning:         "Similar crispy texture and savory flavor. Both are finger foods with a crunchy coating.",
				},
				FoodChainSuggestion{
					SuggestedFoodName: "Fish sticks",
					SimilarityScore:   0.80,
					Reasoning:         "Same crispy breaded coating, similar shape and eating style. Mild flavor like chicken nuggets.",
				},
			)
		case "soft":
			suggestions = append(suggestions,
				FoodChainSuggestion{
					SuggestedFoodName: "Mashed potatoes",
					SimilarityScore:   0.90,
					Reasoning:         "Similar smooth, soft texture. Comfort food with mild, savory flavor.",
				},
			)
		case "chewy":
			suggestions = append(suggestions,
				FoodChainSuggestion{
					SuggestedFoodName: "Soft pretzel",
					SimilarityScore:   0.75,
					Reasoning:         "Similar chewy texture and can be eaten with hands. Mild flavor that accepts toppings well.",
				},
			)
		}

		// Flavor-based suggestions
		if profile.FlavorProfile == "savory" {
			suggestions = append(suggestions,
				FoodChainSuggestion{
					SuggestedFoodName: "Crackers with cheese",
					SimilarityScore:   0.70,
					Reasoning:         "Simple savory flavor, similar temperature. Easy to prepare, familiar taste.",
				},
			)
		}
	}

	// Specific food-based suggestions
	if strings.Contains(foodLower, "chicken nugget") {
		suggestions = append(suggestions,
			FoodChainSuggestion{
				SuggestedFoodName: "Popcorn chicken",
				SimilarityScore:   0.95,
				Reasoning:         "Nearly identical - same crispy chicken in smaller pieces. Same flavor and texture.",
			},
			FoodChainSuggestion{
				SuggestedFoodName: "Mozzarella sticks",
				SimilarityScore:   0.75,
				Reasoning:         "Similar crispy breaded coating, finger food format. Cheese inside instead of chicken.",
			},
		)
	} else if strings.Contains(foodLower, "mac") && strings.Contains(foodLower, "cheese") {
		suggestions = append(suggestions,
			FoodChainSuggestion{
				SuggestedFoodName: "Cheese quesadilla",
				SimilarityScore:   0.80,
				Reasoning:         "Similar creamy cheese flavor, mild and comforting. Different texture but same cheese satisfaction.",
			},
			FoodChainSuggestion{
				SuggestedFoodName: "Grilled cheese sandwich",
				SimilarityScore:   0.85,
				Reasoning:         "Very similar cheese flavor, slightly different texture. Same comfort food appeal.",
			},
		)
	} else if strings.Contains(foodLower, "pizza") {
		suggestions = append(suggestions,
			FoodChainSuggestion{
				SuggestedFoodName: "Flatbread with cheese",
				SimilarityScore:   0.90,
				Reasoning:         "Very similar to pizza - bread, cheese, tomato sauce. Slightly thinner crust.",
			},
			FoodChainSuggestion{
				SuggestedFoodName: "Bagel bites",
				SimilarityScore:   0.85,
				Reasoning:         "Mini pizza on a bagel. Same toppings and flavors in bite-sized format.",
			},
		)
	} else if strings.Contains(foodLower, "fries") || strings.Contains(foodLower, "french fries") {
		suggestions = append(suggestions,
			FoodChainSuggestion{
				SuggestedFoodName: "Tater tots",
				SimilarityScore:   0.95,
				Reasoning:         "Same potato base, very similar crispy exterior. Bite-sized instead of strips.",
			},
			FoodChainSuggestion{
				SuggestedFoodName: "Hash browns",
				SimilarityScore:   0.85,
				Reasoning:         "Crispy potato with similar flavor. Different shape but same satisfying crunch.",
			},
		)
	} else if strings.Contains(foodLower, "pasta") {
		suggestions = append(suggestions,
			FoodChainSuggestion{
				SuggestedFoodName: "Ravioli",
				SimilarityScore:   0.85,
				Reasoning:         "Same pasta base with filling inside. Similar texture, familiar Italian flavor.",
			},
		)
	}

	// If no specific matches, provide generic safe suggestions
	if len(suggestions) == 0 {
		suggestions = append(suggestions,
			FoodChainSuggestion{
				SuggestedFoodName: "Plain rice",
				SimilarityScore:   0.60,
				Reasoning:         "Simple, mild flavor that works as a safe base. Easy to prepare and very familiar.",
			},
			FoodChainSuggestion{
				SuggestedFoodName: "Buttered noodles",
				SimilarityScore:   0.65,
				Reasoning:         "Comfort food with simple, familiar taste. Soft texture, minimal ingredients.",
			},
		)
	}

	return suggestions
}

func (s *MockAIChainService) generateMockVariations(baseFood string) []FoodVariation {
	foodLower := strings.ToLower(baseFood)
	variations := []FoodVariation{}

	// Generate variations based on food type
	if strings.Contains(foodLower, "chicken") {
		variations = append(variations,
			FoodVariation{
				BaseFoodName:  baseFood,
				VariationType: "sauce",
				VariationName: "Honey mustard",
				Description:   "Sweet and tangy dipping sauce",
				Complexity:    1,
			},
			FoodVariation{
				BaseFoodName:  baseFood,
				VariationType: "sauce",
				VariationName: "BBQ sauce",
				Description:   "Sweet and smoky dipping sauce",
				Complexity:    1,
			},
		)
	}

	if strings.Contains(foodLower, "pasta") || strings.Contains(foodLower, "noodle") {
		variations = append(variations,
			FoodVariation{
				BaseFoodName:  baseFood,
				VariationType: "topping",
				VariationName: "Parmesan cheese",
				Description:   "Grate fresh parmesan on top",
				Complexity:    1,
			},
			FoodVariation{
				BaseFoodName:  baseFood,
				VariationType: "preparation",
				VariationName: "Add garlic butter",
				Description:   "Melt butter with garlic powder",
				Complexity:    2,
			},
		)
	}

	// Generic variations that work for most foods
	variations = append(variations,
		FoodVariation{
			BaseFoodName:  baseFood,
			VariationType: "side",
			VariationName: "Apple slices",
			Description:   "Fresh apple slices on the side for contrast",
			Complexity:    1,
		},
	)

	return variations
}

// RealAIChainService would integrate with actual AI providers
// This is a placeholder for future implementation
type RealAIChainService struct {
	apiKey string
	model  string
}

func NewRealAIChainService(apiKey string) AIChainService {
	return &RealAIChainService{
		apiKey: apiKey,
		model:  "gpt-4o",
	}
}

func (s *RealAIChainService) GenerateChainSuggestions(ctx context.Context, currentFood string, profile *FoodProfile, count int) ([]FoodChainSuggestion, error) {
	// TODO: Implement actual AI API call
	prompt := s.buildChainPrompt(currentFood, profile, count)
	_ = prompt // Use in actual implementation

	// For now, fall back to mock
	mock := NewMockAIChainService()
	return mock.GenerateChainSuggestions(ctx, currentFood, profile, count)
}

func (s *RealAIChainService) GenerateVariationIdeas(ctx context.Context, baseFood string) ([]FoodVariation, error) {
	// TODO: Implement actual AI API call
	prompt := s.buildVariationPrompt(baseFood)
	_ = prompt // Use in actual implementation

	// For now, fall back to mock
	mock := NewMockAIChainService()
	return mock.GenerateVariationIdeas(ctx, baseFood)
}

func (s *RealAIChainService) buildChainPrompt(currentFood string, profile *FoodProfile, count int) string {
	profileStr := "No profile available"
	if profile != nil {
		profileStr = fmt.Sprintf(`
Texture: %s
Flavor: %s
Temperature: %s
Complexity: %d/5
Dietary tags: %v`,
			profile.Texture,
			profile.FlavorProfile,
			profile.Temperature,
			profile.Complexity,
			profile.DietaryTags,
		)
	}

	return fmt.Sprintf(`You are a food variety assistant helping people with ADHD expand their diet gently.

Current food: %s
Profile: %s

Generate %d food suggestions that are similar to this food using food chaining principles.
Share key characteristics (texture, flavor, temperature, appearance) with the current food.

Important guidelines:
- Suggest foods with high similarity (shared texture, flavor profile, or preparation)
- Explain WHY the food is similar (be specific about shared characteristics)
- Consider sensory sensitivities common in ADHD
- Never suggest foods with allergens unless the current food also has them
- Respect dietary preferences (vegetarian, vegan, gluten-free)
- Start with minimal changes (same food, different sauce > completely different food)
- Be encouraging but never judgmental

Return JSON format:
{
  "suggestions": [
    {
      "food_name": "string",
      "similarity_score": 0.0-1.0,
      "reasoning": "Explain why this is similar (be specific about shared texture, flavor, etc.)"
    }
  ]
}`,
		currentFood,
		profileStr,
		count,
	)
}

func (s *RealAIChainService) buildVariationPrompt(baseFood string) string {
	return fmt.Sprintf(`Generate variation ideas for: %s

Suggest simple ways to change this food while keeping it familiar:
- Different sauces or condiments
- Simple toppings
- Alternative preparations (grilled vs baked, cold vs hot)
- Easy side dishes that pair well

Focus on minimal-effort changes. Return as JSON:
{
  "variations": [
    {
      "type": "sauce|topping|preparation|side",
      "name": "specific variation",
      "description": "brief description",
      "complexity": 1-5
    }
  ]
}`, baseFood)
}

// Helper to parse AI JSON response
func parseAIResponse(response string, v interface{}) error {
	return json.Unmarshal([]byte(response), v)
}
