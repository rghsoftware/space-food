# Food Variety & Rotation System - Test Suite

Comprehensive test suite for the Food Variety & Rotation System feature.

## Overview

This test suite provides coverage for:
- **Backend (Go)**: 4 test files, ~40+ test cases
- **Flutter (Dart)**: 2 test files, ~20+ widget/integration tests
- **Target Coverage**: 80%+ on critical paths

## Backend Tests (Go)

### Test Files

#### 1. `repository_test.go`
Tests all database operations with various scenarios.

**Coverage:**
- ✅ CRUD operations for all 8 tables
- ✅ Upsert logic for hyperfixation tracking
- ✅ Top foods calculation
- ✅ Last eaten tracking
- ✅ Chain suggestion storage
- ✅ Nutrition settings management
- ✅ Rotation schedule operations
- ✅ Integration test for hyperfixation detection flow

**Key Test Cases:**
```go
TestRepository_UpsertHyperfixation
TestRepository_GetActiveHyperfixations
TestRepository_UpdateLastEaten
TestRepository_GetTopFoods
TestRepository_SaveChainSuggestions
TestRepository_Integration_HyperfixationDetection
```

**Running:**
```bash
cd backend/internal/features/food_variety
go test -v -run TestRepository
```

#### 2. `service_test.go`
Tests business logic including variety scoring and non-judgmental messaging.

**Coverage:**
- ✅ Variety score calculation algorithm (1-10 scale)
- ✅ Hyperfixation detection (5+ times in 7 days)
- ✅ Non-judgmental rotation suggestions
- ✅ Variety analysis generation
- ✅ Weekly insights (positive-only)
- ✅ Chain suggestion generation
- ✅ Rotation schedule validation

**Critical Tests:**
```go
TestService_CalculateVarietyScore - Tests scoring algorithm
TestService_TrackFoodConsumption - Tests hyperfixation detection
TestService_GenerateRotationSuggestions - Tests non-judgmental language
TestService_GenerateWeeklyInsights - Ensures positive-only messaging
```

**Example Test:**
```go
func TestService_GenerateRotationSuggestions(t *testing.T) {
    tests := []struct {
        name            string
        topFoods        []FoodFrequency
        hyperfixations  []FoodHyperfixation
        checkMessages   func(t *testing.T, suggestions []string)
    }{
        {
            name: "with active hyperfixations - non-judgmental",
            checkMessages: func(t *testing.T, suggestions []string) {
                // Must contain positive language
                found := false
                for _, msg := range suggestions {
                    if contains(msg, "totally okay") {
                        found = true
                    }
                }
                assert.True(t, found)

                // Must NOT contain negative words
                for _, msg := range suggestions {
                    assert.NotContains(t, msg, "problem")
                    assert.NotContains(t, msg, "fix")
                    assert.NotContains(t, msg, "unhealthy")
                }
            },
        },
    }
}
```

**Running:**
```bash
go test -v -run TestService
```

#### 3. `handler_test.go`
Tests HTTP endpoints with various request/response scenarios.

**Coverage:**
- ✅ All 17 REST endpoints
- ✅ Request validation
- ✅ Response formatting
- ✅ Error handling
- ✅ Authentication (mocked)
- ✅ JSON parsing

**Test Structure:**
```go
TestHandler_GetActiveHyperfixations
TestHandler_GenerateChainSuggestions
TestHandler_RecordChainFeedback
TestHandler_GetVarietyAnalysis
TestHandler_UpdateNutritionSettings
TestHandler_CreateRotationSchedule
TestHandler_ErrorHandling
```

**Running:**
```bash
go test -v -run TestHandler
```

#### 4. `ai_chain_service_test.go`
Tests Mock AI service food chaining logic.

**Coverage:**
- ✅ Texture-based matching (crispy → chicken tenders)
- ✅ Specific food mappings (nuggets → popcorn chicken)
- ✅ Fallback suggestions
- ✅ Similarity score ordering
- ✅ Reasoning quality (explains WHY similar)
- ✅ Non-judgmental language verification
- ✅ Count parameter respect
- ✅ Benchmark tests

**Key Tests:**
```go
TestMockAIService_TextureMatching
TestMockAIService_SpecificFoodMappings
TestMockAIService_ReasoningQuality - Ensures no judgmental language
TestMockAIService_SimilarityScoreOrdering
```

