# Food Variety & Rotation System

**Priority 4 Feature** - Non-judgmental food variety tracking with gentle expansion suggestions for users with ADHD.

## Overview

The Food Variety & Rotation System helps users gently expand their food repertoire while respecting hyperfixations and sensory preferences. This feature is specifically designed with ADHD in mind, using compassionate language and non-judgmental tracking.

### Core Philosophy

> **"Good enough nutrition consistently beats perfect sporadically"**

This feature:
- **Never judges** food choices or eating patterns
- **Respects hyperfixations** as valid coping mechanisms
- **Suggests gently** without pressure or shame
- **Celebrates variety** when it happens naturally
- **Makes nutrition opt-in** to avoid triggering disordered eating

## Key Features

### 1. Non-Judgmental Hyperfixation Tracking
- Automatically detects food patterns (5+ times in 7 days)
- Tracks without requiring manual logging
- Uses neutral language ("favorite foods" not "problem foods")
- Provides gentle context when suggesting alternatives

### 2. Food Chaining
AI-powered suggestions for similar foods that share key characteristics:
- **Texture matching**: crispy → chicken tenders, fish sticks
- **Flavor similarity**: savory → crackers with cheese
- **Temperature preferences**: hot → warm variations
- **Complexity levels**: simple → similarly simple preparations

Each suggestion includes:
- Similarity score (0.0-1.0)
- Detailed reasoning explaining WHY it's similar
- User feedback tracking (tried/liked)

### 3. Variation Ideas
Simple modifications to familiar foods:
- **Sauces**: honey mustard, BBQ, ranch
- **Toppings**: cheese, herbs, spices
- **Preparations**: grilled vs baked, cold vs hot
- **Side dishes**: complementary pairings

Complexity rating (1-5) helps users choose based on available energy.

### 4. Variety Analysis
Non-prescriptive metrics:
- Unique foods in last 7 days
- Unique foods in last 30 days
- Top foods with percentages
- Active hyperfixations (neutral presentation)
- **Variety Score (1-10)**: Informational only, never judgmental

### 5. Compassionate Nutrition Tracking
Completely opt-in system with granular controls:
- Can hide calorie counts entirely
- Can show macros only (no calories)
- Can focus on specific nutrients of interest
- "Gentle" reminder style (never pushy)
- Weekly summaries celebrate achievements only

### 6. Rotation Schedules
Optional structured meal rotation:
- Create named schedules (e.g., "Lunch Rotation")
- Define rotation period (7, 14, 28 days)
- List of foods with portions and notes
- Enable/disable as needed

## Database Schema

### Core Tables

#### `food_hyperfixations`
Tracks food eating patterns without judgment.

```sql
CREATE TABLE food_hyperfixations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    food_name VARCHAR(200) NOT NULL,
    started_at TIMESTAMP NOT NULL DEFAULT NOW(),
    frequency_count INTEGER DEFAULT 1,
    peak_frequency_per_day DECIMAL(5,2),
    is_active BOOLEAN DEFAULT true,
    ended_at TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, food_name, is_active)
);
```

**Purpose**: Auto-detected when eating same food 5+ times in 7 days.

#### `food_profiles`
Stores food characteristics for chaining algorithm.

```sql
CREATE TABLE food_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    food_name VARCHAR(200) NOT NULL UNIQUE,
    texture VARCHAR(50), -- 'crunchy', 'soft', 'chewy', 'smooth', 'crispy'
    flavor_profile VARCHAR(50), -- 'sweet', 'salty', 'savory', 'umami', 'spicy'
    temperature VARCHAR(20), -- 'hot', 'cold', 'room_temp'
    complexity INTEGER CHECK (complexity >= 1 AND complexity <= 5),
    common_allergens TEXT[],
    dietary_tags TEXT[], -- 'vegetarian', 'vegan', 'gluten_free', etc.
    preparation_time_minutes INTEGER,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

**Sample Data**: Pre-populated with 15 common ADHD-safe foods (chicken nuggets, mac and cheese, pizza, etc.).

#### `food_chain_suggestions`
AI-generated suggestions for similar foods.

```sql
CREATE TABLE food_chain_suggestions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    current_food_name VARCHAR(200) NOT NULL,
    suggested_food_name VARCHAR(200) NOT NULL,
    similarity_score DECIMAL(3,2) CHECK (similarity_score >= 0 AND similarity_score <= 1),
    reasoning TEXT NOT NULL,
    was_tried BOOLEAN DEFAULT false,
    was_liked BOOLEAN,
    tried_at TIMESTAMP,
    feedback TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

