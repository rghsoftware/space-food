# Meal Reminder & Logging System Implementation

## Overview

This document describes the implementation of the Meal Reminder & Logging System for Space Food - a feature specifically designed for ADHD users who struggle with remembering to eat.

## Implementation Status

✅ **Backend (Go)**: Complete
✅ **Frontend (Flutter)**: Complete
⚠️ **Code Generation**: Required
⚠️ **Testing**: Pending

## Features Implemented

### Core Features
- ✅ Recurring meal reminders with customizable times
- ✅ Pre-alert notifications (setup time before meal)
- ✅ Days-of-week scheduling
- ✅ One-tap meal logging
- ✅ Energy level tracking (1-5 scale)
- ✅ Visual eating timeline (shame-free progress tracking)
- ✅ Offline-first with Drift local database
- ✅ Automatic background sync
- ✅ Streak calculation (optional)
- ✅ Customizable daily goals (meals & snacks)

### ADHD-Friendly Design
- ✅ Shame-free UX (show_missed_meals defaults to false)
- ✅ Minimal-friction logging (one-tap "Ate!" button)
- ✅ Visual progress indicators
- ✅ Optional energy level tracking
- ✅ No guilt-inducing missed meal highlights (unless opted in)

## Architecture

### Backend (Go)

#### Files Created/Modified:

1. **Database Migration**
   - `backend/internal/database/postgres/migrations/002_meal_reminders.sql`
   - Three tables: `meal_reminders`, `meal_logs`, `eating_timeline_settings`

2. **Models**
   - `backend/internal/features/meal_reminders/models.go`
   - Data structures and DTOs for reminders, logs, settings

3. **Repository**
   - `backend/internal/features/meal_reminders/repository.go`
   - CRUD operations for all tables
   - PostgreSQL with lib/pq for array support

4. **Service**
   - `backend/internal/features/meal_reminders/service.go`
   - Business logic: validation, timeline generation, streak calculation

5. **HTTP Handler**
   - `backend/internal/features/meal_reminders/handler.go`
   - REST API endpoints

6. **Router Integration**
   - `backend/internal/api/rest/router.go` (modified)
   - Wired up meal reminder routes

#### API Endpoints:

```
POST   /api/v1/meal-reminders          - Create reminder
GET    /api/v1/meal-reminders          - List reminders
GET    /api/v1/meal-reminders/:id      - Get reminder
PUT    /api/v1/meal-reminders/:id      - Update reminder
DELETE /api/v1/meal-reminders/:id      - Delete reminder

POST   /api/v1/meal-logs               - Log a meal
GET    /api/v1/meal-logs/timeline      - Get eating timeline

GET    /api/v1/eating-timeline-settings - Get settings
PUT    /api/v1/eating-timeline-settings - Update settings
```

### Frontend (Flutter)

#### Files Created:

##### Data Layer
1. **Models** (Freezed)
   - `app/lib/src/features/meal_reminders/data/models/meal_reminder.dart`
   - `app/lib/src/features/meal_reminders/data/models/meal_log.dart`
   - `app/lib/src/features/meal_reminders/data/models/eating_timeline.dart`

2. **Local Database** (Drift)
   - `app/lib/src/features/meal_reminders/data/local/meal_reminders_database.dart`
   - Three tables with sync tracking
   - Offline-first storage

3. **API Client** (Retrofit)
   - `app/lib/src/features/meal_reminders/data/api/meal_reminder_api.dart`
   - REST API integration

4. **Repository**
   - `app/lib/src/features/meal_reminders/data/repositories/meal_reminder_repository.dart`
   - Offline-first implementation
   - Automatic sync to server
   - Graceful fallback to local data

##### Services
5. **Notification Service**
   - `app/lib/src/features/meal_reminders/services/notification_service.dart`
   - flutter_local_notifications integration
   - Weekly recurring notifications
   - Pre-alert scheduling
   - Notification actions (Log Meal, Dismiss)

##### Presentation Layer
6. **Screens**
   - `app/lib/src/features/meal_reminders/presentation/screens/meal_reminders_screen.dart`
     - Manage meal reminders (create, edit, delete, toggle)

   - `app/lib/src/features/meal_reminders/presentation/screens/eating_timeline_screen.dart`
     - Visual timeline with 30-day grid
     - Streak display
     - Today's progress indicators
     - Shame-free design

   - `app/lib/src/features/meal_reminders/presentation/screens/timeline_settings_screen.dart`
     - Configure daily goals
     - Toggle streak display
     - Toggle missed meals visibility
     - ADHD-friendly tips

7. **Widgets**
   - `app/lib/src/features/meal_reminders/presentation/widgets/quick_meal_log_widget.dart`
     - QuickMealLogButton (FAB)
     - QuickMealLogSheet (bottom sheet with energy level)
     - OneTapLogButton (minimal friction)

   - `app/lib/src/features/meal_reminders/presentation/widgets/notification_permission_prompt.dart`
     - Permission request UI
     - Full-screen onboarding

8. **Providers** (Riverpod)
   - `app/lib/src/features/meal_reminders/presentation/providers/meal_reminder_providers.dart`
     - Infrastructure providers (database, API, repository)
     - State providers (reminders, timeline, settings)
     - Action providers (logging, sync)

