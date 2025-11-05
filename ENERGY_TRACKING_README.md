# Energy-Aware Meal Management Implementation

## Overview

This document describes the implementation of the Energy-Aware Meal Management System for Space Food - a feature that helps ADHD users filter meals based on their current energy level and learn their energy patterns over time.

## Implementation Status

✅ **Backend (Go)**: Complete
✅ **Frontend (Flutter)**: Complete
⚠️ **Code Generation**: Required
⚠️ **Testing**: Pending

## Features Implemented

### Core Features
- ✅ Energy level recording (1-5 scale)
- ✅ Automatic pattern learning over time
- ✅ Energy-based meal filtering
- ✅ Favorite meals management
- ✅ Time-of-day associations
- ✅ Frequency tracking
- ✅ Energy-based recommendations
- ✅ Offline-first with Drift local database
- ✅ Automatic background sync
- ✅ Recipe energy level filtering

### ADHD-Friendly Design
- ✅ Respects cognitive capacity rather than forcing ideals
- ✅ No shame for low-energy choices
- ✅ Simple, visual energy level selector
- ✅ Pattern learning without user effort
- ✅ Smart recommendations based on time and energy
- ✅ Quick access to appropriate meals

## Architecture

### Backend (Go)

#### Files Created/Modified:

1. **Database Migration**
   - `backend/internal/database/postgres/migrations/003_energy_tracking.sql`
   - Tables: `user_energy_patterns`, `energy_snapshots`, `saved_favorite_meals`
   - Added energy columns to `recipes` table

2. **Models**
   - `backend/internal/features/energy_tracking/models.go`
   - Data structures for energy snapshots, patterns, favorite meals

3. **Repository**
   - `backend/internal/features/energy_tracking/repository.go`
   - CRUD operations for all tables
   - Pattern lookup and updates
   - Favorite meals filtering by energy/time

4. **Service**
   - `backend/internal/features/energy_tracking/service.go`
   - Pattern learning with weighted averages (recent data weighted higher)
   - Exponential decay (7-day half-life)
   - Energy-based recommendations
   - Reasoning generation

5. **HTTP Handler**
   - `backend/internal/features/energy_tracking/handler.go`
   - REST API endpoints

6. **Router Integration**
   - `backend/internal/api/rest/router.go` (modified)
   - Wired up energy tracking routes

#### API Endpoints:

```
Energy Recording & History:
POST   /api/v1/energy/record              - Record energy level
GET    /api/v1/energy/history              - Get energy snapshots (with days param)
GET    /api/v1/energy/patterns             - Get learned energy patterns
GET    /api/v1/energy/recommendations      - Get meal recommendations
GET    /api/v1/energy/recipes              - Get recipes filtered by energy

Favorite Meals:
POST   /api/v1/favorite-meals              - Save favorite meal
GET    /api/v1/favorite-meals              - List favorite meals (filterable)
GET    /api/v1/favorite-meals/:id          - Get specific meal
PUT    /api/v1/favorite-meals/:id          - Update favorite meal
POST   /api/v1/favorite-meals/:id/eaten    - Mark meal as eaten
DELETE /api/v1/favorite-meals/:id          - Delete favorite meal
```

### Frontend (Flutter)

#### Files Created:

##### Data Layer
1. **Models** (Freezed)
   - `app/lib/src/features/energy_tracking/data/models/energy_snapshot.dart`
   - `app/lib/src/features/energy_tracking/data/models/favorite_meal.dart`

2. **Local Database** (Drift)
   - `app/lib/src/features/energy_tracking/data/local/energy_tracking_database.dart`
   - Three tables with sync tracking
   - Offline-first storage

3. **API Client** (Retrofit)
   - `app/lib/src/features/energy_tracking/data/api/energy_tracking_api.dart`
   - REST API integration

4. **Repository**
   - `app/lib/src/features/energy_tracking/data/repositories/energy_tracking_repository.dart`
   - Offline-first implementation
   - Automatic pattern updates
   - Graceful fallback to local data

##### Presentation Layer
5. **Widgets**
   - `app/lib/src/features/energy_tracking/presentation/widgets/energy_filter_chip.dart`
     - Horizontal scrolling filter chips (1-5)
     - Quick energy recorder widget

6. **Screens**
   - `app/lib/src/features/energy_tracking/presentation/screens/energy_based_meals_screen.dart`
     - Main screen with energy filter
     - Meal recommendations
     - Quick energy recording
     - Energy level guide

   - `app/lib/src/features/energy_tracking/presentation/screens/favorite_meals_screen.dart`
     - Manage favorite meals
     - Add/edit/delete meals
     - Energy and time associations

