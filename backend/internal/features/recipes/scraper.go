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
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/PuerkitoBio/goquery"
	"github.com/rghsoftware/space-food/internal/database"
)

// Scraper handles recipe URL scraping
type Scraper struct {
	client *http.Client
}

// NewScraper creates a new recipe scraper
func NewScraper() *Scraper {
	return &Scraper{
		client: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// ScrapeRecipe scrapes a recipe from a URL
func (s *Scraper) ScrapeRecipe(ctx context.Context, url string) (*database.Recipe, error) {
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("User-Agent", "Mozilla/5.0 (compatible; SpaceFoodBot/1.0)")

	resp, err := s.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch URL: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("received status code %d", resp.StatusCode)
	}

	doc, err := goquery.NewDocumentFromReader(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to parse HTML: %w", err)
	}

	// Try to extract recipe using various methods
	recipe := s.trySchemaOrg(doc)
	if recipe == nil {
		recipe = s.tryCommonPatterns(doc)
	}

	if recipe == nil {
		return nil, fmt.Errorf("could not extract recipe from URL")
	}

	recipe.SourceURL = url
	recipe.Source = s.extractDomain(url)

	return recipe, nil
}

// trySchemaOrg attempts to extract recipe from schema.org JSON-LD
func (s *Scraper) trySchemaOrg(doc *goquery.Document) *database.Recipe {
	var recipe *database.Recipe

	doc.Find("script[type='application/ld+json']").Each(func(i int, sel *goquery.Selection) {
		if recipe != nil {
			return
		}

		jsonStr := sel.Text()
		var data map[string]interface{}
		if err := json.Unmarshal([]byte(jsonStr), &data); err != nil {
			return
		}

		// Handle both single object and array of objects
		var recipeData map[string]interface{}
		if data["@type"] == "Recipe" {
			recipeData = data
		} else if graph, ok := data["@graph"].([]interface{}); ok {
			for _, item := range graph {
				if itemMap, ok := item.(map[string]interface{}); ok {
					if itemMap["@type"] == "Recipe" {
						recipeData = itemMap
						break
					}
				}
			}
		}

		if recipeData != nil {
			recipe = s.parseSchemaOrgRecipe(recipeData)
		}
	})

	return recipe
}

// parseSchemaOrgRecipe parses a schema.org recipe object
func (s *Scraper) parseSchemaOrgRecipe(data map[string]interface{}) *database.Recipe {
	recipe := &database.Recipe{}

	if name, ok := data["name"].(string); ok {
		recipe.Title = name
	}

	if desc, ok := data["description"].(string); ok {
		recipe.Description = desc
	}

	if img, ok := data["image"].(string); ok {
		recipe.ImageURL = img
	} else if imgArray, ok := data["image"].([]interface{}); ok && len(imgArray) > 0 {
		if imgStr, ok := imgArray[0].(string); ok {
			recipe.ImageURL = imgStr
		}
	}

	// Parse prep time (ISO 8601 duration)
	if prepTime, ok := data["prepTime"].(string); ok {
		recipe.PrepTime = s.parseDuration(prepTime)
	}

	// Parse cook time
	if cookTime, ok := data["cookTime"].(string); ok {
		recipe.CookTime = s.parseDuration(cookTime)
	}

	// Parse servings
	if yield, ok := data["recipeYield"].(string); ok {
		recipe.Servings = s.parseServings(yield)
	} else if yieldNum, ok := data["recipeYield"].(float64); ok {
		recipe.Servings = int(yieldNum)
	}

	// Parse ingredients
	if ingredients, ok := data["recipeIngredient"].([]interface{}); ok {
		for i, ing := range ingredients {
			if ingStr, ok := ing.(string); ok {
				recipe.Ingredients = append(recipe.Ingredients, database.Ingredient{
					Name:  ingStr,
					Order: i,
				})
			}
		}
	}

	// Parse instructions
	var instructions []string
	if instData, ok := data["recipeInstructions"].([]interface{}); ok {
		for _, inst := range instData {
			if instStr, ok := inst.(string); ok {
				instructions = append(instructions, instStr)
			} else if instMap, ok := inst.(map[string]interface{}); ok {
				if text, ok := instMap["text"].(string); ok {
					instructions = append(instructions, text)
				}
			}
		}
	} else if instStr, ok := data["recipeInstructions"].(string); ok {
		instructions = append(instructions, instStr)
	}
	recipe.Instructions = strings.Join(instructions, "\n\n")

	// Parse nutrition
	if nutrition, ok := data["nutrition"].(map[string]interface{}); ok {
		recipe.NutritionInfo = s.parseNutrition(nutrition)
	}

	return recipe
}

// tryCommonPatterns attempts to extract recipe using common HTML patterns
func (s *Scraper) tryCommonPatterns(doc *goquery.Document) *database.Recipe {
	recipe := &database.Recipe{}

	// Try common title selectors
	titleSelectors := []string{
		"h1.recipe-title",
		"h1.entry-title",
		".recipe-header h1",
		"h1[itemprop='name']",
		"h1",
	}

	for _, selector := range titleSelectors {
		if title := doc.Find(selector).First().Text(); title != "" {
			recipe.Title = strings.TrimSpace(title)
			break
		}
	}

	// Try common description selectors
	descSelectors := []string{
		".recipe-description",
		".recipe-summary",
		"[itemprop='description']",
		".entry-summary",
	}

	for _, selector := range descSelectors {
		if desc := doc.Find(selector).First().Text(); desc != "" {
			recipe.Description = strings.TrimSpace(desc)
			break
		}
	}

	// Try to find ingredients
	ingredientSelectors := []string{
		".recipe-ingredients li",
		".ingredients li",
		"[itemprop='recipeIngredient']",
		".ingredient",
	}

	for _, selector := range ingredientSelectors {
		doc.Find(selector).Each(func(i int, sel *goquery.Selection) {
			text := strings.TrimSpace(sel.Text())
			if text != "" {
				recipe.Ingredients = append(recipe.Ingredients, database.Ingredient{
					Name:  text,
					Order: i,
				})
			}
		})
		if len(recipe.Ingredients) > 0 {
			break
		}
	}

	// Try to find instructions
	instructionSelectors := []string{
		".recipe-instructions li",
		".instructions li",
		"[itemprop='recipeInstructions'] li",
		".recipe-steps li",
	}

	var instructions []string
	for _, selector := range instructionSelectors {
		doc.Find(selector).Each(func(i int, sel *goquery.Selection) {
			text := strings.TrimSpace(sel.Text())
			if text != "" {
				instructions = append(instructions, text)
			}
		})
		if len(instructions) > 0 {
			break
		}
	}
	recipe.Instructions = strings.Join(instructions, "\n\n")

	// Try to find image
	imgSelectors := []string{
		".recipe-image img",
		".recipe-photo img",
		"[itemprop='image']",
		".entry-content img",
	}

	for _, selector := range imgSelectors {
		if img, exists := doc.Find(selector).First().Attr("src"); exists {
			recipe.ImageURL = img
			break
		}
	}

	if recipe.Title == "" {
		return nil
	}

	return recipe
}

// parseDuration parses ISO 8601 duration (e.g., PT30M)
func (s *Scraper) parseDuration(duration string) int {
	duration = strings.ToUpper(duration)
	if !strings.HasPrefix(duration, "PT") {
		return 0
	}

	duration = strings.TrimPrefix(duration, "PT")
	minutes := 0

	// Parse hours
	if idx := strings.Index(duration, "H"); idx != -1 {
		if hours, err := strconv.Atoi(duration[:idx]); err == nil {
			minutes += hours * 60
		}
		duration = duration[idx+1:]
	}

	// Parse minutes
	if idx := strings.Index(duration, "M"); idx != -1 {
		if mins, err := strconv.Atoi(duration[:idx]); err == nil {
			minutes += mins
		}
	}

	return minutes
}

// parseServings extracts serving count from string
func (s *Scraper) parseServings(yield string) int {
	// Try to extract first number
	fields := strings.Fields(yield)
	for _, field := range fields {
		if num, err := strconv.Atoi(field); err == nil {
			return num
		}
	}
	return 0
}

// parseNutrition extracts nutrition info from schema.org nutrition object
func (s *Scraper) parseNutrition(nutrition map[string]interface{}) *database.NutritionInfo {
	info := &database.NutritionInfo{}

	if cal, ok := nutrition["calories"].(string); ok {
		info.Calories = s.parseNutrientValue(cal)
	}

	if protein, ok := nutrition["proteinContent"].(string); ok {
		info.Protein = s.parseNutrientValue(protein)
	}

	if carbs, ok := nutrition["carbohydrateContent"].(string); ok {
		info.Carbohydrates = s.parseNutrientValue(carbs)
	}

	if fat, ok := nutrition["fatContent"].(string); ok {
		info.Fat = s.parseNutrientValue(fat)
	}

	if fiber, ok := nutrition["fiberContent"].(string); ok {
		info.Fiber = s.parseNutrientValue(fiber)
	}

	if sugar, ok := nutrition["sugarContent"].(string); ok {
		info.Sugar = s.parseNutrientValue(sugar)
	}

	if sodium, ok := nutrition["sodiumContent"].(string); ok {
		info.Sodium = s.parseNutrientValue(sodium)
	}

	return info
}

// parseNutrientValue extracts numeric value from nutrient string
func (s *Scraper) parseNutrientValue(value string) float64 {
	// Remove common suffixes and parse
	value = strings.TrimSpace(value)
	value = strings.TrimSuffix(value, "g")
	value = strings.TrimSuffix(value, "mg")
	value = strings.TrimSpace(value)

	if num, err := strconv.ParseFloat(value, 64); err == nil {
		return num
	}

	return 0
}

// extractDomain extracts domain from URL
func (s *Scraper) extractDomain(url string) string {
	// Simple domain extraction
	if idx := strings.Index(url, "://"); idx != -1 {
		url = url[idx+3:]
	}
	if idx := strings.Index(url, "/"); idx != -1 {
		url = url[:idx]
	}
	// Remove www.
	url = strings.TrimPrefix(url, "www.")
	return url
}
