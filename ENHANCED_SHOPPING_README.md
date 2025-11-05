# Enhanced Shopping Experience Implementation

## Overview

This document describes the implementation plan for the Enhanced Shopping Experience feature set for Space Food - designed to reduce cognitive load for ADHD users through visual organization, photo-based pantry management, store layouts, and family synchronization.

## Implementation Status

✅ **Database Schema**: Complete
⏳ **Backend (Go)**: Pending
⏳ **Frontend (Flutter)**: Pending
⏳ **Testing**: Pending

## Features

### Core Features
- ✅ Database schema for all features
- ⏳ Visual grocery lists with photos
- ⏳ Pantry photo inventory
- ⏳ Store layout organization
- ⏳ Family/household sync
- ⏳ Item assignment
- ⏳ Online ordering integration (basic structure)

### ADHD-Friendly Design Principles
- **Visual over Text**: Photos instead of abstract lists
- **"Out of Sight, Out of Mind" Solution**: Photo-based pantry inventory
- **Reduced Wandering**: Store layout organization
- **Shared Responsibility**: Family sync and item assignment
- **Eliminate Trips**: Online ordering integration

## Database Schema (Completed)

### Tables Created

#### 1. Households & Members
```sql
households
- id: UUID
- name: VARCHAR(200)
- created_by: UUID → users
- created_at, updated_at: TIMESTAMP

household_members
- household_id: UUID → households
- user_id: UUID → users
- role: VARCHAR(20) (admin/member)
- joined_at: TIMESTAMP
```

**Purpose**: Enable family sharing of shopping lists and pantry

#### 2. Store Layouts
```sql
store_layouts
- id: UUID
- user_id: UUID → users
- household_id: UUID → households (nullable)
- store_name: VARCHAR(200)
- is_default: BOOLEAN
- created_at, updated_at: TIMESTAMP

store_sections
- id: UUID
- store_layout_id: UUID → store_layouts
- section_name: VARCHAR(100) (e.g., "Produce", "Dairy")
- section_order: INTEGER
- color: VARCHAR(7) (hex code like #FF6B6B)
- icon: VARCHAR(50)
- created_at: TIMESTAMP
```

**Purpose**: Organize shopping by store layout to reduce wandering

#### 3. Enhanced Pantry Items
```sql
ALTER TABLE pantry_items ADD:
- photo_url: VARCHAR(500)
- thumbnail_url: VARCHAR(500)
- expiration_date: DATE
- location: VARCHAR(100) (fridge/pantry/freezer)
- is_running_low: BOOLEAN
- minimum_quantity: DECIMAL(10,2)
- household_id: UUID → households
- is_shared: BOOLEAN
```

**Purpose**: Visual pantry with photos and location tracking

#### 4. Enhanced Shopping List Items
```sql
ALTER TABLE shopping_list_items ADD:
- store_section_id: UUID → store_sections
- photo_url: VARCHAR(500)
- added_from_recipe_id: UUID → recipes
- sort_order: INTEGER
- assigned_to: UUID → users
- purchased_by: UUID → users
- purchased_at: TIMESTAMP
- notes: TEXT
- online_product_id: VARCHAR(200)
- online_provider: VARCHAR(50)
- online_product_url: TEXT
- online_price: DECIMAL(10,2)
```

**Purpose**: Organized, assignable shopping with online integration

#### 5. Shared Lists
```sql
ALTER TABLE shopping_lists ADD:
- household_id: UUID → households
- is_shared: BOOLEAN
```

**Purpose**: Share shopping lists with household members

#### 6. Online Ordering Integration
```sql
online_order_integrations
- id: UUID
- user_id: UUID → users
- household_id: UUID → households (nullable)
- provider: VARCHAR(50) (instacart/amazon_fresh/walmart/other)
- provider_user_id: VARCHAR(200)
- auth_token, refresh_token: TEXT
- token_expires_at: TIMESTAMP
- is_active: BOOLEAN
- created_at, updated_at: TIMESTAMP
```

**Purpose**: Basic structure for online grocery ordering

## Backend Implementation Guide

### 1. Models (`backend/internal/features/enhanced_shopping/models.go`)

Create models for:
- `StoreLayout` with nested `[]StoreSection`
- `PantryItemEnhanced` (extends base PantryItem)
- `ShoppingListItemEnhanced` (extends base ShoppingListItem)
- `Household` with nested `[]HouseholdMember`
- `OnlineOrderIntegration`
- Request/Response DTOs