**Similarity Scoring**:
- 0.95-1.0: Nearly identical (popcorn chicken → chicken nuggets)
- 0.85-0.94: Very similar (grilled cheese → mac and cheese)
- 0.70-0.84: Similar characteristics (mozzarella sticks → chicken nuggets)
- 0.60-0.69: Some similarities (rice → buttered noodles)

#### `food_variations`
Simple modifications to familiar foods.

```sql
CREATE TABLE food_variations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    base_food_name VARCHAR(200) NOT NULL,
    variation_type VARCHAR(50) NOT NULL, -- 'sauce', 'topping', 'preparation', 'side'
    variation_name VARCHAR(200) NOT NULL,
    description TEXT,
    complexity INTEGER CHECK (complexity >= 1 AND complexity <= 5),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

**Sample Variations**: 14 pre-populated variations for common foods.

#### `nutrition_tracking_settings`
User preferences for optional nutrition tracking.

```sql
CREATE TABLE nutrition_tracking_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    tracking_enabled BOOLEAN DEFAULT false, -- Opt-in by default
    show_calorie_counts BOOLEAN DEFAULT false,
    show_macros BOOLEAN DEFAULT false,
    show_micronutrients BOOLEAN DEFAULT false,
    focus_nutrients TEXT[], -- e.g., ['iron', 'vitamin_d', 'protein']
    show_weekly_summary BOOLEAN DEFAULT true,
    show_daily_summary BOOLEAN DEFAULT false,
    reminder_style VARCHAR(20) DEFAULT 'gentle', -- 'gentle', 'none'
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

**Default**: All tracking disabled. User must explicitly opt-in.

#### `nutrition_insights`
Weekly positive-only nutrition insights.

```sql
CREATE TABLE nutrition_insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    week_start_date DATE NOT NULL,
    insight_type VARCHAR(50) NOT NULL, -- 'variety_celebration', 'nutrient_highlight'
    message TEXT NOT NULL,
    is_dismissed BOOLEAN DEFAULT false,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

**Example Messages**:
- "You tried 8 different foods this week! That's great variety! 🎉"
- "You have some favorite foods you're eating often right now. That's totally okay!"

#### `food_rotation_schedules`
Optional meal rotation structures.

```sql
CREATE TABLE food_rotation_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    schedule_name VARCHAR(200) NOT NULL,
    rotation_days INTEGER NOT NULL, -- 7, 14, 28, etc.
    foods JSONB NOT NULL, -- Array of {food_name, portion_size, notes}
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

**Foods JSONB Format**:
```json
[
  {
    "food_name": "Chicken nuggets with fries",
    "portion_size": "8 nuggets, small fries",
    "notes": "Monday lunch rotation"
  },
  {
    "food_name": "Mac and cheese",
    "portion_size": "1 bowl",
    "notes": "Tuesday lunch rotation"
  }
]
```

#### `last_eaten_tracking`
Frequency tracking for automatic hyperfixation detection.

```sql
CREATE TABLE last_eaten_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    food_name VARCHAR(200) NOT NULL,
    last_eaten TIMESTAMP NOT NULL,
    count_last_7_days INTEGER DEFAULT 1,
    count_last_30_days INTEGER DEFAULT 1,
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, food_name)
);
```

**Purpose**: Powers automatic hyperfixation detection and variety analysis.

## API Endpoints

All endpoints are under `/api/v1/food-variety` and require authentication.

### Hyperfixation Tracking

#### `GET /food-variety/hyperfixations`
Get user's active hyperfixations.

**Response**:
```json
{
  "hyperfixations": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "food_name": "Chicken nuggets",
      "started_at": "2025-01-15T10:30:00Z",
      "frequency_count": 8,
      "peak_frequency_per_day": 2.5,
      "is_active": true,
      "notes": ""
    }
  ]
}
```

