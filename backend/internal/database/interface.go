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

package database

import (
	"context"
	"time"
)

// Database defines the contract that all database implementations must fulfill
type Database interface {
	// Lifecycle
	Connect(ctx context.Context) error
	Close() error
	Health(ctx context.Context) error
	Migrate(ctx context.Context) error

	// Transaction management
	BeginTx(ctx context.Context) (Transaction, error)

	// User operations
	CreateUser(ctx context.Context, user *User) error
	GetUserByID(ctx context.Context, id string) (*User, error)
	GetUserByEmail(ctx context.Context, email string) (*User, error)
	UpdateUser(ctx context.Context, user *User) error
	DeleteUser(ctx context.Context, id string) error

	// Recipe operations
	CreateRecipe(ctx context.Context, recipe *Recipe) error
	GetRecipeByID(ctx context.Context, id string) (*Recipe, error)
	ListRecipes(ctx context.Context, filter RecipeFilter) ([]*Recipe, error)
	UpdateRecipe(ctx context.Context, recipe *Recipe) error
	DeleteRecipe(ctx context.Context, id string) error
	SearchRecipes(ctx context.Context, query string) ([]*Recipe, error)

	// Meal plan operations
	CreateMealPlan(ctx context.Context, plan *MealPlan) error
	GetMealPlanByID(ctx context.Context, id string) (*MealPlan, error)
	ListMealPlans(ctx context.Context, filter MealPlanFilter) ([]*MealPlan, error)
	UpdateMealPlan(ctx context.Context, plan *MealPlan) error
	DeleteMealPlan(ctx context.Context, id string) error

	// Pantry operations
	CreatePantryItem(ctx context.Context, item *PantryItem) error
	GetPantryItemByID(ctx context.Context, id string) (*PantryItem, error)
	ListPantryItems(ctx context.Context, filter PantryFilter) ([]*PantryItem, error)
	UpdatePantryItem(ctx context.Context, item *PantryItem) error
	DeletePantryItem(ctx context.Context, id string) error

	// Shopping list operations
	CreateShoppingListItem(ctx context.Context, item *ShoppingListItem) error
	GetShoppingListItemByID(ctx context.Context, id string) (*ShoppingListItem, error)
	ListShoppingListItems(ctx context.Context, filter ShoppingListFilter) ([]*ShoppingListItem, error)
	UpdateShoppingListItem(ctx context.Context, item *ShoppingListItem) error
	DeleteShoppingListItem(ctx context.Context, id string) error

	// Nutrition tracking operations
	CreateNutritionLog(ctx context.Context, log *NutritionLog) error
	GetNutritionLog(ctx context.Context, userID string, date time.Time) ([]*NutritionLog, error)
	ListNutritionLogs(ctx context.Context, filter NutritionFilter) ([]*NutritionLog, error)

	// Full-text search
	SearchFullText(ctx context.Context, query string, entityType string) ([]interface{}, error)
}

// Transaction represents a database transaction
type Transaction interface {
	Commit() error
	Rollback() error
	Database
}

// User represents a user in the system
type User struct {
	ID             string
	Email          string
	PasswordHash   string
	FirstName      string
	LastName       string
	CreatedAt      time.Time
	UpdatedAt      time.Time
	LastLoginAt    *time.Time
	EmailVerified  bool
	Active         bool
}

// Recipe represents a recipe
type Recipe struct {
	ID              string
	UserID          string
	Title           string
	Description     string
	Instructions    string
	PrepTime        int // minutes
	CookTime        int // minutes
	Servings        int
	Difficulty      string
	ImageURL        string
	Categories      []string
	Tags            []string
	Ingredients     []Ingredient
	NutritionInfo   *NutritionInfo
	Source          string
	SourceURL       string
	Rating          float64
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

// Ingredient represents a recipe ingredient
type Ingredient struct {
	ID           string
	RecipeID     string
	Name         string
	Quantity     float64
	Unit         string
	Notes        string
	Optional     bool
	Order        int
}

// NutritionInfo represents nutritional information
type NutritionInfo struct {
	Calories      float64
	Protein       float64
	Carbohydrates float64
	Fat           float64
	Fiber         float64
	Sugar         float64
	Sodium        float64
}

// MealPlan represents a meal plan
type MealPlan struct {
	ID          string
	UserID      string
	Title       string
	Description string
	StartDate   time.Time
	EndDate     time.Time
	Meals       []PlannedMeal
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

// PlannedMeal represents a meal in a meal plan
type PlannedMeal struct {
	ID         string
	MealPlanID string
	RecipeID   string
	Date       time.Time
	MealType   string // breakfast, lunch, dinner, snack
	Servings   int
	Notes      string
}

// PantryItem represents an item in the pantry
type PantryItem struct {
	ID             string
	UserID         string
	Name           string
	Quantity       float64
	Unit           string
	Category       string
	Location       string
	PurchaseDate   *time.Time
	ExpiryDate     *time.Time
	Notes          string
	Barcode        string
	CreatedAt      time.Time
	UpdatedAt      time.Time
}

// ShoppingListItem represents an item on a shopping list
type ShoppingListItem struct {
	ID        string
	UserID    string
	Name      string
	Quantity  float64
	Unit      string
	Category  string
	Notes     string
	Completed bool
	RecipeID  *string
	CreatedAt time.Time
	UpdatedAt time.Time
}

// NutritionLog represents a nutrition tracking entry
type NutritionLog struct {
	ID             string
	UserID         string
	Date           time.Time
	MealType       string
	RecipeID       *string
	FoodName       string
	Servings       float64
	NutritionInfo  NutritionInfo
	Notes          string
	CreatedAt      time.Time
}

// RecipeFilter for querying recipes
type RecipeFilter struct {
	UserID      string
	Categories  []string
	Tags        []string
	MinRating   *float64
	MaxPrepTime *int
	Limit       int
	Offset      int
}

// MealPlanFilter for querying meal plans
type MealPlanFilter struct {
	UserID    string
	StartDate time.Time
	EndDate   time.Time
	Limit     int
	Offset    int
}

// PantryFilter for querying pantry items
type PantryFilter struct {
	UserID       string
	Categories   []string
	ExpiryBefore *time.Time
	Limit        int
	Offset       int
}

// ShoppingListFilter for querying shopping list items
type ShoppingListFilter struct {
	UserID     string
	Completed  *bool
	Categories []string
	Limit      int
	Offset     int
}

// NutritionFilter for querying nutrition logs
type NutritionFilter struct {
	UserID    string
	StartDate time.Time
	EndDate   time.Time
	Limit     int
	Offset    int
}