**Key Models:**
```go
type StoreLayout struct {
    ID        uuid.UUID      `json:"id"`
    UserID    uuid.UUID      `json:"user_id"`
    StoreName string         `json:"store_name"`
    IsDefault bool           `json:"is_default"`
    Sections  []StoreSection `json:"sections,omitempty"`
}

type StoreSection struct {
    ID            uuid.UUID `json:"id"`
    StoreLayoutID uuid.UUID `json:"store_layout_id"`
    SectionName   string    `json:"section_name"`
    SectionOrder  int       `json:"section_order"`
    Color         string    `json:"color,omitempty"`
    Icon          string    `json:"icon,omitempty"`
}

type Household struct {
    ID        uuid.UUID         `json:"id"`
    Name      string            `json:"name"`
    CreatedBy uuid.UUID         `json:"created_by"`
    Members   []HouseholdMember `json:"members,omitempty"`
}
```

### 2. Repository (`backend/internal/features/enhanced_shopping/repository.go`)

Implement methods for:

**Store Layouts:**
- `CreateStoreLayout(ctx, layout) error`
- `GetUserStoreLayouts(ctx, userID) ([]StoreLayout, error)`
- `GetDefaultStoreLayout(ctx, userID) (*StoreLayout, error)`
- `UpdateStoreLayout(ctx, layout) error`
- `DeleteStoreLayout(ctx, layoutID, userID) error`
- `GetLayoutSections(ctx, layoutID) ([]StoreSection, error)`

**Households:**
- `CreateHousehold(ctx, household) error`
- `GetUserHouseholds(ctx, userID) ([]Household, error)`
- `GetHouseholdMembers(ctx, householdID) ([]HouseholdMember, error)`
- `AddHouseholdMember(ctx, householdID, userID, role) error`
- `RemoveHouseholdMember(ctx, householdID, userID) error`
- `UpdateMemberRole(ctx, householdID, userID, role) error`

**Enhanced Shopping Lists:**
- `GetShoppingListWithSections(ctx, listID) ([]ShoppingListItemEnhanced, error)`
- `UpdateItemSection(ctx, itemID, sectionID) error`
- `AssignItemToMember(ctx, itemID, userID) error`
- `MarkItemPurchased(ctx, itemID, userID) error`

**Enhanced Pantry:**
- `GetPantryWithPhotos(ctx, userID, householdID) ([]PantryItemEnhanced, error)`
- `UpdatePantryPhoto(ctx, itemID, userID, photoURL, thumbnailURL) error`
- `GetPantryByLocation(ctx, userID, location) ([]PantryItemEnhanced, error)`
- `UpdatePantryLocation(ctx, itemID, location) error`

### 3. Service (`backend/internal/features/enhanced_shopping/service.go`)

Business logic:

**Store Layouts:**
- Default color assignment to sections
- Validation of section ordering
- Default layout management

**Photo Management:**
- Upload original and generate thumbnail
- Store in configured storage (S3/local)
- Return URLs

**Household Management:**
- Invitation flow (would integrate with email)
- Permission checking (admin vs member)
- Sharing validation

**Shopping Organization:**
- Group items by store section
- Sort by section order
- Calculate completion percentage per section

**Key Methods:**
```go
func (s *Service) CreateStoreLayout(ctx, userID, req) (*StoreLayout, error)
func (s *Service) UploadPantryPhoto(ctx, itemID, userID, photoData) (string, error)
func (s *Service) GetOrganizedShoppingList(ctx, listID) (map[string][]ShoppingListItem, error)
func (s *Service) CreateHousehold(ctx, userID, req) (*Household, error)
func (s *Service) InviteHouseholdMember(ctx, householdID, email) error
```

### 4. Handlers (`backend/internal/features/enhanced_shopping/handler.go`)

REST API endpoints:

**Store Layouts:**
```
POST   /store-layouts              - Create layout
GET    /store-layouts              - List user layouts
GET    /store-layouts/:id          - Get specific layout
PUT    /store-layouts/:id          - Update layout
DELETE /store-layouts/:id          - Delete layout
POST   /store-layouts/:id/default  - Set as default
```

**Households:**
```
POST   /households                 - Create household
GET    /households                 - List user households
GET    /households/:id             - Get household
PUT    /households/:id             - Update household
DELETE /households/:id             - Delete household
POST   /households/:id/members     - Add member
DELETE /households/:id/members/:uid - Remove member
```

**Shopping Lists:**
```
GET    /shopping-lists/:id/organized     - Get organized by sections
PUT    /shopping-lists/items/:id/section - Update item section
PUT    /shopping-lists/items/:id/assign  - Assign item
POST   /shopping-lists/items/:id/purchase - Mark purchased
```