#### `POST /food-variety/hyperfixations`
Manually record a hyperfixation.

**Request**:
```json
{
  "food_name": "Pizza",
  "notes": "Comfort food this week"
}
```

### Food Chaining

#### `POST /food-variety/chain-suggestions/generate`
Generate AI-powered food chain suggestions.

**Request**:
```json
{
  "food_name": "Chicken nuggets",
  "count": 5
}
```

**Response**:
```json
{
  "suggestions": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "current_food_name": "Chicken nuggets",
      "suggested_food_name": "Popcorn chicken",
      "similarity_score": 0.95,
      "reasoning": "Nearly identical - same crispy chicken in smaller pieces. Same flavor and texture.",
      "was_tried": false,
      "was_liked": null,
      "created_at": "2025-01-20T14:00:00Z"
    },
    {
      "id": "uuid",
      "suggested_food_name": "Chicken tenders",
      "similarity_score": 0.85,
      "reasoning": "Similar crispy texture and savory flavor. Both are finger foods with a crunchy coating."
    }
  ]
}
```

**How It Works**:
1. Checks if suggestions already exist (avoid regenerating)
2. Gets food profile if available
3. Calls AI chain service (mock or real)
4. Saves suggestions to database
5. Returns suggestions

#### `GET /food-variety/chain-suggestions`
Get user's past chain suggestions.

**Query Parameters**:
- `limit` (int, default 20): Number of suggestions
- `offset` (int, default 0): Pagination offset

#### `PUT /food-variety/chain-suggestions/:suggestion_id/feedback`
Record feedback after trying a suggestion.

**Request**:
```json
{
  "was_liked": true,
  "feedback": "Really enjoyed this! Very similar texture."
}
```

### Variation Ideas

#### `GET /food-variety/variations/:food_name`
Get simple variation ideas for a food.

**Example**: `GET /food-variety/variations/Chicken%20nuggets`

**Response**:
```json
{
  "variations": [
    {
      "id": "uuid",
      "base_food_name": "Chicken nuggets",
      "variation_type": "sauce",
      "variation_name": "Honey mustard",
      "description": "Sweet and tangy dipping sauce",
      "complexity": 1,
      "created_at": "2025-01-01T00:00:00Z"
    },
    {
      "variation_type": "sauce",
      "variation_name": "BBQ sauce",
      "description": "Sweet and smoky dipping sauce",
      "complexity": 1
    }
  ]
}
```

### Variety Analysis

#### `GET /food-variety/analysis`
Get comprehensive variety metrics.

**Response**:
```json
{
  "unique_foods_last_7_days": 8,
  "unique_foods_last_30_days": 15,
  "top_foods": [
    {
      "food_name": "Chicken nuggets",
      "count": 12,
      "percentage": 24.5,
      "last_eaten": "2025-01-20T12:00:00Z"
    },
    {
      "food_name": "Mac and cheese",
      "count": 10,
      "percentage": 20.4
    }
  ],
  "active_hyperfixations": [...],
  "suggested_rotations": [
    "You're doing great with food variety! Keep enjoying what works for you."
  ],
  "variety_score": 7
}
```

**Variety Score Algorithm**:
```go
score := unique7 // Base score from weekly variety (1-10+)

// Bonus for monthly variety
if unique30 > 20 {
    score += 2
} else if unique30 > 15 {
    score += 1
}

// Small reduction for hyperfixations (not punitive)
score -= (hyperfixationCount / 2)

// Clamp to 1-10
if score < 1 { score = 1 }
if score > 10 { score = 10 }
```

**Rotation Suggestions**:
- High variety (top food <30%): "You're doing great with food variety!"
- Single food dominance (>40%): "Try alternating X with a similar food"
- Active hyperfixations: "That's totally okay! When you're ready, try a small variation."

### Nutrition Settings

#### `GET /food-variety/nutrition/settings`
Get user's nutrition tracking preferences.