7. **Providers** (Riverpod)
   - `app/lib/src/features/energy_tracking/presentation/providers/energy_tracking_providers.dart`
     - Infrastructure providers (database, API, repository)
     - State providers (energy history, patterns, recommendations, meals)
     - Action providers (recording, logging)
     - Helper providers (predicted energy, current time of day)

## Energy Level Scale

### 1 - Exhausted
- **Description**: Zero-prep meals only
- **Examples**: Cereal, yogurt, protein bar, fruit
- **Preparation**: None - grab and eat
- **Time**: < 1 minute

### 2 - Depleted / Low Energy
- **Description**: Minimal effort, very quick
- **Examples**: Toast, instant oatmeal, smoothie, microwave meal
- **Preparation**: Minimal - microwave or toaster
- **Time**: 2-5 minutes

### 3 - Moderate
- **Description**: Simple cooking
- **Examples**: Pasta, scrambled eggs, quesadilla, stir-fry
- **Preparation**: Basic cooking skills
- **Time**: 10-15 minutes

### 4 - Good Energy
- **Description**: Can follow recipes
- **Examples**: Most standard recipes, roasted vegetables, grilled chicken
- **Preparation**: Following recipe steps
- **Time**: 20-30 minutes

### 5 - Energized / High Energy
- **Description**: Complex meals, multiple steps
- **Examples**: Elaborate recipes, meal prep, baking from scratch
- **Preparation**: Complex cooking, multiple steps
- **Time**: 30+ minutes

## Pattern Learning Algorithm

The system automatically learns user energy patterns over time:

1. **Data Collection**: Energy snapshots are recorded with timestamp
2. **Time Categorization**: Snapshots are categorized by:
   - Time of day (morning, afternoon, evening, night)
   - Day of week (0=Sunday through 6=Saturday)
3. **Weighted Average**: Recent snapshots weighted higher
   - Weight = 1.0 / (1.0 + days_ago / 7.0)
   - 7-day exponential decay half-life
4. **Pattern Update**: Typical energy level updated automatically
5. **Prediction**: System can predict likely energy level for current time/day

## Usage

### Recording Energy Level

**Quick Recording:**
1. Tap the "Energy Check" floating button
2. Select your current energy level (1-5)
3. Done! Pattern learning happens automatically

**Recording with Context:**
- When logging a meal with the meal reminders feature
- Automatically records energy with context "meal_log"

### Filtering Meals by Energy

1. Open "What to Eat" screen
2. Use the energy filter chips at the top
3. Select your current energy level or "All"
4. See meals appropriate for your energy level
5. Meals filtered by energy and time of day

### Managing Favorite Meals

**Adding a Favorite Meal:**
1. Navigate to "Favorite Meals"
2. Tap "Add Meal" button
3. Enter:
   - Meal name (required)
   - Energy level required (1-5, optional)
   - Typical time of day (optional)
   - Notes (optional)
4. Save

**Editing/Deleting:**
- Tap the three-dot menu on any meal card
- Select "Edit" or "Delete"

**Marking as Eaten:**
- Tap the checkmark icon on any meal card
- Automatically increments frequency score
- Updates "last eaten" timestamp

### Getting Recommendations

The system provides smart recommendations based on:
1. Your current or predicted energy level
2. Current time of day
3. Your historical eating patterns
4. Frequency of eating each meal

**Automatic Prediction:**
- If you don't specify energy level
- System predicts based on your patterns for this time/day
- Falls back to moderate (3) if no pattern exists

## Build Instructions

### Prerequisites
- Go 1.22+
- PostgreSQL 14+
- Flutter 3.0+
- Android SDK (for Android) or Xcode (for iOS)

### Backend Setup

1. **Run database migrations:**
   ```bash
   cd backend
   # Migrations run automatically on startup
   # Ensure 003_energy_tracking.sql is in migrations folder
   ```

2. **Start the backend:**
   ```bash
   go run cmd/server/main.go
   ```

### Frontend Setup

1. **Install dependencies:**
   ```bash
   cd app
   flutter pub get
   ```

2. **Generate code (IMPORTANT - Required before running):**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

   This generates:
   - Freezed models (`.freezed.dart` and `.g.dart` files)
   - Drift database (`.g.dart` files)
   - Retrofit API clients (`.g.dart` files)
   - Riverpod providers (`.g.dart` files)