##### Core Providers
9. **Core Infrastructure**
   - `app/lib/src/core/providers/dio_provider.dart`
   - `app/lib/src/core/providers/auth_provider.dart`

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
   # Ensure PostgreSQL is running
   # Migrations will run automatically on startup
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

## Configuration

### Backend Configuration

The backend uses the existing Space Food configuration. Ensure your `.env` or config file includes:

```env
DATABASE_URL=postgresql://user:password@localhost:5432/space_food
SERVER_PORT=8080
```

### Frontend Configuration

Update the base URL in `app/lib/src/core/providers/dio_provider.dart`:

```dart
baseUrl: 'http://your-server-url:8080', // Update this
```

## Usage

### Creating a Meal Reminder

1. Open the app and navigate to "Meal Reminders"
2. Tap the "+" button
3. Enter reminder details:
   - Name (e.g., "Breakfast", "Lunch")
   - Time (e.g., 8:00 AM)
   - Pre-alert minutes (e.g., 15 minutes before)
   - Days of week
4. Save the reminder

Notifications will be automatically scheduled.

### Logging a Meal

**Quick Log (One-Tap):**
- Tap the floating "Log Meal" button
- Tap "Log Now"
- Done! (< 2 seconds)

**Log with Energy Level:**
- Tap the floating "Log Meal" button
- Select energy level (1-5)
- Optionally add notes
- Tap "Log Now"

**Log from Notification:**
- When you receive a meal reminder notification
- Tap "Log Meal" action directly from the notification
- Meal is logged immediately

### Viewing Progress

1. Navigate to "Eating Timeline"
2. See:
   - Current streak (if enabled)
   - Today's progress (meals & snacks vs. goals)
   - 30-day visual timeline grid
   - Color-coded days:
     - Green: Met goals
     - Blue: Partial progress
     - Grey: No data
     - Red: Missed (only if enabled in settings)

### Adjusting Settings

1. Navigate to "Eating Timeline"
2. Tap the settings icon
3. Configure:
   - Daily meal goal (0-6)
   - Daily snack goal (0-6)
   - Show streak (on/off)
   - Show missed meals (on/off - defaults to off for shame-free tracking)

## Offline-First Implementation

### How It Works

1. **Write Operations:**
   - All writes (create reminder, log meal, update settings) are saved to local Drift database first
   - Then attempts to sync to server
   - If offline, queued for later sync
   - User sees immediate feedback

2. **Read Operations:**
   - Attempts to fetch from server first
   - Falls back to local database if offline
   - Always shows data, even offline

3. **Background Sync:**
   - Automatic sync when connection is restored
   - Manual sync via pull-to-refresh
   - Conflict resolution (server wins)

4. **Sync Tracking:**
   - Each table has a `synced_to_server` column
   - Unsynced items are identified and pushed on next sync

## Testing

### Backend Testing

```bash
cd backend
go test ./internal/features/meal_reminders/...
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

2. **Notification Permissions:**
   - User must grant notification permissions
   - iOS requires explicit permission request
   - Android 13+ requires runtime permission

3. **Timezone Support:**
   - Notifications use device's local timezone
   - Server stores times in UTC
   - Timezone package handles conversions

4. **Background Sync:**
   - Currently manual sync only
   - TODO: Implement WorkManager for periodic background sync

## Future Enhancements

- [ ] Smart meal suggestions based on time of day
- [ ] Integration with recipe database
- [ ] Meal photo attachments
- [ ] Share eating timeline with household
- [ ] Apple Watch / Wear OS quick logging
- [ ] Siri / Google Assistant integration
- [ ] Periodic background sync (WorkManager)
- [ ] Export eating timeline as PDF/CSV
- [ ] Nutrition tracking integration

## Troubleshooting

### Build Runner Fails
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Notifications Not Working
1. Check notification permissions in device settings
2. Verify timezone package is initialized
3. Check pending notifications:
   ```dart
   final service = MealReminderNotificationService();
   final pending = await service.getPendingNotifications();
   print('Pending: ${pending.length}');
   ```

### Sync Issues
1. Check internet connection
2. Verify backend is running
3. Check console for API errors
4. Manual sync: Pull-to-refresh on timeline screen

### Database Issues
```bash
# Clear app data (will lose local data)
flutter clean
flutter run

# Or uninstall and reinstall the app
```

## ADHD-Specific Design Decisions

1. **Shame-Free by Default:**
   - `show_missed_meals` defaults to `false`
   - No guilt-inducing red X's or "you failed" messages
   - Focus on progress, not perfection

2. **Minimal Friction:**
   - One-tap logging (no forms required)
   - Optional energy level (not required)
   - Quick access via FAB and notifications

3. **Visual Progress:**
   - Color-coded timeline
   - Progress circles
   - Streak counter (motivating, not shaming)

4. **Flexible Goals:**
   - User-defined goals (not prescriptive)
   - Can be adjusted anytime
   - No judgment for changing goals

5. **Pre-Alerts:**
   - 15-minute warning by default
   - Gives time to prepare
   - Reduces decision fatigue

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
Special thanks to the ADHD community for design feedback and requirements.