**Response**:
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "tracking_enabled": false,
  "show_calorie_counts": false,
  "show_macros": false,
  "show_micronutrients": false,
  "focus_nutrients": [],
  "show_weekly_summary": true,
  "show_daily_summary": false,
  "reminder_style": "gentle",
  "created_at": "2025-01-15T10:00:00Z",
  "updated_at": "2025-01-15T10:00:00Z"
}
```

#### `PUT /food-variety/nutrition/settings`
Update nutrition tracking preferences.

**Request** (all fields optional):
```json
{
  "tracking_enabled": true,
  "show_calorie_counts": false,
  "show_macros": true,
  "show_micronutrients": false,
  "focus_nutrients": ["protein", "iron", "vitamin_d"],
  "show_weekly_summary": true,
  "show_daily_summary": false,
  "reminder_style": "gentle"
}
```

**Philosophy**: Users can enable tracking selectively. For example:
- Show macros but NOT calories
- Focus only on iron and vitamin D
- Weekly summaries only (no daily pressure)

### Nutrition Insights

#### `GET /food-variety/nutrition/insights`
Get current week's nutrition insights.

**Response**:
```json
{
  "insights": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "week_start_date": "2025-01-13",
      "insight_type": "variety_celebration",
      "message": "You tried 8 different foods this week! That's great variety! 🎉",
      "is_dismissed": false,
      "created_at": "2025-01-20T08:00:00Z"
    }
  ]
}
```

**Insight Types**:
- `variety_celebration`: Celebrates dietary variety
- `nutrient_highlight`: Positive nutrient achievements (never deficiencies)

#### `POST /food-variety/nutrition/insights/generate`
Manually generate insights for current week.

**Response**: Same as GET, with newly generated insights.

#### `PUT /food-variety/nutrition/insights/:insight_id/dismiss`
Dismiss an insight.

**Response**:
```json
{
  "success": true
}
```

### Rotation Schedules

#### `POST /food-variety/rotation-schedules`
Create a new rotation schedule.

**Request**:
```json
{
  "schedule_name": "Weekday Lunch Rotation",
  "rotation_days": 7,
  "foods": [
    {
      "food_name": "Chicken nuggets with fries",
      "portion_size": "8 nuggets, small fries",
      "notes": "Monday"
    },
    {
      "food_name": "Mac and cheese",
      "portion_size": "1 bowl",
      "notes": "Tuesday"
    },
    {
      "food_name": "Pizza (cheese)",
      "portion_size": "2 slices",
      "notes": "Wednesday"
    }
  ]
}
```

**Response**:
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "schedule_name": "Weekday Lunch Rotation",
  "rotation_days": 7,
  "foods": [...],
  "is_active": true,
  "created_at": "2025-01-20T10:00:00Z",
  "updated_at": "2025-01-20T10:00:00Z"
}
```

#### `GET /food-variety/rotation-schedules`
Get all user's rotation schedules.

#### `PUT /food-variety/rotation-schedules/:schedule_id`
Update a rotation schedule.

**Request** (all fields optional):
```json
{
  "schedule_name": "Updated Lunch Rotation",
  "rotation_days": 14,
  "foods": [...],
  "is_active": false
}
```

#### `DELETE /food-variety/rotation-schedules/:schedule_id`
Delete a rotation schedule.

## AI Integration

### Mock AI Service (Current)

The system currently uses `MockAIChainService` which provides intelligent rule-based suggestions:

**Texture-based matching**:
- Crispy → chicken tenders, fish sticks
- Soft → mashed potatoes, yogurt
- Chewy → soft pretzel, bagel

**Specific food mappings**:
- Chicken nuggets → popcorn chicken (0.95), mozzarella sticks (0.75)
- Mac and cheese → cheese quesadilla (0.80), grilled cheese (0.85)
- Pizza → flatbread (0.90), bagel bites (0.85)
- French fries → tater tots (0.95), hash browns (0.85)

**Fallback suggestions**:
- Plain rice (0.60)
- Buttered noodles (0.65)

### Real AI Service (Placeholder)

The `RealAIChainService` is a placeholder for future AI provider integration (GPT-4, Claude, etc.).

**Prompt Template**:
```
You are a food variety assistant helping people with ADHD expand their diet gently.

Current food: Chicken nuggets
Profile:
  Texture: crispy
  Flavor: savory
  Temperature: hot
  Complexity: 2/5

Generate 5 food suggestions using food chaining principles.

Guidelines:
- Suggest foods with high similarity
- Explain WHY the food is similar (specific characteristics)
- Consider sensory sensitivities
- Never suggest allergens
- Respect dietary preferences
- Start with minimal changes
- Be encouraging but never judgmental

Return JSON format: {"suggestions": [...]}
```