**Pantry:**
```
GET    /pantry/photos              - Get pantry with photos
POST   /pantry/:id/photo           - Upload photo
GET    /pantry/location/:loc       - Get by location
PUT    /pantry/:id/location        - Update location
```

### 5. Router Integration

Add to `backend/internal/api/rest/router.go`:

```go
// Enhanced shopping features
enhancedShoppingRepo := enhanced_shopping.NewRepository(db.DB())
enhancedShoppingService := enhanced_shopping.NewService(
    enhancedShoppingRepo,
    storageProvider,
)
enhancedShoppingHandler := enhanced_shopping.NewHandler(enhancedShoppingService)
enhancedShoppingHandler.RegisterRoutes(protected)
```

## Frontend Implementation Guide

### 1. Models (`app/lib/src/features/enhanced_shopping/data/models/`)

**Freezed models:**
- `store_layout.dart` - StoreLayout, StoreSection
- `household.dart` - Household, HouseholdMember
- `enhanced_pantry.dart` - PantryItemEnhanced
- `enhanced_shopping_item.dart` - ShoppingListItemEnhanced

```dart
@freezed
class StoreLayout with _$StoreLayout {
  const factory StoreLayout({
    required String id,
    required String userId,
    required String storeName,
    @Default(false) bool isDefault,
    @Default([]) List<StoreSection> sections,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _StoreLayout;

  factory StoreLayout.fromJson(Map<String, dynamic> json) =>
      _$StoreLayoutFromJson(json);
}
```

### 2. Local Database (`app/lib/src/features/enhanced_shopping/data/local/`)

**Drift tables:**
```dart
class StoreLayouts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get storeName => text()();
  BoolColumn get isDefault => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get syncedToServer => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class StoreSections extends Table {
  TextColumn get id => text()();
  TextColumn get storeLayoutId => text()();
  TextColumn get sectionName => text()();
  IntColumn get sectionOrder => integer()();
  TextColumn get color => text().nullable()();
  // etc.
}
```

### 3. UI Screens

#### Organized Shopping List Screen
```dart
class OrganizedShoppingListScreen extends ConsumerWidget {
  // Display items grouped by store section
  // Color-coded sections
  // Section completion progress
  // Drag-and-drop to reorder/reassign sections
}
```

**Features:**
- Sections displayed in order (Produce, Dairy, etc.)
- Color-coded section headers
- Progress indicator per section
- Item assignment to household members
- Photo display for visual recognition
- Quick check-off

#### Pantry Photo Screen
```dart
class PantryPhotoScreen extends ConsumerWidget {
  // Grid view of pantry items with photos
  // Filter by location (pantry/fridge/freezer)
  // Camera integration for quick adds
  // "Running low" badges
}
```

**Features:**
- Grid layout with photos
- Location tabs (Pantry/Fridge/Freezer)
- Quick photo capture
- Visual "running low" indicators
- Expiration date warnings

#### Store Layout Management Screen
```dart
class StoreLayoutScreen extends ConsumerWidget {
  // Create/edit store layouts
  // Drag-and-drop section reordering
  // Color picker for sections
  // Set default layout
}
```

#### Household Management Screen
```dart
class HouseholdScreen extends ConsumerWidget {
  // List household members
  // Invite new members
  // Manage roles
  // View shared lists/pantry
}
```

### 4. Riverpod Providers

```dart
@riverpod
class StoreLayouts extends _$StoreLayouts {
  @override
  Future<List<StoreLayout>> build() async {
    final repository = ref.watch(enhancedShoppingRepositoryProvider);
    final result = await repository.getStoreLayouts();
    return result.fold((error) => throw error, (layouts) => layouts);
  }

  Future<void> createLayout(CreateStoreLayoutRequest request) async {
    // Create and refresh
  }
}

@riverpod
class OrganizedShoppingList extends _$OrganizedShoppingList {
  @override
  Future<Map<String, List<ShoppingListItem>>> build(String listId) async {
    // Get list organized by sections
  }
}

@riverpod
class PantryWithPhotos extends _$PantryWithPhotos {
  @override
  Future<List<PantryItemEnhanced>> build(String? location) async {
    // Get pantry items with photos, optionally filtered by location
  }
}
```

## Usage Scenarios

### Scenario 1: Creating a Store Layout

1. User navigates to "Store Layouts"
2. Taps "Create Layout"
3. Enters store name (e.g., "Whole Foods")
4. Adds sections in order:
   - Produce
   - Dairy
   - Meat
   - Bakery
   - Frozen
   - Pantry Staples
5. System assigns colors automatically
6. Sets as default for future lists

