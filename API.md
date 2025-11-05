# Space Food API Documentation

**Version:** 1.0
**Base URL:** `http://localhost:8080/api/v1`
**Authentication:** Bearer JWT Token

---

## Table of Contents

1. [Authentication](#authentication)
2. [Recipes](#recipes)
3. [Meal Planning](#meal-planning)
4. [Pantry Management](#pantry-management)
5. [Shopping Lists](#shopping-lists)
6. [Nutrition Tracking](#nutrition-tracking)
7. [Households](#households)
8. [AI Features](#ai-features)
9. [Error Responses](#error-responses)

---

## Authentication

### Register User

**POST** `/auth/register`

Create a new user account.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "first_name": "John",
  "last_name": "Doe"
}
```

**Response:** `201 Created`
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "created_at": "2025-01-15T10:00:00Z"
  },
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "expires_in": 900
}
```

### Login

**POST** `/auth/login`

Authenticate and receive access tokens.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}
```

**Response:** `200 OK`
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe"
  },
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "expires_in": 900
}
```

### Refresh Token

**POST** `/auth/refresh`

Get a new access token using refresh token.

**Request Body:**
```json
{
  "refresh_token": "eyJhbGc..."
}
```

**Response:** `200 OK`
```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "expires_in": 900
}
```

---

## Recipes

All recipe endpoints require authentication via Bearer token.

### List Recipes

**GET** `/recipes`

Get all recipes for the authenticated user.

**Headers:**
```
Authorization: Bearer {access_token}
```

**Response:** `200 OK`
```json
[
  {
    "id": "uuid",
    "user_id": "uuid",
    "household_id": "uuid",
    "title": "Spaghetti Carbonara",
    "description": "Classic Italian pasta dish",
    "instructions": "1. Cook pasta...",
    "prep_time": 15,
    "cook_time": 20,
    "servings": 4,
    "difficulty": "medium",
    "image_url": "http://localhost:8080/uploads/abc123.jpg",
    "categories": ["Italian", "Pasta"],
    "tags": ["quick", "dinner"],
    "ingredients": [
      {
        "id": "uuid",
        "recipe_id": "uuid",
        "name": "Spaghetti",
        "quantity": 400,
        "unit": "g",
        "notes": "",
        "optional": false,
        "order": 1
      }
    ],
    "nutrition_info": {
      "calories": 520,
      "protein": 18,
      "carbohydrates": 65,
      "fat": 20,
      "fiber": 3,
      "sugar": 2,
      "sodium": 450
    },
    "source": "Family Recipe",
    "source_url": "",
    "rating": 4.5,
    "created_at": "2025-01-15T10:00:00Z",
    "updated_at": "2025-01-15T10:00:00Z"
  }
]
```

### Get Recipe by ID

**GET** `/recipes/{id}`

Get a specific recipe.

**Response:** `200 OK` (same structure as recipe object above)

### Create Recipe

**POST** `/recipes`

Create a new recipe.

**Request Body:**
```json
{
  "title": "Spaghetti Carbonara",
  "description": "Classic Italian pasta dish",
  "instructions": "1. Cook pasta according to package directions...",
  "prep_time": 15,
  "cook_time": 20,
  "servings": 4,
  "difficulty": "medium",
  "categories": ["Italian", "Pasta"],
  "tags": ["quick", "dinner"],
  "ingredients": [
    {
      "name": "Spaghetti",
      "quantity": 400,
      "unit": "g",
      "optional": false,
      "order": 1
    }
  ],
  "nutrition_info": {
    "calories": 520,
    "protein": 18,
    "carbohydrates": 65,
    "fat": 20
  }
}
```

**Response:** `201 Created` (recipe object)

### Update Recipe

**PUT** `/recipes/{id}`

Update an existing recipe.

**Request Body:** Same as Create Recipe

**Response:** `200 OK` (updated recipe object)

### Delete Recipe

**DELETE** `/recipes/{id}`

Delete a recipe.

**Response:** `204 No Content`

### Search Recipes

**GET** `/recipes/search?q={query}`

Search recipes by title, description, or ingredients.

**Query Parameters:**
- `q` (required): Search query string

**Response:** `200 OK` (array of recipe objects)

### Import Recipe from URL

**POST** `/recipes/import`

Import a recipe from a URL using web scraping.

**Request Body:**
```json
{
  "url": "https://example.com/recipes/carbonara"
}
```

**Response:** `200 OK` (imported recipe object)

**Notes:**
- Supports schema.org JSON-LD structured data
- Falls back to common HTML patterns
- Automatically extracts ingredients, instructions, and nutrition info

### Upload Recipe Image

**POST** `/recipes/{id}/image`

Upload an image for a recipe.

**Content-Type:** `multipart/form-data`

**Form Data:**
- `image`: Image file (jpg, jpeg, png, gif, webp, max 10MB)

**Response:** `200 OK`
```json
{
  "image_url": "http://localhost:8080/uploads/abc123.jpg"
}
```

---

## Meal Planning

### List Meal Plans

**GET** `/meal-plans`

Get meal plans for the authenticated user.

**Response:** `200 OK`
```json
[
  {
    "id": "uuid",
    "user_id": "uuid",
    "household_id": "uuid",
    "title": "Week of Jan 15-21",
    "description": "Family meal plan",
    "start_date": "2025-01-15T00:00:00Z",
    "end_date": "2025-01-21T23:59:59Z",
    "meals": [
      {
        "id": "uuid",
        "meal_plan_id": "uuid",
        "recipe_id": "uuid",
        "date": "2025-01-15T18:00:00Z",
        "meal_type": "dinner",
        "servings": 4,
        "notes": "Family dinner"
      }
    ],
    "created_at": "2025-01-15T10:00:00Z",
    "updated_at": "2025-01-15T10:00:00Z"
  }
]
```

### Get Meal Plan by ID

**GET** `/meal-plans/{id}`

Get a specific meal plan.

**Response:** `200 OK` (meal plan object)

### Create Meal Plan

**POST** `/meal-plans`

Create a new meal plan.

**Request Body:**
```json
{
  "title": "Week of Jan 15-21",
  "description": "Family meal plan",
  "start_date": "2025-01-15T00:00:00Z",
  "end_date": "2025-01-21T23:59:59Z",
  "meals": [
    {
      "recipe_id": "uuid",
      "date": "2025-01-15T18:00:00Z",
      "meal_type": "dinner",
      "servings": 4,
      "notes": "Family dinner"
    }
  ]
}
```

**Meal Types:** `breakfast`, `lunch`, `dinner`, `snack`

**Response:** `201 Created` (meal plan object)

### Update Meal Plan

**PUT** `/meal-plans/{id}`

Update an existing meal plan.

**Response:** `200 OK` (updated meal plan object)

### Delete Meal Plan

**DELETE** `/meal-plans/{id}`

Delete a meal plan.

**Response:** `204 No Content`

---

## Pantry Management

### List Pantry Items

**GET** `/pantry`

Get all pantry items for the authenticated user.

**Response:** `200 OK`
```json
[
  {
    "id": "uuid",
    "user_id": "uuid",
    "household_id": "uuid",
    "name": "Spaghetti",
    "quantity": 2,
    "unit": "packages",
    "category": "Pasta",
    "location": "Kitchen Cabinet",
    "purchase_date": "2025-01-10T00:00:00Z",
    "expiry_date": "2026-01-10T00:00:00Z",
    "notes": "Whole wheat",
    "barcode": "1234567890123",
    "created_at": "2025-01-15T10:00:00Z",
    "updated_at": "2025-01-15T10:00:00Z"
  }
]
```

### Get Pantry Item by ID

**GET** `/pantry/{id}`

Get a specific pantry item.

**Response:** `200 OK` (pantry item object)

### Create Pantry Item

**POST** `/pantry`

Add an item to the pantry.

**Request Body:**
```json
{
  "name": "Spaghetti",
  "quantity": 2,
  "unit": "packages",
  "category": "Pasta",
  "location": "Kitchen Cabinet",
  "expiry_date": "2026-01-10T00:00:00Z",
  "notes": "Whole wheat"
}
```

**Response:** `201 Created` (pantry item object)

### Update Pantry Item

**PUT** `/pantry/{id}`

Update a pantry item.

**Response:** `200 OK` (updated pantry item object)

### Delete Pantry Item

**DELETE** `/pantry/{id}`

Remove an item from the pantry.

**Response:** `204 No Content`

---

## Shopping Lists

### List Shopping List Items

**GET** `/shopping-list`

Get all shopping list items.

**Response:** `200 OK`
```json
[
  {
    "id": "uuid",
    "user_id": "uuid",
    "household_id": "uuid",
    "name": "Milk",
    "quantity": 2,
    "unit": "liters",
    "category": "Dairy",
    "notes": "Whole milk",
    "completed": false,
    "recipe_id": "uuid",
    "created_at": "2025-01-15T10:00:00Z",
    "updated_at": "2025-01-15T10:00:00Z"
  }
]
```

### Create Shopping List Item

**POST** `/shopping-list`

Add an item to the shopping list.

**Request Body:**
```json
{
  "name": "Milk",
  "quantity": 2,
  "unit": "liters",
  "category": "Dairy",
  "notes": "Whole milk",
  "recipe_id": "uuid"
}
```

**Response:** `201 Created` (shopping list item object)

### Toggle Item Completion

**PATCH** `/shopping-list/{id}/toggle`

Toggle the completed status of a shopping list item.

**Response:** `200 OK` (updated shopping list item object)

### Update Shopping List Item

**PUT** `/shopping-list/{id}`

Update a shopping list item.

**Response:** `200 OK` (updated shopping list item object)

### Delete Shopping List Item

**DELETE** `/shopping-list/{id}`

Remove an item from the shopping list.

**Response:** `204 No Content`

---

## Nutrition Tracking

### List Nutrition Logs

**GET** `/nutrition/logs`

Get nutrition logs for the last 30 days.

**Response:** `200 OK`
```json
[
  {
    "id": "uuid",
    "user_id": "uuid",
    "date": "2025-01-15T12:30:00Z",
    "meal_type": "lunch",
    "recipe_id": "uuid",
    "food_name": "Spaghetti Carbonara",
    "servings": 1.5,
    "nutrition_info": {
      "calories": 780,
      "protein": 27,
      "carbohydrates": 97.5,
      "fat": 30,
      "fiber": 4.5,
      "sugar": 3,
      "sodium": 675
    },
    "notes": "Had extra portion",
    "created_at": "2025-01-15T12:30:00Z"
  }
]
```

### Get Today's Nutrition Log

**GET** `/nutrition/logs/today`

Get nutrition logs for today.

**Response:** `200 OK` (array of nutrition log objects)

### Create Nutrition Log

**POST** `/nutrition/logs`

Log a meal or food item.

**Request Body:**
```json
{
  "date": "2025-01-15T12:30:00Z",
  "meal_type": "lunch",
  "recipe_id": "uuid",
  "food_name": "Spaghetti Carbonara",
  "servings": 1.5,
  "nutrition_info": {
    "calories": 520,
    "protein": 18,
    "carbohydrates": 65,
    "fat": 20
  },
  "notes": "Had extra portion"
}
```

**Response:** `201 Created` (nutrition log object)

### Get Nutrition Summary

**GET** `/nutrition/summary`

Get aggregated nutrition data for the last 7 days.

**Response:** `200 OK`
```json
{
  "summary": {
    "2025-01-15": {
      "calories": 2100,
      "protein": 85,
      "carbohydrates": 250,
      "fat": 70,
      "fiber": 30,
      "sugar": 45,
      "sodium": 2200
    },
    "2025-01-14": {
      "calories": 1950,
      "protein": 78,
      "carbohydrates": 230,
      "fat": 65,
      "fiber": 28,
      "sugar": 40,
      "sodium": 2100
    }
  }
}
```

### Search USDA Foods

**GET** `/nutrition/foods/search?query={query}&pageSize={size}`

Search the USDA FoodData Central database.

**Query Parameters:**
- `query` (required): Search term
- `pageSize` (optional): Number of results (default: 10, max: 50)

**Response:** `200 OK`
```json
[
  {
    "fdc_id": 123456,
    "description": "Spaghetti, cooked",
    "brand_owner": "",
    "data_type": "SR Legacy"
  }
]
```

**Note:** Requires `SPACE_FOOD_NUTRITION_USDAAPIKEY` environment variable to be set.

### Get USDA Food Detail

**GET** `/nutrition/foods/{fdcId}`

Get detailed nutrition information for a specific food.

**Response:** `200 OK`
```json
{
  "fdc_id": 123456,
  "description": "Spaghetti, cooked",
  "nutrients": [
    {
      "nutrient_id": 208,
      "nutrient_name": "Energy",
      "value": 158,
      "unit": "kcal"
    }
  ],
  "nutrition_info": {
    "calories": 158,
    "protein": 5.8,
    "carbohydrates": 30.9,
    "fat": 0.9,
    "fiber": 1.8,
    "sugar": 0.6,
    "sodium": 1
  }
}
```

---

## Households

### List User Households

**GET** `/households`

Get all households the authenticated user is a member of.

**Response:** `200 OK`
```json
[
  {
    "id": "uuid",
    "name": "Smith Family",
    "description": "Our family meal planning",
    "owner_id": "uuid",
    "created_at": "2025-01-15T10:00:00Z",
    "updated_at": "2025-01-15T10:00:00Z"
  }
]
```

### Get Household by ID

**GET** `/households/{id}`

Get a specific household (must be a member).

**Response:** `200 OK` (household object)

### Create Household

**POST** `/households`

Create a new household.

**Request Body:**
```json
{
  "name": "Smith Family",
  "description": "Our family meal planning"
}
```

**Response:** `201 Created` (household object)

**Notes:**
- Creator is automatically added as owner
- Owner role has full control over household settings

### Update Household

**PUT** `/households/{id}`

Update household details (owner only).

**Request Body:**
```json
{
  "name": "Smith Family",
  "description": "Updated description"
}
```

**Response:** `200 OK` (updated household object)

### Delete Household

**DELETE** `/households/{id}`

Delete a household (owner only).

**Response:** `204 No Content`

### List Household Members

**GET** `/households/{id}/members`

Get all members of a household.

**Response:** `200 OK`
```json
[
  {
    "household_id": "uuid",
    "user_id": "uuid",
    "role": "owner",
    "joined_at": "2025-01-15T10:00:00Z"
  },
  {
    "household_id": "uuid",
    "user_id": "uuid",
    "role": "member",
    "joined_at": "2025-01-16T14:30:00Z"
  }
]
```

**Roles:**
- `owner`: Full control, can delete household, add/remove members
- `admin`: Can add/remove members (except owner)
- `member`: Can view and contribute content

### Add Household Member

**POST** `/households/{id}/members`

Add a member to the household (owner/admin only).

**Request Body:**
```json
{
  "user_id": "uuid",
  "role": "member"
}
```

**Response:** `201 Created` (household member object)

**Notes:**
- Only owners can add admins
- Admins can add members

### Remove Household Member

**DELETE** `/households/{id}/members/{userID}`

Remove a member from the household.

**Response:** `204 No Content`

**Notes:**
- Owners and admins can remove members
- Users can remove themselves
- Owner cannot be removed

---

## AI Features

All AI endpoints require AI provider to be configured. Returns `404` if AI is not available.

### Suggest Recipe

**POST** `/ai/recipes/suggest`

Get AI-generated recipe suggestions.

**Request Body:**
```json
{
  "ingredients": ["chicken", "tomatoes", "basil"],
  "dietary_restrictions": ["gluten-free"],
  "cuisine": "Italian",
  "meal_type": "dinner",
  "servings": 4,
  "max_prep_time": 30
}
```

**Response:** `200 OK`
```json
{
  "recipe": {
    "title": "Italian Chicken with Tomatoes and Basil",
    "description": "A quick and flavorful gluten-free dinner",
    "ingredients": [
      "2 chicken breasts",
      "4 tomatoes, diced",
      "Fresh basil leaves"
    ],
    "instructions": "1. Season chicken...",
    "prep_time": 15,
    "cook_time": 20,
    "servings": 4,
    "cuisine": "Italian"
  }
}
```

### Generate Recipe Variation

**POST** `/ai/recipes/variation`

Generate variations of an existing recipe.

**Request Body:**
```json
{
  "recipe_id": "uuid",
  "variation_type": "vegetarian",
  "notes": "Replace chicken with tofu"
}
```

**Variation Types:** `vegetarian`, `vegan`, `low-carb`, `high-protein`, `budget-friendly`

**Response:** `200 OK` (recipe suggestion object)

### Analyze Nutrition

**POST** `/ai/recipes/analyze-nutrition`

Get AI-powered nutrition analysis and recommendations.

**Request Body:**
```json
{
  "recipe_id": "uuid"
}
```

**Response:** `200 OK`
```json
{
  "analysis": "This recipe is high in protein and moderate in carbohydrates...",
  "recommendations": [
    "Consider reducing sodium by 25%",
    "Add leafy greens for more fiber"
  ],
  "health_score": 7.5
}
```

### Suggest Ingredient Substitutions

**POST** `/ai/recipes/substitutions`

Get ingredient substitution suggestions.

**Request Body:**
```json
{
  "ingredient": "butter",
  "reason": "dairy-free",
  "recipe_context": "baking cookies"
}
```

**Response:** `200 OK`
```json
{
  "substitutions": [
    {
      "ingredient": "coconut oil",
      "ratio": "1:1",
      "notes": "Use solid coconut oil for best results"
    },
    {
      "ingredient": "vegan butter",
      "ratio": "1:1",
      "notes": "Most similar texture to dairy butter"
    }
  ]
}
```

### Generate AI Meal Plan

**POST** `/ai/meal-planning/generate`

Generate a meal plan using AI.

**Request Body:**
```json
{
  "start_date": "2025-01-15",
  "end_date": "2025-01-21",
  "people_count": 4,
  "dietary_restrictions": ["vegetarian"],
  "cuisine_preferences": ["Italian", "Mexican"],
  "budget_per_day": 50,
  "meal_types": ["breakfast", "lunch", "dinner"]
}
```

**Response:** `200 OK`
```json
{
  "meal_plan": {
    "title": "Vegetarian Week - Jan 15-21",
    "description": "AI-generated meal plan for 4 people",
    "meals": [
      {
        "date": "2025-01-15T07:00:00Z",
        "meal_type": "breakfast",
        "recipe_suggestion": {
          "title": "Veggie Breakfast Burrito",
          "ingredients": ["eggs", "bell peppers", "cheese"],
          "prep_time": 15
        }
      }
    ],
    "shopping_list": [
      {
        "name": "Eggs",
        "quantity": 24,
        "unit": "pieces",
        "category": "Dairy"
      }
    ],
    "estimated_cost": 280
  }
}
```

---

## Error Responses

All endpoints use consistent error response format:

### 400 Bad Request
```json
{
  "error": "Validation failed: email is required"
}
```

### 401 Unauthorized
```json
{
  "error": "unauthorized"
}
```

### 403 Forbidden
```json
{
  "error": "forbidden: you don't have permission to access this resource"
}
```

### 404 Not Found
```json
{
  "error": "recipe not found"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error"
}
```

---

## Rate Limiting

Currently, no rate limiting is implemented. Consider adding rate limiting in production deployments.

## CORS

CORS is enabled by default for all origins in development mode. Configure `SPACE_FOOD_SERVER_TRUSTEDPROXY` for production.

## Health Check

**GET** `/health`

Check API and database health.

**Response:** `200 OK`
```json
{
  "status": "healthy"
}
```

**Response:** `503 Service Unavailable` (if database is down)
```json
{
  "status": "unhealthy",
  "error": "database connection failed"
}
```