**To Enable Real AI**:
```go
// In router.go, replace:
mockChainAIService := food_variety.NewMockAIChainService()

// With:
realAIService := food_variety.NewRealAIChainService(cfg.OpenAI.APIKey)
```

Then implement actual API calls in `ai_chain_service.go`.

## Integration with Meal Logging

The Food Variety system automatically tracks meals when users log them:

```go
// In meal logging handler
func (h *Handler) LogMeal(c *gin.Context) {
    // ... log meal to database ...

    // Track for food variety analysis
    userID := auth.GetUserID(c)
    foodName := meal.MainFood // or extract from meal description

    if err := foodVarietyService.TrackFoodConsumption(c.Request.Context(), userID, foodName); err != nil {
        log.Warn().Err(err).Msg("Failed to track food consumption for variety analysis")
        // Don't fail the meal logging if this fails
    }

    // ... continue with meal logging ...
}
```

**Automatic Detection**:
- Eating same food 5+ times in 7 days → hyperfixation created
- Counters updated in `last_eaten_tracking`
- Powers variety analysis and top foods

## Usage Examples

### Example 1: User with Chicken Nugget Hyperfixation

**Scenario**: User has been eating chicken nuggets daily for a week.

1. **Automatic Detection**:
   - System detects 7 instances in 7 days
   - Creates `food_hyperfixations` entry
   - `is_active = true`

2. **User Requests Suggestions**:
   ```bash
   POST /food-variety/chain-suggestions/generate
   {
     "food_name": "Chicken nuggets",
     "count": 5
   }
   ```

3. **System Responds**:
   - Popcorn chicken (0.95 similarity)
   - Chicken tenders (0.85)
   - Fish sticks (0.80)
   - Mozzarella sticks (0.75)

4. **User Tries Popcorn Chicken**:
   ```bash
   PUT /food-variety/chain-suggestions/:id/feedback
   {
     "was_liked": true,
     "feedback": "Loved it! Same texture!"
   }
   ```

5. **Variety Analysis Shows**:
   - Unique foods: 8 (nuggets + 7 variations tried)
   - Variety score: 6/10
   - Suggestion: "You're building variety! Try a small variation when ready."

### Example 2: User Wanting Rotation Structure

**Scenario**: User prefers routine and wants a lunch rotation.

1. **Create Schedule**:
   ```bash
   POST /food-variety/rotation-schedules
   {
     "schedule_name": "Work Lunch Week",
     "rotation_days": 7,
     "foods": [
       {"food_name": "Chicken nuggets", "notes": "Monday"},
       {"food_name": "Mac and cheese", "notes": "Tuesday"},
       {"food_name": "Pizza", "notes": "Wednesday"},
       {"food_name": "Grilled cheese", "notes": "Thursday"},
       {"food_name": "Chicken nuggets", "notes": "Friday"}
     ]
   }
   ```

2. **System Tracks**:
   - 4 unique foods in rotation
   - Chicken nuggets 2x per week
   - Variety score: 5-6/10
   - No hyperfixation (not meeting 5+ threshold with variety)

### Example 3: Opt-In Nutrition Tracking

**Scenario**: User wants to track protein but NOT calories.

1. **Update Settings**:
   ```bash
   PUT /food-variety/nutrition/settings
   {
     "tracking_enabled": true,
     "show_calorie_counts": false,
     "show_macros": true,
     "focus_nutrients": ["protein"]
   }
   ```

2. **Weekly Insight Generated**:
   - "You had protein in 12 meals this week!"
   - Never: "You didn't get enough protein" (no deficiency shaming)

## ADHD-Specific Design Principles

