# Space Food Mobile App

Flutter mobile application for Space Food - self-hosted meal planning with AI features.

## Getting Started

### Prerequisites

- Flutter SDK 3.0 or later
- Dart SDK 3.0 or later
- An IDE (VS Code, Android Studio, or IntelliJ IDEA)

### Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Generate code (Freezed, JSON serialization, Retrofit):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Running the App

#### Web
```bash
flutter run -d chrome
```

#### macOS
```bash
flutter run -d macos
```

#### iOS Simulator
```bash
flutter run -d iphone
```

#### Android Emulator
```bash
flutter run -d emulator
```

### Configuration

The app connects to the Space Food API. Configure the API endpoint:

**Development:**
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

**Production:**
```bash
flutter run --dart-define=API_BASE_URL=https://your-domain.com/api/v1
```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── src/
│   ├── app.dart                # Main app widget with routing
│   ├── core/
│   │   ├── config/            # App configuration
│   │   ├── constants/         # Constants
│   │   └── network/           # Network utilities
│   ├── data/
│   │   ├── api/               # API clients (Retrofit)
│   │   ├── models/            # Data models (Freezed)
│   │   ├── repositories/      # Repository pattern
│   │   └── database/          # Local database (Drift)
│   └── presentation/
│       ├── auth/              # Authentication screens
│       ├── home/              # Home screen
│       ├── recipes/           # Recipe screens (coming soon)
│       ├── meal_plans/        # Meal planning (coming soon)
│       ├── pantry/            # Pantry management (coming soon)
│       ├── shopping/          # Shopping lists (coming soon)
│       ├── nutrition/         # Nutrition tracking (coming soon)
│       └── providers/         # Riverpod providers
```

## Features Implemented

### ✅ Phase 1: Authentication
- [x] Login screen
- [x] Register screen
- [x] Secure token storage
- [x] Automatic token refresh
- [x] Protected routes

### 🚧 Phase 2: Core Features (In Progress)
- [ ] Recipe list and detail
- [ ] Recipe creation and editing
- [ ] Image upload
- [ ] Meal plan calendar
- [ ] Pantry management
- [ ] Shopping lists
- [ ] Nutrition tracking

### ⏳ Phase 3: Advanced Features
- [ ] Offline-first data sync (Drift)
- [ ] AI recipe suggestions
- [ ] Barcode scanning
- [ ] Household sharing
- [ ] Image caching

## Development

### Code Generation

This project uses code generation for:
- **Freezed**: Immutable data classes
- **JSON Serializable**: JSON serialization
- **Retrofit**: Type-safe API clients
- **Riverpod**: State management providers

Run code generation when you:
- Add or modify data models
- Add or modify API endpoints
- Add new providers

```bash
# One-time generation
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerate on file changes)
flutter pub run build_runner watch --delete-conflicting-outputs
```

### State Management

This app uses **Riverpod** for state management:

```dart
// Provider definition
final counterProvider = StateProvider<int>((ref) => 0);

// Reading in a widget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Text('Count: $count');
  }
}

// Updating state
ref.read(counterProvider.notifier).state++;
```

### API Client

API calls use **Retrofit** with **Dio**:

```dart
@RestApi()
abstract class RecipeApi {
  factory RecipeApi(Dio dio) = _RecipeApi;

  @GET('/recipes')
  Future<List<Recipe>> getRecipes();

  @POST('/recipes')
  Future<Recipe> createRecipe(@Body() Recipe recipe);
}
```

### Error Handling

The app uses functional error handling with **Dartz**:

```dart
Future<Either<ApiException, Recipe>> getRecipe(String id) async {
  try {
    final recipe = await _api.getRecipe(id);
    return Right(recipe);
  } catch (e) {
    return Left(ApiException.unknown(e.toString()));
  }
}

// Usage
final result = await repository.getRecipe('123');
result.fold(
  (error) => print('Error: $error'),
  (recipe) => print('Success: ${recipe.title}'),
);
```

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/auth/login_test.dart
```

## Building for Production

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
flutter build ipa --release
```

### Web
```bash
flutter build web --release --dart-define=API_BASE_URL=https://your-domain.com/api/v1
```

### macOS
```bash
flutter build macos --release
```

### Windows
```bash
flutter build windows --release
```

### Linux
```bash
flutter build linux --release
```

## Troubleshooting

### Build Runner Issues

If code generation fails:
```bash
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### API Connection Issues

1. Check the API base URL:
```dart
// lib/src/core/config/app_config.dart
static const String apiBaseUrl = ...
```

2. For localhost on Android emulator, use:
```
http://10.0.2.2:8080/api/v1
```

3. For localhost on iOS simulator, use:
```
http://localhost:8080/api/v1
```

### Token Issues

If you get "unauthorized" errors:
1. Clear app data
2. Re-login
3. Check token expiration settings in backend

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0).
See [LICENSE](../LICENSE) for details.