3. **Run the app:**
   ```bash
   flutter run
   ```

## Integration with Existing Features

### Meal Reminders
- When logging a meal via meal reminders, can also record energy
- Links energy snapshots with meal logs via context "meal_log"
- Helps learn energy patterns at meal times

### Recipes
- Recipes table now includes `energy_level`, `preparation_time_minutes`, `active_time_minutes`
- Can filter recipes by maximum energy level
- Recipe import can suggest energy level based on complexity

### Meal Planning
- Can use energy predictions to suggest appropriate meals for different times
- Considers typical energy levels when planning weekly meals

## Offline-First Implementation

### How It Works

1. **Write Operations:**
   - Energy recordings saved to local Drift database first
   - Favorite meals saved locally first
   - Then attempts to sync to server
   - If offline, queued for later sync
   - User sees immediate feedback

2. **Read Operations:**
   - Attempts to fetch from server first
   - Falls back to local database if offline
   - Always shows data, even offline
   - Recommendations work offline using local data

3. **Pattern Learning:**
   - Happens on server side when online
   - Local predictions use cached patterns
   - Updates automatically when back online

## Testing

### Backend Testing

```bash
cd backend
go test ./internal/features/energy_tracking/...
```

### Frontend Testing

```bash
cd app

# Unit tests
flutter test

# Widget tests
flutter test test/widgets/

# Integration tests
flutter test integration_test/
```

## Known Limitations

1. **Code Generation Required:**
   - Must run `flutter pub run build_runner build` before first run
   - Generated files are gitignored

2. **Pattern Learning:**
   - Requires at least a few data points to be accurate
   - Takes ~1 week to establish reliable patterns
   - Works better with consistent recording

3. **Energy Level Subjectivity:**
   - Energy levels are self-reported
   - May vary between users
   - System learns individual patterns over time

4. **Recipe Energy Assignment:**
   - Must be manually assigned or AI-assisted
   - Not all recipes have energy levels initially
   - Can be added gradually

## Future Enhancements

- [ ] AI-powered energy level auto-assignment for recipes
- [ ] Visual energy pattern dashboard
- [ ] Energy trend analysis
- [ ] Meal suggestions based on upcoming tasks/events
- [ ] Integration with wearables (sleep tracking, activity)
- [ ] Family sharing of favorite meals
- [ ] Voice-activated energy recording
- [ ] Smart notifications at low energy times
- [ ] Meal prep suggestions for energy-intensive days

## Troubleshooting

### Build Runner Fails
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Patterns Not Learning
1. Ensure you're recording energy regularly
2. Check that patterns are being synced to server
3. Verify database migration ran successfully
4. Check server logs for pattern update errors

### Recommendations Not Showing
1. Add some favorite meals first
2. Assign energy levels to favorite meals
3. Check that meals match your current filter
4. Verify API connection is working

### Database Issues
```bash
# Clear app data (will lose local data)
flutter clean
flutter run

# Or uninstall and reinstall the app
```

## ADHD-Specific Design Decisions

1. **Respects Variable Capacity:**
   - Acknowledges that energy levels vary throughout the day
   - Doesn't shame for low-energy choices
   - Provides appropriate options for every level

2. **Automatic Learning:**
   - No need to manually track patterns
   - System learns from your natural behavior
   - Reduces cognitive load

3. **Visual Energy Scale:**
   - Battery icon metaphor is intuitive
   - Color-coded (red/orange/green) for quick recognition
   - Simple 1-5 scale, not overwhelming

4. **Quick Recording:**
   - One-tap to record energy
   - No forms or detailed logging required
   - Can skip if not interested

5. **Flexible Recommendations:**
   - Works with predicted energy if you don't specify
   - Falls back gracefully to moderate if no pattern
   - No rigid rules or requirements

6. **Shame-Free UX:**
   - No judgment for any energy level
   - All levels are valid and supported
   - Focus on what's doable, not ideal

## License

Copyright (C) 2025 RGH Software
Licensed under AGPL-3.0

---

## Questions or Issues?

If you encounter any problems or have questions about this implementation, please:
1. Check this README
2. Review the code comments
3. Check the backend logs
4. Check the Flutter console output
5. Open an issue on GitHub

## Credits

Implemented as part of the Space Food meal planning application.
Special thanks to the ADHD community for design feedback emphasizing the importance of energy-aware meal planning.