### 1. Recognition Over Recall
- Food profiles store characteristics (don't rely on memory)
- Past suggestions saved (don't need to remember what worked)
- Rotation schedules (structure without memorization)

### 2. Gentle Executive Function Support
- Automatic tracking (no manual logging burden)
- Low-complexity variations (complexity 1-2 for low energy days)
- Pre-populated sample data (ready to use immediately)

### 3. Non-Judgmental Language
**Never Use**:
- "Bad" foods
- "Unhealthy" eating
- "Fix" your diet
- "Problem" eating patterns
- Red warning colors

**Always Use**:
- "Favorite" foods
- "Current go-to" meals
- "Expand" or "explore" variety
- "Eating patterns"
- Informational metrics

### 4. Hyperfixation as Neutral Pattern
- Acknowledged without pathologizing
- "That's totally okay!" messaging
- Gentle suggestions without pressure
- Optional tracking (can be hidden)

### 5. Opt-In Philosophy
- Nutrition tracking OFF by default
- User must explicitly enable
- Granular control (can hide specific metrics)
- "Gentle" reminder style (never pushy)

### 6. Celebration Over Criticism
- Positive achievements highlighted
- Low variety = "You have your go-to foods and that's okay!"
- High variety = "Great variety this week! 🎉"
- No negative insights ever

### 7. Sensory Sensitivity Awareness
- Texture matching in food chaining
- Temperature preferences respected
- Complexity levels for preparation
- Allergen avoidance

## Testing the Feature

### Backend Testing

```bash
# Run the migration
psql -d space_food -f backend/internal/database/postgres/migrations/006_food_variety.sql

# Start the backend
cd backend
go run cmd/server/main.go

# Test hyperfixation tracking (simulated meal logging)
# Eat chicken nuggets 6 times to trigger detection
for i in {1..6}; do
  curl -X POST http://localhost:8080/api/v1/meal-reminders/logs \
    -H "Authorization: Bearer $TOKEN" \
    -d '{"meal_time": "lunch", "food_name": "Chicken nuggets"}'
done

# Check hyperfixations
curl http://localhost:8080/api/v1/food-variety/hyperfixations \
  -H "Authorization: Bearer $TOKEN"

# Generate chain suggestions
curl -X POST http://localhost:8080/api/v1/food-variety/chain-suggestions/generate \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"food_name": "Chicken nuggets", "count": 5}'

# Get variety analysis
curl http://localhost:8080/api/v1/food-variety/analysis \
  -H "Authorization: Bearer $TOKEN"

# Create rotation schedule
curl -X POST http://localhost:8080/api/v1/food-variety/rotation-schedules \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "schedule_name": "Test Rotation",
    "rotation_days": 7,
    "foods": [
      {"food_name": "Chicken nuggets", "portion_size": "8 pieces"},
      {"food_name": "Mac and cheese", "portion_size": "1 bowl"}
    ]
  }'
```

### Flutter Testing (Once Implemented)

```dart
// Test variety dashboard
await tester.pumpWidget(VarietyDashboardScreen());
expect(find.text('Variety Score'), findsOneWidget);
expect(find.byType(VarietyScoreChart), findsOneWidget);

// Test food chaining
await tester.tap(find.text('Get Suggestions'));
await tester.pumpAndSettle();
expect(find.byType(ChainSuggestionCard), findsWidgets);

// Test nutrition settings
await tester.tap(find.text('Nutrition Settings'));
await tester.pump();
expect(find.switchWidget('tracking_enabled'), findsOneWidget);
```

## Future Enhancements

### Phase 2: Real AI Integration
- Integrate with OpenAI GPT-4 or Anthropic Claude
- More sophisticated food chaining
- Personalized learning from user feedback
- Cross-cultural food suggestions

### Phase 3: Community Features
- Share rotation schedules (anonymously)
- "Other people who like X also like Y"
- Success stories (opt-in sharing)

### Phase 4: Advanced Nutrition
- Integration with nutrition APIs (USDA, Nutritionix)
- Micronutrient tracking (iron, vitamin D, B12)
- Supplement reminders (gentle, opt-in)

### Phase 5: Visual Recognition
- Take photo of food → auto-identification
- Visual similarity matching
- Texture recognition from images

## License

Space Food - Self-Hosted Meal Planning Application
Copyright (C) 2025 RGH Software
Licensed under AGPL-3.0

## Support

For ADHD-specific design questions or feature requests, please open an issue on GitHub with the `adhd-friendly` label.