### Scenario 2: Adding Pantry Item with Photo

1. User opens Pantry screen
2. Selects location (Fridge)
3. Taps camera button
4. Takes photo of milk carton
5. System recognizes or prompts for name
6. Adds to pantry with photo
7. Photo appears in grid view
8. When milk runs low, "Low" badge appears

### Scenario 3: Organized Shopping Trip

1. User opens shopping list
2. Items automatically grouped by store section
3. User follows sections in order:
   - **Produce** (green header)
     - ☑ Apples
     - ☐ Lettuce
   - **Dairy** (blue header)
     - ☐ Milk
     - ☐ Cheese
4. Checks off items as shopping
5. Progress shows 50% complete
6. No forgetting or backtracking

### Scenario 4: Family Sharing

1. Parent creates household "Smith Family"
2. Invites spouse via email
3. Both can access shared shopping list
4. Parent assigns milk to spouse
5. Spouse checks off when purchased
6. Both see real-time updates
7. No duplicate purchases

## ADHD-Specific Benefits

### 1. Visual over Abstract
**Problem**: Text-only lists are abstract and forgettable
**Solution**: Photos of actual products
**Benefit**: Recognition memory > recall memory

### 2. "Out of Sight, Out of Mind"
**Problem**: Forget what's in fridge/pantry
**Solution**: Photo inventory at a glance
**Benefit**: Visual reminder of what you have

### 3. Reduced Wandering
**Problem**: Forget items, wander store randomly
**Solution**: Organized by store layout
**Benefit**: Follow logical path, less forgetting

### 4. Shared Cognitive Load
**Problem**: One person remembers everything
**Solution**: Family sync and assignment
**Benefit**: Distributed responsibility

### 5. Eliminate the Trip
**Problem**: Executive function barrier of going to store
**Solution**: Online ordering integration
**Benefit**: Can shop when energy is low

## Testing Strategy

### Backend Tests
```go
func TestCreateStoreLayout(t *testing.T) {
    // Test creating layout with sections
    // Test auto-color assignment
    // Test default layout management
}

func TestOrganizedShoppingList(t *testing.T) {
    // Test grouping by sections
    // Test ordering
    // Test empty sections
}

func TestHouseholdSharing(t *testing.T) {
    // Test creating household
    // Test adding members
    // Test permission checking
}
```

### Frontend Tests
```dart
testWidgets('Organized shopping list displays sections', (tester) async {
  // Test section grouping
  // Test color coding
  // Test item ordering
});

testWidgets('Pantry photo grid displays correctly', (tester) async {
  // Test photo display
  // Test location filtering
  // Test low stock badges
});
```

## Build Instructions

### Backend
1. Ensure database migration 004 has run
2. Implement models, repository, service, handlers
3. Wire up routes in router
4. Test endpoints

### Frontend
1. Install dependencies (already in pubspec.yaml)
2. Create models and run code generation
3. Implement Drift tables
4. Create screens and widgets
5. Wire up Riverpod providers
6. Test UI

```bash
cd app
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

## Success Metrics

- **Photo Pantry Usage**: >50% of active users
- **Store Layout Adoption**: >40% create custom layouts
- **Household Sharing**: >30% use family sharing
- **Shopping Time Reduction**: Measure average trip time
- **Forgotten Items**: Reduced by 60%+
- **User Satisfaction**: ADHD-friendly design feedback

## Known Limitations

1. **Photo Storage**: Requires S3 or local file storage configured
2. **Image Processing**: Thumbnail generation needs image library
3. **Online Ordering**: Requires API integrations with providers
4. **Real-time Sync**: Requires WebSocket or polling for shared lists
5. **Barcode Scanning**: Not yet implemented (future enhancement)

## Future Enhancements

- [ ] Barcode scanning for quick pantry adds
- [ ] AI product recognition from photos
- [ ] Recipe-to-shopping-list with automatic section assignment
- [ ] Expiration date tracking and alerts
- [ ] Smart reordering based on purchase history
- [ ] Voice input for adding items
- [ ] Apple Watch / Wear OS companion app
- [ ] Integration with meal planning for auto-list generation

## License

Copyright (C) 2025 RGH Software
Licensed under AGPL-3.0

---

## Next Steps

1. Implement backend Go code (models, repository, service, handlers)
2. Implement Flutter UI (screens, widgets, providers)
3. Add image upload/processing
4. Test household sharing
5. Test organized shopping flow
6. Add online ordering API stubs

This feature set significantly reduces cognitive load for ADHD users by making shopping and pantry management visual, organized, and shareable.
