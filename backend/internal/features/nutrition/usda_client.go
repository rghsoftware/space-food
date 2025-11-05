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

package nutrition

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"time"

	"github.com/rghsoftware/space-food/internal/database"
)

const (
	usdaBaseURL = "https://api.nal.usda.gov/fdc/v1"
)

// USDAClient handles USDA FoodData Central API requests
type USDAClient struct {
	apiKey string
	client *http.Client
}

// NewUSDAClient creates a new USDA API client
func NewUSDAClient(apiKey string) *USDAClient {
	return &USDAClient{
		apiKey: apiKey,
		client: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

// FoodSearchResult represents a food search result
type FoodSearchResult struct {
	FDCID       int     `json:"fdcId"`
	Description string  `json:"description"`
	DataType    string  `json:"dataType"`
	BrandOwner  string  `json:"brandOwner,omitempty"`
	BrandName   string  `json:"brandName,omitempty"`
	Score       float64 `json:"score"`
}

// FoodDetail represents detailed food information
type FoodDetail struct {
	FDCID              int                `json:"fdcId"`
	Description        string             `json:"description"`
	DataType           string             `json:"dataType"`
	FoodNutrients      []FoodNutrient     `json:"foodNutrients"`
	ServingSize        float64            `json:"servingSize,omitempty"`
	ServingSizeUnit    string             `json:"servingSizeUnit,omitempty"`
	HouseholdServingFullText string       `json:"householdServingFullText,omitempty"`
}

// FoodNutrient represents a nutrient in a food
type FoodNutrient struct {
	Nutrient Nutrient `json:"nutrient"`
	Amount   float64  `json:"amount"`
}

// Nutrient represents nutrient information
type Nutrient struct {
	ID       int    `json:"id"`
	Number   string `json:"number"`
	Name     string `json:"name"`
	UnitName string `json:"unitName"`
}

// SearchFoods searches for foods in the USDA database
func (c *USDAClient) SearchFoods(ctx context.Context, query string, pageSize int) ([]FoodSearchResult, error) {
	if c.apiKey == "" {
		return nil, fmt.Errorf("USDA API key not configured")
	}

	params := url.Values{}
	params.Set("api_key", c.apiKey)
	params.Set("query", query)
	params.Set("pageSize", fmt.Sprintf("%d", pageSize))
	params.Set("dataType", "Foundation,SR Legacy,Branded") // Include multiple data types

	reqURL := fmt.Sprintf("%s/foods/search?%s", usdaBaseURL, params.Encode())

	req, err := http.NewRequestWithContext(ctx, "GET", reqURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := c.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to execute request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("USDA API returned status %d", resp.StatusCode)
	}

	var result struct {
		Foods []FoodSearchResult `json:"foods"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return result.Foods, nil
}

// GetFoodDetail retrieves detailed information about a food
func (c *USDAClient) GetFoodDetail(ctx context.Context, fdcID int) (*FoodDetail, error) {
	if c.apiKey == "" {
		return nil, fmt.Errorf("USDA API key not configured")
	}

	reqURL := fmt.Sprintf("%s/food/%d?api_key=%s", usdaBaseURL, fdcID, c.apiKey)

	req, err := http.NewRequestWithContext(ctx, "GET", reqURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := c.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to execute request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("USDA API returned status %d", resp.StatusCode)
	}

	var detail FoodDetail
	if err := json.NewDecoder(resp.Body).Decode(&detail); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &detail, nil
}

// ExtractNutritionInfo extracts NutritionInfo from USDA food detail
func (c *USDAClient) ExtractNutritionInfo(detail *FoodDetail) database.NutritionInfo {
	info := database.NutritionInfo{}

	// Map of nutrient IDs to nutrition info fields
	for _, fn := range detail.FoodNutrients {
		switch fn.Nutrient.Number {
		case "208": // Energy (kcal)
			info.Calories = fn.Amount
		case "203": // Protein
			info.Protein = fn.Amount
		case "205": // Carbohydrates
			info.Carbohydrates = fn.Amount
		case "204": // Total lipid (fat)
			info.Fat = fn.Amount
		case "291": // Fiber, total dietary
			info.Fiber = fn.Amount
		case "269": // Sugars, total
			info.Sugar = fn.Amount
		case "307": // Sodium
			info.Sodium = fn.Amount / 1000 // Convert mg to g
		}
	}

	return info
}

// SearchAndGetNutrition searches for a food and returns its nutrition information
func (c *USDAClient) SearchAndGetNutrition(ctx context.Context, query string) (*database.NutritionInfo, string, error) {
	// Search for foods
	foods, err := c.SearchFoods(ctx, query, 1)
	if err != nil {
		return nil, "", err
	}

	if len(foods) == 0 {
		return nil, "", fmt.Errorf("no foods found for query: %s", query)
	}

	// Get detailed information for the first result
	detail, err := c.GetFoodDetail(ctx, foods[0].FDCID)
	if err != nil {
		return nil, "", err
	}

	// Extract nutrition info
	nutrition := c.ExtractNutritionInfo(detail)

	return &nutrition, detail.Description, nil
}