**Example:**
```go
func TestMockAIService_ReasoningQuality(t *testing.T) {
    // Reasoning should explain WHY it's similar
    for _, s := range suggestions {
        reasoning := strings.ToLower(s.Reasoning)

        // Should mention characteristics
        hasCharacteristic := strings.Contains(reasoning, "texture") ||
            strings.Contains(reasoning, "flavor") ||
            strings.Contains(reasoning, "crispy")
        assert.True(t, hasCharacteristic)

        // Should not be judgmental
        assert.NotContains(t, reasoning, "should")
        assert.NotContains(t, reasoning, "must")
    }
}
```

**Running:**
```bash
go test -v -run TestMockAI
go test -bench=. -run BenchmarkMockAI
```

### Running All Backend Tests

```bash
# All tests
cd backend/internal/features/food_variety
go test -v

# With coverage
go test -v -coverprofile=coverage.out
go tool cover -html=coverage.out

# Specific test
go test -v -run TestService_CalculateVarietyScore

# Short tests only (skip integration tests)
go test -v -short
```

## Flutter Tests (Dart)

### Test Files

#### 1. `food_variety_repository_test.dart`
Tests offline-first repository logic with API fallback.

**Coverage:**
- ✅ API-first data fetching
- ✅ Local cache fallback when offline
- ✅ Sync to local database
- ✅ Error handling (API + DB failures)
- ✅ Either-based error flow
- ✅ Default opt-out nutrition settings

**Key Test Cases:**
```dart
test('should return hyperfixations from API and cache locally')
test('should fallback to local database when API fails')
test('should return Left when both API and database fail')
test('should verify default settings are opt-out')
test('should work offline with cached data')
```

**Running:**
```bash
cd app
flutter test test/features/food_variety/food_variety_repository_test.dart
```

#### 2. `variety_dashboard_widget_test.dart`
Tests UI components with emphasis on non-judgmental design.

**Coverage:**
- ✅ Variety score display
- ✅ Non-judgmental messaging for low scores
- ✅ Celebration for high scores
- ✅ Color scheme (blue for low, NOT red)
- ✅ "Favorite foods" language (not "hyperfixations")
- ✅ Weekly insights display
- ✅ Dismiss insights functionality
- ✅ Loading states
- ✅ Error states
- ✅ Navigation
- ✅ Pull-to-refresh
- ✅ Accessibility (semantic labels, contrast)

**Critical Tests:**
```dart
testWidgets('should use blue color for low score, not red')
testWidgets('should display non-judgmental message for low score')
testWidgets('should display hyperfixations as "favorite foods"')
```

**Example:**
```dart
testWidgets('should display non-judgmental message for low score',
    (WidgetTester tester) async {
  // Arrange - low variety score
  final analysis = VarietyAnalysis(varietyScore: 3, ...);

  await tester.pumpWidget(...);

  // Assert - should have positive messaging
  expect(find.textContaining('okay'), findsOneWidget);

  // Should NOT have negative words
  expect(find.textContaining('problem'), findsNothing);
  expect(find.textContaining('should'), findsNothing);
});
```

**Running:**
```bash
flutter test test/features/food_variety/variety_dashboard_widget_test.dart

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Running All Flutter Tests

```bash
cd app

# All tests
flutter test

# Specific test
flutter test test/features/food_variety/food_variety_repository_test.dart

# With coverage report
flutter test --coverage
lcov --summary coverage/lcov.info
```

## Test Coverage Goals

### Critical Paths (80%+ Target)

**Backend:**
- ✅ Variety scoring algorithm: `calculateVarietyScore()`
- ✅ Hyperfixation detection: `TrackFoodConsumption()`
- ✅ Non-judgmental messaging: `generateRotationSuggestions()`
- ✅ Food chaining: `GenerateChainSuggestions()`
- ✅ All HTTP endpoints

**Flutter:**
- ✅ Offline-first repository logic
- ✅ API fallback behavior
- ✅ Widget rendering (score, messages, insights)
- ✅ Non-judgmental UI language
- ✅ Error handling

### Current Coverage Status

```
Backend (Go):
├── repository_test.go     - Structure complete, needs DB setup
├── service_test.go        - ✅ Complete with mocks
├── handler_test.go        - ✅ Complete with httptest
└── ai_chain_service_test.go - ✅ Complete

Flutter (Dart):
├── repository_test.dart   - Structure complete, needs mock generation
└── widget_test.dart       - Structure complete, needs provider setup
```

## Setting Up Tests

### Backend Prerequisites

```bash
# Install test dependencies
cd backend
go get github.com/stretchr/testify/assert
go get github.com/stretchr/testify/mock
go get github.com/stretchr/testify/require

# Setup test database (for integration tests)
psql -c "CREATE DATABASE space_food_test;"
psql -d space_food_test -f internal/database/postgres/migrations/*.sql
```

### Flutter Prerequisites

```bash
cd app

# Install test dependencies
flutter pub get

# Generate mocks
flutter pub run build_runner build

# Run code generation for freezed/json_serializable
flutter pub run build_runner build --delete-conflicting-outputs
```

## Test Data Fixtures

### Backend Test Data

Located in test files as inline fixtures:

```go
// Example hyperfixation fixture
func createTestHyperfixation() *FoodHyperfixation {
    return &FoodHyperfixation{
        ID:                  uuid.New(),
        UserID:              uuid.New(),
        FoodName:            "Chicken nuggets",
        FrequencyCount:      8,
        PeakFrequencyPerDay: 2.5,
        IsActive:            true,
        StartedAt:           time.Now().Add(-7 * 24 * time.Hour),
        CreatedAt:           time.Now(),
        UpdatedAt:           time.Now(),
    }
}
```

### Flutter Test Data

```dart
// Example variety analysis fixture
VarietyAnalysis createTestAnalysis({int score = 7}) {
  return VarietyAnalysis(
    uniqueFoodsLast7Days: 8,
    uniqueFoodsLast30Days: 15,
    topFoods: [
      FoodFrequency(
        foodName: 'Pizza',
        count: 10,
        percentage: 25.0,
      ),
    ],
    activeHyperfixations: [],
    suggestedRotations: [],
    varietyScore: score,
  );
}
```

## Continuous Integration

### GitHub Actions Workflow

```yaml
name: Food Variety Tests

on: [push, pull_request]

jobs:
  backend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-go@v2
        with:
          go-version: '1.22'
      - name: Run backend tests
        run: |
          cd backend/internal/features/food_variety
          go test -v -coverprofile=coverage.out
          go tool cover -func=coverage.out

  flutter-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.0.0'
      - name: Run Flutter tests
        run: |
          cd app
          flutter pub get
          flutter test --coverage
```

## Test Principles

### ADHD-Friendly Design Verification

All tests verify the core design principles:

1. **Non-Judgmental Language**
   - Tests explicitly check for absence of: "should", "must", "problem", "fix", "unhealthy"
   - Tests verify presence of: "okay", "great", "ready", "when you want"

2. **Color Choices**
   - Low scores: Blue (informational), NOT red (negative)
   - High scores: Green (celebration)
   - Tests verify `_getScoreColor()` returns correct colors

3. **Positive-Only Insights**
   - No deficiency messaging
   - Celebrations for achievements
   - Tests verify no negative words in insights

4. **Opt-In Philosophy**
   - Nutrition tracking disabled by default
   - Tests verify `trackingEnabled: false` on new settings

## Troubleshooting

### Common Issues

**Backend:**
```bash
# Missing dependencies
go mod tidy

# Test database not found
psql -c "CREATE DATABASE space_food_test;"

# Mock expectations not met
# Check that all mock.On() calls have matching function calls
```

**Flutter:**
```bash
# Generated files missing
flutter pub run build_runner build --delete-conflicting-outputs

# Provider override not working
# Ensure ProviderScope wraps MaterialApp in tests

# Widget not found
await tester.pumpAndSettle();  # Wait for async operations
```

## Future Enhancements

- [ ] Add integration tests with real test database
- [ ] Add E2E tests for complete user flows
- [ ] Add performance benchmarks
- [ ] Add mutation testing
- [ ] Increase coverage to 90%+
- [ ] Add visual regression tests
- [ ] Add accessibility audit tests

## License

Space Food - Self-Hosted Meal Planning Application
Copyright (C) 2025 RGH Software
Licensed under AGPL-3.0
