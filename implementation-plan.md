# Self-Hosted Meal Planning Application - Implementation Plan

**Version:** 1.0  
**Target Audience:** Claude Code / AI Agents  
**License:** AGPL-3.0  
**Tech Stack:** Flutter + Go + Modular Database + AI Integration

---

## Executive Summary

This document provides a complete implementation plan for a self-hosted, cross-platform meal planning application with AI-powered features. The architecture emphasizes modularity, allowing developers to contribute database and authentication integrations while maintaining a working default implementation.

### Core Requirements
- **Platforms:** iOS, Android, Web, Desktop (Flutter)
- **Backend:** Go REST/GraphQL API
- **Database:** Modular (Default: PostgreSQL with SQLite option, Supabase integration available)
- **Authentication:** Modular (Default: Username/Password with Argon2, OAuth stretch goal, Supabase auth available)
- **AI Integration:** Multi-provider (Ollama, OpenAI, Google Gemini, Anthropic Claude)
- **Deployment:** Docker Compose, single binary option
- **Budget Target:** $10-15/month for self-hosted deployment
- **License:** AGPL-3.0

---

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Client                          │
│  ┌──────────┬──────────┬──────────┬──────────┬──────────┐ │
│  │  Meal    │  Recipe  │  Pantry  │ Shopping │ Nutrition│ │
│  │ Planning │  Manager │ Inventory│   List   │ Tracking │ │
│  └──────────┴──────────┴──────────┴──────────┴──────────┘ │
│           │                                                 │
│  ┌────────▼──────────────────────────────────────────────┐ │
│  │      Offline-First Data Layer (SQLite/Hive)           │ │
│  └────────┬──────────────────────────────────────────────┘ │
└───────────┼─────────────────────────────────────────────────┘
            │ HTTPS/GraphQL/WebSocket
┌───────────▼─────────────────────────────────────────────────┐
│                    Reverse Proxy (Caddy)                    │
└───────────┬─────────────────────────────────────────────────┘
            │
┌───────────▼─────────────────────────────────────────────────┐
│                      Go Backend API                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Auth Middleware (Modular)                │  │
│  │     ┌──────────────┬──────────────┬──────────────┐   │  │
│  │     │   Argon2     │   OAuth2     │  Supabase    │   │  │
│  │     │   Default    │   Stretch    │   Plugin     │   │  │
│  │     └──────────────┴──────────────┴──────────────┘   │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           Database Abstraction Layer                  │  │
│  │     ┌──────────────┬──────────────┬──────────────┐   │  │
│  │     │  PostgreSQL  │    SQLite    │  Supabase    │   │  │
│  │     │   Default    │   Embedded   │   Plugin     │   │  │
│  │     └──────────────┴──────────────┴──────────────┘   │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              AI Integration Layer                     │  │
│  │  ┌────────────┬────────────┬────────────┬─────────┐  │  │
│  │  │   Ollama   │   OpenAI   │   Gemini   │ Claude  │  │  │
│  │  │   (Local)  │   (API)    │   (API)    │  (API)  │  │  │
│  │  └────────────┴────────────┴────────────┴─────────┘  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
            │
┌───────────▼─────────────────────────────────────────────────┐
│               Database (PostgreSQL/SQLite)                  │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│              External Services (Optional)                   │
│  ┌──────────────┬──────────────┬──────────────────────┐    │
│  │ USDA FoodDB  │ Open Food    │  Recipe Scrapers     │    │
│  │   (Nutrition)│   Facts      │  (Import)            │    │
│  └──────────────┴──────────────┴──────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
meal-planner/
├── backend/                           # Go backend service
│   ├── cmd/
│   │   └── server/
│   │       └── main.go               # Application entrypoint
│   ├── internal/
│   │   ├── config/                   # Configuration management
│   │   │   ├── config.go
│   │   │   └── env.go
│   │   ├── database/                 # Database abstraction layer
│   │   │   ├── interface.go         # Database interface
│   │   │   ├── postgres/            # PostgreSQL implementation
│   │   │   │   ├── postgres.go
│   │   │   │   ├── migrations/
│   │   │   │   └── queries/
│   │   │   ├── sqlite/              # SQLite implementation
│   │   │   │   ├── sqlite.go
│   │   │   │   └── migrations/
│   │   │   └── supabase/            # Supabase plugin
│   │   │       ├── supabase.go
│   │   │       └── README.md
│   │   ├── auth/                    # Authentication abstraction
│   │   │   ├── interface.go         # Auth interface
│   │   │   ├── argon2/              # Default argon2 implementation
│   │   │   │   ├── argon2.go
│   │   │   │   ├── password.go
│   │   │   │   └── jwt.go
│   │   │   ├── oauth/               # OAuth2 implementation (stretch)
│   │   │   │   ├── oauth.go
│   │   │   │   ├── providers/
│   │   │   │   └── README.md
│   │   │   └── supabase/            # Supabase auth plugin
│   │   │       ├── supabase.go
│   │   │       └── README.md
│   │   ├── ai/                      # AI integration layer
│   │   │   ├── interface.go         # AI provider interface
│   │   │   ├── ollama/              # Local Ollama integration
│   │   │   │   ├── ollama.go
│   │   │   │   ├── embeddings.go
│   │   │   │   └── completion.go
│   │   │   ├── openai/              # OpenAI integration
│   │   │   │   ├── openai.go
│   │   │   │   └── embeddings.go
│   │   │   ├── gemini/              # Google Gemini integration
│   │   │   │   ├── gemini.go
│   │   │   │   └── embeddings.go
│   │   │   └── claude/              # Anthropic Claude integration
│   │   │       ├── claude.go
│   │   │       └── embeddings.go    # Separate embeddings model
│   │   ├── features/                # Business logic by feature
│   │   │   ├── meal_planning/
│   │   │   │   ├── handler.go       # HTTP handlers
│   │   │   │   ├── service.go       # Business logic
│   │   │   │   ├── repository.go    # Database operations
│   │   │   │   └── models.go        # Domain models
│   │   │   ├── recipes/
│   │   │   │   ├── handler.go
│   │   │   │   ├── service.go
│   │   │   │   ├── repository.go
│   │   │   │   ├── scraper.go       # Recipe URL import
│   │   │   │   └── models.go
│   │   │   ├── nutrition/
│   │   │   │   ├── handler.go
│   │   │   │   ├── service.go
│   │   │   │   ├── repository.go
│   │   │   │   ├── usda_client.go   # USDA API integration
│   │   │   │   └── models.go
│   │   │   ├── pantry/
│   │   │   │   ├── handler.go
│   │   │   │   ├── service.go
│   │   │   │   ├── repository.go
│   │   │   │   └── models.go
│   │   │   └── shopping_list/
│   │   │       ├── handler.go
│   │   │       ├── service.go
│   │   │       ├── repository.go
│   │   │       └── models.go
│   │   ├── middleware/              # HTTP middleware
│   │   │   ├── auth.go
│   │   │   ├── cors.go
│   │   │   ├── logging.go
│   │   │   └── ratelimit.go
│   │   ├── api/                     # API layer
│   │   │   ├── rest/                # REST endpoints
│   │   │   │   └── router.go
│   │   │   └── graphql/             # GraphQL schema (optional)
│   │   │       ├── schema.graphql
│   │   │       └── resolvers.go
│   │   └── storage/                 # File storage
│   │       ├── interface.go
│   │       ├── local.go
│   │       └── s3.go                # Optional S3 compatibility
│   ├── pkg/                         # Reusable packages
│   │   ├── logger/
│   │   ├── validator/
│   │   └── utils/
│   ├── scripts/                     # Utility scripts
│   │   ├── migrate.sh
│   │   └── seed.sh
│   ├── tests/
│   │   ├── unit/
│   │   ├── integration/
│   │   └── e2e/
│   ├── go.mod
│   ├── go.sum
│   ├── Dockerfile
│   ├── Dockerfile.dev
│   └── README.md
│
├── app/                              # Flutter application
│   ├── lib/
│   │   ├── src/
│   │   │   ├── core/
│   │   │   │   ├── constants/
│   │   │   │   │   ├── api_constants.dart
│   │   │   │   │   ├── storage_keys.dart
│   │   │   │   │   └── app_constants.dart
│   │   │   │   ├── config/
│   │   │   │   │   ├── app_config.dart
│   │   │   │   │   └── env_config.dart
│   │   │   │   ├── network/
│   │   │   │   │   ├── api_client.dart
│   │   │   │   │   ├── graphql_client.dart
│   │   │   │   │   └── interceptors.dart
│   │   │   │   ├── database/               # Local database
│   │   │   │   │   ├── app_database.dart   # Drift/SQLite
│   │   │   │   │   ├── tables.dart
│   │   │   │   │   └── daos/
│   │   │   │   ├── storage/
│   │   │   │   │   ├── secure_storage.dart
│   │   │   │   │   └── preferences.dart
│   │   │   │   ├── sync/                   # Offline-first sync
│   │   │   │   │   ├── sync_service.dart
│   │   │   │   │   ├── conflict_resolver.dart
│   │   │   │   │   └── sync_queue.dart
│   │   │   │   ├── error/
│   │   │   │   │   ├── exceptions.dart
│   │   │   │   │   └── error_handler.dart
│   │   │   │   └── utils/
│   │   │   │       ├── date_utils.dart
│   │   │   │       ├── validators.dart
│   │   │   │       └── extensions.dart
│   │   │   └── features/
│   │   │       ├── auth/
│   │   │       │   ├── data/
│   │   │       │   │   ├── datasources/
│   │   │       │   │   │   ├── auth_local_datasource.dart
│   │   │       │   │   │   └── auth_remote_datasource.dart
│   │   │       │   │   ├── models/
│   │   │       │   │   │   └── user_model.dart
│   │   │       │   │   └── repositories/
│   │   │       │   │       └── auth_repository_impl.dart
│   │   │       │   ├── domain/
│   │   │       │   │   ├── entities/
│   │   │       │   │   │   └── user.dart
│   │   │       │   │   ├── repositories/
│   │   │       │   │   │   └── auth_repository.dart
│   │   │       │   │   └── usecases/
│   │   │       │   │       ├── login.dart
│   │   │       │   │       ├── logout.dart
│   │   │       │   │       └── register.dart
│   │   │       │   └── presentation/
│   │   │       │       ├── providers/
│   │   │       │       │   └── auth_provider.dart
│   │   │       │       ├── pages/
│   │   │       │       │   ├── login_page.dart
│   │   │       │       │   └── register_page.dart
│   │   │       │       └── widgets/
│   │   │       ├── meal_planning/
│   │   │       │   ├── data/
│   │   │       │   ├── domain/
│   │   │       │   └── presentation/
│   │   │       ├── recipes/
│   │   │       │   ├── data/
│   │   │       │   ├── domain/
│   │   │       │   └── presentation/
│   │   │       ├── nutrition/
│   │   │       │   ├── data/
│   │   │       │   ├── domain/
│   │   │       │   └── presentation/
│   │   │       ├── pantry/
│   │   │       │   ├── data/
│   │   │       │   ├── domain/
│   │   │       │   └── presentation/
│   │   │       └── shopping_list/
│   │   │           ├── data/
│   │   │           ├── domain/
│   │   │           └── presentation/
│   │   ├── app.dart
│   │   └── main.dart
│   ├── test/
│   │   ├── unit/
│   │   ├── widget/
│   │   └── integration/
│   ├── assets/
│   │   ├── images/
│   │   └── icons/
│   ├── pubspec.yaml
│   ├── analysis_options.yaml
│   └── README.md
│
├── deployment/                       # Deployment configurations
│   ├── docker/
│   │   ├── docker-compose.yml       # Main compose file
│   │   ├── docker-compose.dev.yml   # Development overrides
│   │   ├── docker-compose.test.yml  # Testing environment
│   │   └── .env.example
│   ├── kubernetes/                  # K8s manifests (optional)
│   │   ├── base/
│   │   └── overlays/
│   ├── caddy/
│   │   └── Caddyfile
│   └── scripts/
│       ├── backup.sh
│       ├── restore.sh
│       └── health_check.sh
│
├── docs/                            # Documentation
│   ├── architecture/
│   │   ├── database_abstraction.md
│   │   ├── auth_abstraction.md
│   │   └── ai_integration.md
│   ├── api/
│   │   ├── rest_api.md
│   │   └── graphql_schema.md
│   ├── deployment/
│   │   ├── docker_deployment.md
│   │   ├── vps_setup.md
│   │   └── self_hosting.md
│   ├── development/
│   │   ├── getting_started.md
│   │   ├── contributing.md
│   │   └── plugin_development.md
│   └── user_guide/
│       └── user_manual.md
│
├── .github/                         # CI/CD workflows
│   └── workflows/
│       ├── backend_ci.yml
│       ├── frontend_ci.yml
│       ├── integration_tests.yml
│       └── release.yml
│
├── LICENSE                          # AGPL-3.0
├── README.md
└── CONTRIBUTING.md
```

---

## Database Abstraction Layer

### Interface Definition

The database layer is abstracted through a Go interface, allowing multiple implementations.

```go
// internal/database/interface.go
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

// RecipeFilter for querying recipes
type RecipeFilter struct {
    UserID     string
    Categories []string
    Tags       []string
    MinRating  *float64
    MaxPrepTime *int
    Limit      int
    Offset     int
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
    UserID      string
    Categories  []string
    ExpiryBefore *time.Time
    Limit       int
    Offset      int
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
```

### PostgreSQL Implementation

```go
// internal/database/postgres/postgres.go
package postgres

import (
    "context"
    "database/sql"
    "fmt"
    
    "github.com/jackc/pgx/v5/pgxpool"
    _ "github.com/jackc/pgx/v5/stdlib"
    "github.com/yourusername/meal-planner/internal/database"
)

type PostgresDB struct {
    pool *pgxpool.Pool
}

func NewPostgresDB(connString string) (*PostgresDB, error) {
    config, err := pgxpool.ParseConfig(connString)
    if err != nil {
        return nil, fmt.Errorf("unable to parse config: %w", err)
    }
    
    // Configure connection pool
    config.MaxConns = 25
    config.MinConns = 5
    
    pool, err := pgxpool.NewWithConfig(context.Background(), config)
    if err != nil {
        return nil, fmt.Errorf("unable to create connection pool: %w", err)
    }
    
    return &PostgresDB{pool: pool}, nil
}

func (db *PostgresDB) Connect(ctx context.Context) error {
    return db.pool.Ping(ctx)
}

func (db *PostgresDB) Close() error {
    db.pool.Close()
    return nil
}

func (db *PostgresDB) Health(ctx context.Context) error {
    return db.pool.Ping(ctx)
}

func (db *PostgresDB) Migrate(ctx context.Context) error {
    // Run migrations using golang-migrate or embedded SQL
    return runMigrations(ctx, db.pool)
}

// Implement all other interface methods...
```

### SQLite Implementation

```go
// internal/database/sqlite/sqlite.go
package sqlite

import (
    "context"
    "database/sql"
    "fmt"
    
    _ "github.com/mattn/go-sqlite3"
    "github.com/yourusername/meal-planner/internal/database"
)

type SQLiteDB struct {
    db *sql.DB
}

func NewSQLiteDB(filepath string) (*SQLiteDB, error) {
    db, err := sql.Open("sqlite3", filepath)
    if err != nil {
        return nil, fmt.Errorf("unable to open database: %w", err)
    }
    
    // Enable foreign keys
    if _, err := db.Exec("PRAGMA foreign_keys = ON"); err != nil {
        return nil, fmt.Errorf("unable to enable foreign keys: %w", err)
    }
    
    return &SQLiteDB{db: db}, nil
}

func (db *SQLiteDB) Connect(ctx context.Context) error {
    return db.db.PingContext(ctx)
}

// Implement all other interface methods...
```

### Supabase Plugin

```go
// internal/database/supabase/supabase.go
package supabase

import (
    "context"
    "fmt"
    
    supabase "github.com/supabase-community/supabase-go"
    "github.com/yourusername/meal-planner/internal/database"
)

type SupabaseDB struct {
    client *supabase.Client
}

func NewSupabaseDB(url, key string) (*SupabaseDB, error) {
    client, err := supabase.NewClient(url, key, nil)
    if err != nil {
        return nil, fmt.Errorf("unable to create supabase client: %w", err)
    }
    
    return &SupabaseDB{client: client}, nil
}

// Implement all interface methods using Supabase client...
```

### Database Factory

```go
// internal/database/factory.go
package database

import (
    "fmt"
    
    "github.com/yourusername/meal-planner/internal/config"
    "github.com/yourusername/meal-planner/internal/database/postgres"
    "github.com/yourusername/meal-planner/internal/database/sqlite"
    "github.com/yourusername/meal-planner/internal/database/supabase"
)

func NewDatabase(cfg *config.Config) (Database, error) {
    switch cfg.Database.Type {
    case "postgres":
        return postgres.NewPostgresDB(cfg.Database.ConnectionString)
    case "sqlite":
        return sqlite.NewSQLiteDB(cfg.Database.FilePath)
    case "supabase":
        return supabase.NewSupabaseDB(cfg.Database.SupabaseURL, cfg.Database.SupabaseKey)
    default:
        return nil, fmt.Errorf("unsupported database type: %s", cfg.Database.Type)
    }
}
```

---

## Authentication Abstraction Layer

### Interface Definition

```go
// internal/auth/interface.go
package auth

import (
    "context"
    "time"
)

// AuthProvider defines the contract for authentication implementations
type AuthProvider interface {
    // Password-based authentication
    Register(ctx context.Context, req RegisterRequest) (*User, error)
    Login(ctx context.Context, req LoginRequest) (*AuthResponse, error)
    Logout(ctx context.Context, token string) error
    
    // Token management
    GenerateToken(ctx context.Context, user *User) (string, error)
    ValidateToken(ctx context.Context, token string) (*User, error)
    RefreshToken(ctx context.Context, refreshToken string) (*AuthResponse, error)
    
    // Password management
    ChangePassword(ctx context.Context, userID string, oldPassword, newPassword string) error
    ResetPassword(ctx context.Context, email string) error
    ConfirmPasswordReset(ctx context.Context, token, newPassword string) error
    
    // User management
    GetUser(ctx context.Context, userID string) (*User, error)
    UpdateUser(ctx context.Context, user *User) error
    DeleteUser(ctx context.Context, userID string) error
    
    // Session management
    InvalidateAllSessions(ctx context.Context, userID string) error
}

// OAuthProvider defines OAuth-specific methods (stretch goal)
type OAuthProvider interface {
    AuthProvider
    
    // OAuth flow
    GetAuthorizationURL(ctx context.Context, state string) (string, error)
    ExchangeCode(ctx context.Context, code string) (*AuthResponse, error)
    
    // Provider-specific
    GetProviderName() string
}

type RegisterRequest struct {
    Email           string
    Password        string
    FullName        string
    AcceptedTerms   bool
}

type LoginRequest struct {
    Email    string
    Password string
}

type AuthResponse struct {
    AccessToken  string
    RefreshToken string
    ExpiresAt    time.Time
    User         *User
}

type User struct {
    ID           string
    Email        string
    FullName     string
    PasswordHash string
    CreatedAt    time.Time
    UpdatedAt    time.Time
    LastLoginAt  *time.Time
}
```

### Argon2 Implementation (Default)

```go
// internal/auth/argon2/argon2.go
package argon2

import (
    "context"
    "crypto/rand"
    "crypto/subtle"
    "encoding/base64"
    "errors"
    "fmt"
    "strings"
    "time"
    
    "golang.org/x/crypto/argon2"
    "github.com/golang-jwt/jwt/v5"
    "github.com/yourusername/meal-planner/internal/auth"
    "github.com/yourusername/meal-planner/internal/database"
)

type Argon2Provider struct {
    db        database.Database
    jwtSecret []byte
    
    // Argon2 parameters
    memory      uint32
    iterations  uint32
    parallelism uint8
    saltLength  uint32
    keyLength   uint32
}

func NewArgon2Provider(db database.Database, jwtSecret string) *Argon2Provider {
    return &Argon2Provider{
        db:          db,
        jwtSecret:   []byte(jwtSecret),
        memory:      64 * 1024, // 64 MB
        iterations:  3,
        parallelism: 2,
        saltLength:  16,
        keyLength:   32,
    }
}

func (p *Argon2Provider) Register(ctx context.Context, req auth.RegisterRequest) (*auth.User, error) {
    // Validate input
    if err := validateEmail(req.Email); err != nil {
        return nil, err
    }
    if err := validatePassword(req.Password); err != nil {
        return nil, err
    }
    
    // Check if user exists
    existing, _ := p.db.GetUserByEmail(ctx, req.Email)
    if existing != nil {
        return nil, errors.New("user already exists")
    }
    
    // Hash password
    passwordHash, err := p.hashPassword(req.Password)
    if err != nil {
        return nil, fmt.Errorf("failed to hash password: %w", err)
    }
    
    // Create user
    user := &database.User{
        Email:        req.Email,
        PasswordHash: passwordHash,
        FullName:     req.FullName,
        CreatedAt:    time.Now(),
        UpdatedAt:    time.Now(),
    }
    
    if err := p.db.CreateUser(ctx, user); err != nil {
        return nil, fmt.Errorf("failed to create user: %w", err)
    }
    
    return &auth.User{
        ID:        user.ID,
        Email:     user.Email,
        FullName:  user.FullName,
        CreatedAt: user.CreatedAt,
        UpdatedAt: user.UpdatedAt,
    }, nil
}

func (p *Argon2Provider) Login(ctx context.Context, req auth.LoginRequest) (*auth.AuthResponse, error) {
    // Get user
    user, err := p.db.GetUserByEmail(ctx, req.Email)
    if err != nil {
        return nil, errors.New("invalid credentials")
    }
    
    // Verify password
    valid, err := p.verifyPassword(req.Password, user.PasswordHash)
    if err != nil || !valid {
        return nil, errors.New("invalid credentials")
    }
    
    // Update last login
    now := time.Now()
    user.LastLoginAt = &now
    p.db.UpdateUser(ctx, user)
    
    // Generate tokens
    accessToken, err := p.generateAccessToken(user)
    if err != nil {
        return nil, err
    }
    
    refreshToken, err := p.generateRefreshToken(user)
    if err != nil {
        return nil, err
    }
    
    return &auth.AuthResponse{
        AccessToken:  accessToken,
        RefreshToken: refreshToken,
        ExpiresAt:    time.Now().Add(15 * time.Minute),
        User: &auth.User{
            ID:        user.ID,
            Email:     user.Email,
            FullName:  user.FullName,
            CreatedAt: user.CreatedAt,
            UpdatedAt: user.UpdatedAt,
        },
    }, nil
}

func (p *Argon2Provider) hashPassword(password string) (string, error) {
    // Generate random salt
    salt := make([]byte, p.saltLength)
    if _, err := rand.Read(salt); err != nil {
        return "", err
    }
    
    // Hash password
    hash := argon2.IDKey(
        []byte(password),
        salt,
        p.iterations,
        p.memory,
        p.parallelism,
        p.keyLength,
    )
    
    // Encode as: $argon2id$v=19$m=65536,t=3,p=2$<salt>$<hash>
    b64Salt := base64.RawStdEncoding.EncodeToString(salt)
    b64Hash := base64.RawStdEncoding.EncodeToString(hash)
    
    return fmt.Sprintf(
        "$argon2id$v=%d$m=%d,t=%d,p=%d$%s$%s",
        argon2.Version,
        p.memory,
        p.iterations,
        p.parallelism,
        b64Salt,
        b64Hash,
    ), nil
}

func (p *Argon2Provider) verifyPassword(password, encodedHash string) (bool, error) {
    // Parse the encoded hash
    parts := strings.Split(encodedHash, "$")
    if len(parts) != 6 {
        return false, errors.New("invalid hash format")
    }
    
    var memory, iterations uint32
    var parallelism uint8
    _, err := fmt.Sscanf(parts[3], "m=%d,t=%d,p=%d", &memory, &iterations, &parallelism)
    if err != nil {
        return false, err
    }
    
    salt, err := base64.RawStdEncoding.DecodeString(parts[4])
    if err != nil {
        return false, err
    }
    
    hash, err := base64.RawStdEncoding.DecodeString(parts[5])
    if err != nil {
        return false, err
    }
    
    // Hash the input password with the same parameters
    comparisonHash := argon2.IDKey(
        []byte(password),
        salt,
        iterations,
        memory,
        parallelism,
        uint32(len(hash)),
    )
    
    // Constant-time comparison
    return subtle.ConstantTimeCompare(hash, comparisonHash) == 1, nil
}

func (p *Argon2Provider) generateAccessToken(user *database.User) (string, error) {
    claims := jwt.MapClaims{
        "sub": user.ID,
        "email": user.Email,
        "exp": time.Now().Add(15 * time.Minute).Unix(),
        "iat": time.Now().Unix(),
    }
    
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    return token.SignedString(p.jwtSecret)
}

func (p *Argon2Provider) generateRefreshToken(user *database.User) (string, error) {
    claims := jwt.MapClaims{
        "sub": user.ID,
        "type": "refresh",
        "exp": time.Now().Add(7 * 24 * time.Hour).Unix(),
        "iat": time.Now().Unix(),
    }
    
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    return token.SignedString(p.jwtSecret)
}

// Implement other interface methods...
```

### Supabase Auth Plugin

```go
// internal/auth/supabase/supabase.go
package supabase

import (
    "context"
    
    supabase "github.com/supabase-community/supabase-go"
    "github.com/yourusername/meal-planner/internal/auth"
)

type SupabaseAuthProvider struct {
    client *supabase.Client
}

func NewSupabaseAuthProvider(url, key string) (*SupabaseAuthProvider, error) {
    client, err := supabase.NewClient(url, key, nil)
    if err != nil {
        return nil, err
    }
    
    return &SupabaseAuthProvider{client: client}, nil
}

func (p *SupabaseAuthProvider) Register(ctx context.Context, req auth.RegisterRequest) (*auth.User, error) {
    // Use Supabase auth API
    resp, err := p.client.Auth.SignUp(ctx, supabase.SignUpRequest{
        Email:    req.Email,
        Password: req.Password,
        Data: map[string]interface{}{
            "full_name": req.FullName,
        },
    })
    if err != nil {
        return nil, err
    }
    
    return &auth.User{
        ID:       resp.User.ID.String(),
        Email:    resp.User.Email,
        FullName: req.FullName,
    }, nil
}

// Implement other interface methods...
```

---

## AI Integration Layer

### Interface Definition

```go
// internal/ai/interface.go
package ai

import (
    "context"
)

// AIProvider defines the contract for AI service implementations
type AIProvider interface {
    // Completions
    GenerateCompletion(ctx context.Context, req CompletionRequest) (*CompletionResponse, error)
    StreamCompletion(ctx context.Context, req CompletionRequest) (<-chan CompletionChunk, error)
    
    // Embeddings
    GenerateEmbeddings(ctx context.Context, texts []string) ([][]float64, error)
    
    // Provider info
    GetProviderName() string
    GetModelInfo() ModelInfo
    
    // Health check
    Health(ctx context.Context) error
}

type CompletionRequest struct {
    Prompt      string
    SystemPrompt string
    MaxTokens   int
    Temperature float64
    TopP        float64
}

type CompletionResponse struct {
    Text         string
    FinishReason string
    TokensUsed   int
}

type CompletionChunk struct {
    Text  string
    Done  bool
    Error error
}

type ModelInfo struct {
    Name            string
    ContextWindow   int
    MaxOutputTokens int
    SupportsStreaming bool
}

// Recipe-specific AI functions
type RecipeAI interface {
    ExtractRecipeFromImage(ctx context.Context, imageData []byte) (*RecipeExtraction, error)
    ParseRecipeFromText(ctx context.Context, text string) (*RecipeExtraction, error)
    GenerateRecipeVariations(ctx context.Context, baseRecipe *Recipe) ([]*Recipe, error)
    SuggestRecipeSubstitutions(ctx context.Context, recipe *Recipe, missingIngredients []string) (*SubstitutionSuggestion, error)
}

// Meal planning AI functions
type MealPlanningAI interface {
    GenerateMealPlan(ctx context.Context, req MealPlanRequest) (*MealPlanSuggestion, error)
    OptimizeMealPlan(ctx context.Context, plan *MealPlan, constraints Constraints) (*MealPlan, error)
    SuggestShoppingList(ctx context.Context, mealPlan *MealPlan, pantryItems []*PantryItem) (*ShoppingList, error)
}

// Nutrition AI functions
type NutritionAI interface {
    EstimateNutrition(ctx context.Context, foodDescription string, quantity float64, unit string) (*NutritionEstimate, error)
    AnalyzeDiet(ctx context.Context, nutritionLogs []*NutritionLog) (*DietAnalysis, error)
}

type RecipeExtraction struct {
    Title        string
    Ingredients  []Ingredient
    Instructions []string
    PrepTime     int
    CookTime     int
    Servings     int
    Nutrition    *NutritionInfo
    Confidence   float64
}

type MealPlanRequest struct {
    UserID          string
    StartDate       time.Time
    EndDate         time.Time
    DietaryRestrictions []string
    CalorieTarget   int
    PreferredCuisines []string
    AvoidIngredients []string
}

type MealPlanSuggestion struct {
    Meals       []*MealSuggestion
    TotalCalories int
    TotalCost   float64
    Reasoning   string
}
```

### Ollama Implementation (Local AI)

```go
// internal/ai/ollama/ollama.go
package ollama

import (
    "bytes"
    "context"
    "encoding/json"
    "fmt"
    "io"
    "net/http"
    
    "github.com/yourusername/meal-planner/internal/ai"
)

type OllamaProvider struct {
    baseURL string
    model   string
    client  *http.Client
}

func NewOllamaProvider(baseURL, model string) *OllamaProvider {
    return &OllamaProvider{
        baseURL: baseURL,
        model:   model,
        client:  &http.Client{},
    }
}

func (p *OllamaProvider) GenerateCompletion(ctx context.Context, req ai.CompletionRequest) (*ai.CompletionResponse, error) {
    requestBody := map[string]interface{}{
        "model":  p.model,
        "prompt": req.Prompt,
        "stream": false,
        "options": map[string]interface{}{
            "temperature": req.Temperature,
            "top_p":       req.TopP,
            "num_predict": req.MaxTokens,
        },
    }
    
    if req.SystemPrompt != "" {
        requestBody["system"] = req.SystemPrompt
    }
    
    jsonData, err := json.Marshal(requestBody)
    if err != nil {
        return nil, err
    }
    
    httpReq, err := http.NewRequestWithContext(ctx, "POST", p.baseURL+"/api/generate", bytes.NewBuffer(jsonData))
    if err != nil {
        return nil, err
    }
    httpReq.Header.Set("Content-Type", "application/json")
    
    resp, err := p.client.Do(httpReq)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    
    if resp.StatusCode != http.StatusOK {
        body, _ := io.ReadAll(resp.Body)
        return nil, fmt.Errorf("ollama request failed: %s", string(body))
    }
    
    var result struct {
        Response string `json:"response"`
        Done     bool   `json:"done"`
    }
    
    if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
        return nil, err
    }
    
    return &ai.CompletionResponse{
        Text:         result.Response,
        FinishReason: "stop",
        TokensUsed:   0, // Ollama doesn't return token count easily
    }, nil
}

func (p *OllamaProvider) GenerateEmbeddings(ctx context.Context, texts []string) ([][]float64, error) {
    embeddings := make([][]float64, len(texts))
    
    for i, text := range texts {
        requestBody := map[string]interface{}{
            "model":  p.model,
            "prompt": text,
        }
        
        jsonData, err := json.Marshal(requestBody)
        if err != nil {
            return nil, err
        }
        
        httpReq, err := http.NewRequestWithContext(ctx, "POST", p.baseURL+"/api/embeddings", bytes.NewBuffer(jsonData))
        if err != nil {
            return nil, err
        }
        httpReq.Header.Set("Content-Type", "application/json")
        
        resp, err := p.client.Do(httpReq)
        if err != nil {
            return nil, err
        }
        defer resp.Body.Close()
        
        var result struct {
            Embedding []float64 `json:"embedding"`
        }
        
        if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
            return nil, err
        }
        
        embeddings[i] = result.Embedding
    }
    
    return embeddings, nil
}

func (p *OllamaProvider) GetProviderName() string {
    return "ollama"
}

func (p *OllamaProvider) GetModelInfo() ai.ModelInfo {
    return ai.ModelInfo{
        Name:              p.model,
        ContextWindow:     4096, // Varies by model
        MaxOutputTokens:   2048,
        SupportsStreaming: true,
    }
}

func (p *OllamaProvider) Health(ctx context.Context) error {
    resp, err := http.Get(p.baseURL + "/api/tags")
    if err != nil {
        return err
    }
    defer resp.Body.Close()
    
    if resp.StatusCode != http.StatusOK {
        return fmt.Errorf("ollama health check failed: status %d", resp.StatusCode)
    }
    
    return nil
}
```

### OpenAI Implementation

```go
// internal/ai/openai/openai.go
package openai

import (
    "context"
    
    "github.com/sashabaranov/go-openai"
    "github.com/yourusername/meal-planner/internal/ai"
)

type OpenAIProvider struct {
    client *openai.Client
    model  string
}

func NewOpenAIProvider(apiKey, model string) *OpenAIProvider {
    return &OpenAIProvider{
        client: openai.NewClient(apiKey),
        model:  model,
    }
}

func (p *OpenAIProvider) GenerateCompletion(ctx context.Context, req ai.CompletionRequest) (*ai.CompletionResponse, error) {
    messages := []openai.ChatCompletionMessage{
        {
            Role:    openai.ChatMessageRoleUser,
            Content: req.Prompt,
        },
    }
    
    if req.SystemPrompt != "" {
        messages = append([]openai.ChatCompletionMessage{
            {
                Role:    openai.ChatMessageRoleSystem,
                Content: req.SystemPrompt,
            },
        }, messages...)
    }
    
    resp, err := p.client.CreateChatCompletion(ctx, openai.ChatCompletionRequest{
        Model:       p.model,
        Messages:    messages,
        MaxTokens:   req.MaxTokens,
        Temperature: float32(req.Temperature),
        TopP:        float32(req.TopP),
    })
    
    if err != nil {
        return nil, err
    }
    
    return &ai.CompletionResponse{
        Text:         resp.Choices[0].Message.Content,
        FinishReason: string(resp.Choices[0].FinishReason),
        TokensUsed:   resp.Usage.TotalTokens,
    }, nil
}

func (p *OpenAIProvider) GenerateEmbeddings(ctx context.Context, texts []string) ([][]float64, error) {
    resp, err := p.client.CreateEmbeddings(ctx, openai.EmbeddingRequest{
        Model: openai.AdaEmbeddingV2,
        Input: texts,
    })
    
    if err != nil {
        return nil, err
    }
    
    embeddings := make([][]float64, len(resp.Data))
    for i, data := range resp.Data {
        embeddings[i] = make([]float64, len(data.Embedding))
        for j, val := range data.Embedding {
            embeddings[i][j] = float64(val)
        }
    }
    
    return embeddings, nil
}

// Implement other interface methods...
```

### Google Gemini Implementation

```go
// internal/ai/gemini/gemini.go
package gemini

import (
    "context"
    
    "google.golang.org/api/option"
    "github.com/google/generative-ai-go/genai"
    "github.com/yourusername/meal-planner/internal/ai"
)

type GeminiProvider struct {
    client *genai.Client
    model  string
}

func NewGeminiProvider(ctx context.Context, apiKey, model string) (*GeminiProvider, error) {
    client, err := genai.NewClient(ctx, option.WithAPIKey(apiKey))
    if err != nil {
        return nil, err
    }
    
    return &GeminiProvider{
        client: client,
        model:  model,
    }, nil
}

func (p *GeminiProvider) GenerateCompletion(ctx context.Context, req ai.CompletionRequest) (*ai.CompletionResponse, error) {
    model := p.client.GenerativeModel(p.model)
    model.SetTemperature(float32(req.Temperature))
    model.SetTopP(float32(req.TopP))
    model.SetMaxOutputTokens(int32(req.MaxTokens))
    
    if req.SystemPrompt != "" {
        model.SystemInstruction = &genai.Content{
            Parts: []genai.Part{genai.Text(req.SystemPrompt)},
        }
    }
    
    resp, err := model.GenerateContent(ctx, genai.Text(req.Prompt))
    if err != nil {
        return nil, err
    }
    
    if len(resp.Candidates) == 0 {
        return nil, fmt.Errorf("no candidates returned")
    }
    
    var text string
    for _, part := range resp.Candidates[0].Content.Parts {
        text += fmt.Sprintf("%v", part)
    }
    
    return &ai.CompletionResponse{
        Text:         text,
        FinishReason: string(resp.Candidates[0].FinishReason),
        TokensUsed:   int(resp.UsageMetadata.TotalTokenCount),
    }, nil
}

func (p *GeminiProvider) GenerateEmbeddings(ctx context.Context, texts []string) ([][]float64, error) {
    model := p.client.EmbeddingModel("embedding-001")
    
    embeddings := make([][]float64, len(texts))
    for i, text := range texts {
        resp, err := model.EmbedContent(ctx, genai.Text(text))
        if err != nil {
            return nil, err
        }
        
        embeddings[i] = make([]float64, len(resp.Embedding.Values))
        for j, val := range resp.Embedding.Values {
            embeddings[i][j] = float64(val)
        }
    }
    
    return embeddings, nil
}

// Implement other interface methods...
```

### Anthropic Claude Implementation

```go
// internal/ai/claude/claude.go
package claude

import (
    "bytes"
    "context"
    "encoding/json"
    "fmt"
    "io"
    "net/http"
    
    "github.com/yourusername/meal-planner/internal/ai"
)

type ClaudeProvider struct {
    apiKey          string
    model           string
    embeddingModel  string // Separate model for embeddings (e.g., Voyage AI)
    client          *http.Client
    embeddingClient *http.Client
}

func NewClaudeProvider(apiKey, model, embeddingAPIKey string) *ClaudeProvider {
    return &ClaudeProvider{
        apiKey:         apiKey,
        model:          model,
        embeddingModel: "voyage-large-2-instruct", // Example embedding model
        client:         &http.Client{},
        embeddingClient: &http.Client{},
    }
}

func (p *ClaudeProvider) GenerateCompletion(ctx context.Context, req ai.CompletionRequest) (*ai.CompletionResponse, error) {
    requestBody := map[string]interface{}{
        "model":      p.model,
        "max_tokens": req.MaxTokens,
        "messages": []map[string]string{
            {
                "role":    "user",
                "content": req.Prompt,
            },
        },
        "temperature": req.Temperature,
        "top_p":       req.TopP,
    }
    
    if req.SystemPrompt != "" {
        requestBody["system"] = req.SystemPrompt
    }
    
    jsonData, err := json.Marshal(requestBody)
    if err != nil {
        return nil, err
    }
    
    httpReq, err := http.NewRequestWithContext(ctx, "POST", "https://api.anthropic.com/v1/messages", bytes.NewBuffer(jsonData))
    if err != nil {
        return nil, err
    }
    
    httpReq.Header.Set("Content-Type", "application/json")
    httpReq.Header.Set("x-api-key", p.apiKey)
    httpReq.Header.Set("anthropic-version", "2023-06-01")
    
    resp, err := p.client.Do(httpReq)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    
    if resp.StatusCode != http.StatusOK {
        body, _ := io.ReadAll(resp.Body)
        return nil, fmt.Errorf("claude request failed: %s", string(body))
    }
    
    var result struct {
        Content []struct {
            Text string `json:"text"`
        } `json:"content"`
        StopReason string `json:"stop_reason"`
        Usage      struct {
            InputTokens  int `json:"input_tokens"`
            OutputTokens int `json:"output_tokens"`
        } `json:"usage"`
    }
    
    if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
        return nil, err
    }
    
    var text string
    for _, content := range result.Content {
        text += content.Text
    }
    
    return &ai.CompletionResponse{
        Text:         text,
        FinishReason: result.StopReason,
        TokensUsed:   result.Usage.InputTokens + result.Usage.OutputTokens,
    }, nil
}

func (p *ClaudeProvider) GenerateEmbeddings(ctx context.Context, texts []string) ([][]float64, error) {
    // Use Voyage AI or another embedding provider
    // Claude doesn't provide embeddings natively
    requestBody := map[string]interface{}{
        "input": texts,
        "model": p.embeddingModel,
    }
    
    jsonData, err := json.Marshal(requestBody)
    if err != nil {
        return nil, err
    }
    
    httpReq, err := http.NewRequestWithContext(ctx, "POST", "https://api.voyageai.com/v1/embeddings", bytes.NewBuffer(jsonData))
    if err != nil {
        return nil, err
    }
    
    httpReq.Header.Set("Content-Type", "application/json")
    httpReq.Header.Set("Authorization", "Bearer "+p.apiKey) // Use separate API key
    
    resp, err := p.embeddingClient.Do(httpReq)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    
    var result struct {
        Data []struct {
            Embedding []float64 `json:"embedding"`
        } `json:"data"`
    }
    
    if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
        return nil, err
    }
    
    embeddings := make([][]float64, len(result.Data))
    for i, data := range result.Data {
        embeddings[i] = data.Embedding
    }
    
    return embeddings, nil
}

// Implement other interface methods...
```

### AI Factory

```go
// internal/ai/factory.go
package ai

import (
    "context"
    "fmt"
    
    "github.com/yourusername/meal-planner/internal/config"
    "github.com/yourusername/meal-planner/internal/ai/ollama"
    "github.com/yourusername/meal-planner/internal/ai/openai"
    "github.com/yourusername/meal-planner/internal/ai/gemini"
    "github.com/yourusername/meal-planner/internal/ai/claude"
)

func NewAIProvider(ctx context.Context, cfg *config.AIConfig) (AIProvider, error) {
    switch cfg.Provider {
    case "ollama":
        return ollama.NewOllamaProvider(cfg.OllamaURL, cfg.Model), nil
    case "openai":
        return openai.NewOpenAIProvider(cfg.APIKey, cfg.Model), nil
    case "gemini":
        return gemini.NewGeminiProvider(ctx, cfg.APIKey, cfg.Model)
    case "claude":
        return claude.NewClaudeProvider(cfg.APIKey, cfg.Model, cfg.EmbeddingAPIKey), nil
    default:
        return nil, fmt.Errorf("unsupported AI provider: %s", cfg.Provider)
    }
}
```

---

## Database Schema

### PostgreSQL Schema

```sql
-- migrations/001_initial_schema.up.sql

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For full-text search

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

CREATE INDEX idx_users_email ON users(email);

-- Households table (for shared meal planning)
CREATE TABLE households (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Household members junction table
CREATE TABLE household_members (
    household_id UUID REFERENCES households(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL DEFAULT 'member', -- 'owner', 'admin', 'member'
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (household_id, user_id)
);

-- Recipes table
CREATE TABLE recipes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    household_id UUID REFERENCES households(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    prep_time_minutes INTEGER,
    cook_time_minutes INTEGER,
    servings INTEGER,
    difficulty VARCHAR(50), -- 'easy', 'medium', 'hard'
    source_url TEXT,
    image_url TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_recipes_user_id ON recipes(user_id);
CREATE INDEX idx_recipes_household_id ON recipes(household_id);
CREATE INDEX idx_recipes_title ON recipes USING gin(title gin_trgm_ops);

-- Recipe categories
CREATE TABLE recipe_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT
);

-- Recipe-category junction table
CREATE TABLE recipe_category_mappings (
    recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
    category_id UUID REFERENCES recipe_categories(id) ON DELETE CASCADE,
    PRIMARY KEY (recipe_id, category_id)
);

-- Recipe tags
CREATE TABLE recipe_tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL
);

-- Recipe-tag junction table
CREATE TABLE recipe_tag_mappings (
    recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
    tag_id UUID REFERENCES recipe_tags(id) ON DELETE CASCADE,
    PRIMARY KEY (recipe_id, tag_id)
);

-- Ingredients table
CREATE TABLE ingredients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) UNIQUE NOT NULL,
    category VARCHAR(100),
    default_unit VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_ingredients_name ON ingredients USING gin(name gin_trgm_ops);

-- Recipe ingredients
CREATE TABLE recipe_ingredients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
    ingredient_id UUID REFERENCES ingredients(id) ON DELETE CASCADE,
    quantity DECIMAL(10, 3),
    unit VARCHAR(50),
    notes TEXT,
    sort_order INTEGER DEFAULT 0
);

-- Recipe instructions
CREATE TABLE recipe_instructions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
    step_number INTEGER NOT NULL,
    instruction TEXT NOT NULL,
    image_url TEXT,
    UNIQUE (recipe_id, step_number)
);

-- Nutrition information
CREATE TABLE nutrition_info (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
    ingredient_id UUID REFERENCES ingredients(id) ON DELETE CASCADE,
    serving_size_grams DECIMAL(10, 2),
    calories DECIMAL(10, 2),
    protein_grams DECIMAL(10, 2),
    carbs_grams DECIMAL(10, 2),
    fat_grams DECIMAL(10, 2),
    fiber_grams DECIMAL(10, 2),
    sugar_grams DECIMAL(10, 2),
    sodium_mg DECIMAL(10, 2),
    cholesterol_mg DECIMAL(10, 2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT one_reference CHECK (
        (recipe_id IS NOT NULL AND ingredient_id IS NULL) OR
        (recipe_id IS NULL AND ingredient_id IS NOT NULL)
    )
);

-- Meal plans
CREATE TABLE meal_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    household_id UUID REFERENCES households(id) ON DELETE SET NULL,
    name VARCHAR(255),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_meal_plans_user_id ON meal_plans(user_id);
CREATE INDEX idx_meal_plans_dates ON meal_plans(start_date, end_date);

-- Meal plan entries
CREATE TABLE meal_plan_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    meal_plan_id UUID REFERENCES meal_plans(id) ON DELETE CASCADE,
    recipe_id UUID REFERENCES recipes(id) ON DELETE SET NULL,
    date DATE NOT NULL,
    meal_type VARCHAR(50) NOT NULL, -- 'breakfast', 'lunch', 'dinner', 'snack'
    servings INTEGER DEFAULT 1,
    notes TEXT,
    completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_meal_plan_entries_plan_id ON meal_plan_entries(meal_plan_id);
CREATE INDEX idx_meal_plan_entries_date ON meal_plan_entries(date);

-- Pantry items
CREATE TABLE pantry_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    household_id UUID REFERENCES households(id) ON DELETE SET NULL,
    ingredient_id UUID REFERENCES ingredients(id) ON DELETE CASCADE,
    quantity DECIMAL(10, 3),
    unit VARCHAR(50),
    location VARCHAR(100), -- 'fridge', 'freezer', 'pantry', etc.
    expiry_date DATE,
    purchase_date DATE,
    barcode VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_pantry_items_user_id ON pantry_items(user_id);
CREATE INDEX idx_pantry_items_household_id ON pantry_items(household_id);
CREATE INDEX idx_pantry_items_expiry ON pantry_items(expiry_date);

-- Shopping lists
CREATE TABLE shopping_lists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    household_id UUID REFERENCES households(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Shopping list items
CREATE TABLE shopping_list_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shopping_list_id UUID REFERENCES shopping_lists(id) ON DELETE CASCADE,
    ingredient_id UUID REFERENCES ingredients(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    quantity DECIMAL(10, 3),
    unit VARCHAR(50),
    category VARCHAR(100),
    checked BOOLEAN DEFAULT FALSE,
    notes TEXT,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_shopping_list_items_list_id ON shopping_list_items(shopping_list_id);

-- Nutrition logs (for tracking actual consumption)
CREATE TABLE nutrition_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    recipe_id UUID REFERENCES recipes(id) ON DELETE SET NULL,
    ingredient_id UUID REFERENCES ingredients(id) ON DELETE SET NULL,
    logged_at TIMESTAMP WITH TIME ZONE NOT NULL,
    meal_type VARCHAR(50), -- 'breakfast', 'lunch', 'dinner', 'snack'
    servings DECIMAL(10, 2),
    calories DECIMAL(10, 2),
    protein_grams DECIMAL(10, 2),
    carbs_grams DECIMAL(10, 2),
    fat_grams DECIMAL(10, 2),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_nutrition_logs_user_id ON nutrition_logs(user_id);
CREATE INDEX idx_nutrition_logs_date ON nutrition_logs(logged_at);

-- User preferences
CREATE TABLE user_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    dietary_restrictions JSONB DEFAULT '[]'::jsonb,
    allergies JSONB DEFAULT '[]'::jsonb,
    favorite_cuisines JSONB DEFAULT '[]'::jsonb,
    disliked_ingredients JSONB DEFAULT '[]'::jsonb,
    daily_calorie_target INTEGER,
    protein_target_grams INTEGER,
    carbs_target_grams INTEGER,
    fat_target_grams INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Recipe ratings
CREATE TABLE recipe_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE (recipe_id, user_id)
);

CREATE INDEX idx_recipe_ratings_recipe_id ON recipe_ratings(recipe_id);

-- Sync metadata (for offline-first sync)
CREATE TABLE sync_metadata (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    entity_type VARCHAR(100) NOT NULL,
    entity_id UUID NOT NULL,
    last_synced_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    UNIQUE (user_id, entity_type, entity_id)
);

CREATE INDEX idx_sync_metadata_user_id ON sync_metadata(user_id);
CREATE INDEX idx_sync_metadata_last_synced ON sync_metadata(last_synced_at);

-- Trigger to update updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_recipes_updated_at BEFORE UPDATE ON recipes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_meal_plans_updated_at BEFORE UPDATE ON meal_plans FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_pantry_items_updated_at BEFORE UPDATE ON pantry_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

---

## Docker Deployment

### Production Docker Compose

```yaml
# deployment/docker/docker-compose.yml
version: '3.9'

services:
  postgres:
    image: postgres:16-alpine
    container_name: meal-planner-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-mealplanner}
      POSTGRES_USER: ${POSTGRES_USER:-mealplanner}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?Database password required}
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d:ro
    networks:
      - meal-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-mealplanner}"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: ../../backend
      dockerfile: Dockerfile
    container_name: meal-planner-api
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      # Database
      DB_TYPE: postgres
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: ${POSTGRES_DB:-mealplanner}
      DB_USER: ${POSTGRES_USER:-mealplanner}
      DB_PASSWORD: ${POSTGRES_PASSWORD:?Database password required}
      DB_SSL_MODE: disable
      
      # Authentication
      AUTH_TYPE: argon2
      JWT_SECRET: ${JWT_SECRET:?JWT secret required}
      JWT_EXPIRY: 15m
      REFRESH_TOKEN_EXPIRY: 168h
      
      # AI Configuration
      AI_PROVIDER: ${AI_PROVIDER:-ollama}
      AI_MODEL: ${AI_MODEL:-llama2}
      OLLAMA_URL: ${OLLAMA_URL:-http://ollama:11434}
      OPENAI_API_KEY: ${OPENAI_API_KEY:-}
      GEMINI_API_KEY: ${GEMINI_API_KEY:-}
      CLAUDE_API_KEY: ${CLAUDE_API_KEY:-}
      
      # Storage
      STORAGE_TYPE: local
      STORAGE_PATH: /app/uploads
      MAX_UPLOAD_SIZE: 10485760 # 10MB
      
      # Server
      SERVER_PORT: 8080
      SERVER_ENV: production
      LOG_LEVEL: info
      
      # CORS
      CORS_ALLOWED_ORIGINS: ${CORS_ALLOWED_ORIGINS:-*}
      
      # External APIs
      USDA_API_KEY: ${USDA_API_KEY:-DEMO_KEY}
      
    volumes:
      - uploads:/app/uploads
    networks:
      - meal-network
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  ollama:
    image: ollama/ollama:latest
    container_name: meal-planner-ollama
    restart: unless-stopped
    volumes:
      - ollama_data:/root/.ollama
    networks:
      - meal-network
    # Uncomment for GPU support
    # deploy:
    #   resources:
    #     reservations:
    #       devices:
    #         - driver: nvidia
    #           count: 1
    #           capabilities: [gpu]

  caddy:
    image: caddy:2-alpine
    container_name: meal-planner-proxy
    restart: unless-stopped
    ports:
      - "${HTTP_PORT:-80}:80"
      - "${HTTPS_PORT:-443}:443"
    environment:
      DOMAIN: ${DOMAIN:-localhost}
    volumes:
      - ../caddy/Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    depends_on:
      - backend
    networks:
      - meal-network

volumes:
  postgres_data:
    driver: local
  uploads:
    driver: local
  ollama_data:
    driver: local
  caddy_data:
    driver: local
  caddy_config:
    driver: local

networks:
  meal-network:
    driver: bridge
```

### Development Docker Compose Override

```yaml
# deployment/docker/docker-compose.dev.yml
version: '3.9'

services:
  postgres:
    ports:
      - "5432:5432"
    environment:
      POSTGRES_PASSWORD: dev_password

  backend:
    build:
      context: ../../backend
      dockerfile: Dockerfile.dev
    volumes:
      - ../../backend:/app
      - /app/vendor
    environment:
      SERVER_ENV: development
      LOG_LEVEL: debug
      DB_PASSWORD: dev_password
      JWT_SECRET: dev_jwt_secret_change_in_production
      AI_PROVIDER: ollama
    ports:
      - "8080:8080"

  ollama:
    ports:
      - "11434:11434"

  # Add pgAdmin for database management
  pgadmin:
    image: dpage/pgadmin4:latest
    container_name: meal-planner-pgadmin
    restart: unless-stopped
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@localhost.local
      PGADMIN_DEFAULT_PASSWORD: admin
    ports:
      - "5050:80"
    networks:
      - meal-network
    depends_on:
      - postgres
```

### Caddyfile

```caddyfile
# deployment/caddy/Caddyfile
{$DOMAIN:localhost} {
    # API endpoints
    handle /api/* {
        reverse_proxy backend:8080
    }
    
    # GraphQL endpoint
    handle /graphql {
        reverse_proxy backend:8080
    }
    
    # Health check
    handle /health {
        reverse_proxy backend:8080
    }
    
    # File uploads
    handle /uploads/* {
        root * /app/uploads
        file_server
    }
    
    # WebSocket support (for future real-time features)
    handle /ws/* {
        reverse_proxy backend:8080
    }
    
    # Default response
    handle {
        respond "Meal Planner API" 200
    }
    
    # Security headers
    header {
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "strict-origin-when-cross-origin"
    }
    
    # Enable compression
    encode gzip zstd
    
    # Logging
    log {
        output file /data/access.log
        format json
    }
}
```

### Environment Variables Template

```bash
# deployment/docker/.env.example

# Database Configuration
POSTGRES_DB=mealplanner
POSTGRES_USER=mealplanner
POSTGRES_PASSWORD=changeme_secure_password

# Authentication
JWT_SECRET=changeme_random_secret_key_min_32_chars
AUTH_TYPE=argon2  # Options: argon2, oauth, supabase

# AI Configuration
AI_PROVIDER=ollama  # Options: ollama, openai, gemini, claude
AI_MODEL=llama2
OLLAMA_URL=http://ollama:11434

# Optional: API keys for cloud AI providers
OPENAI_API_KEY=
GEMINI_API_KEY=
CLAUDE_API_KEY=

# External APIs
USDA_API_KEY=DEMO_KEY  # Get free key from https://fdc.nal.usda.gov/api-key-signup.html

# Server Configuration
HTTP_PORT=80
HTTPS_PORT=443
DOMAIN=meal.example.com
CORS_ALLOWED_ORIGINS=https://meal.example.com

# Supabase (optional plugin)
SUPABASE_URL=
SUPABASE_ANON_KEY=
```

---

## Testing Strategy

### Backend Testing Structure

```go
// backend/tests/unit/auth/argon2_test.go
package auth_test

import (
    "context"
    "testing"
    
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
    "github.com/yourusername/meal-planner/internal/auth/argon2"
    "github.com/yourusername/meal-planner/internal/database/sqlite"
)

func TestArgon2Provider_Register(t *testing.T) {
    // Setup
    db, err := sqlite.NewSQLiteDB(":memory:")
    require.NoError(t, err)
    defer db.Close()
    
    err = db.Migrate(context.Background())
    require.NoError(t, err)
    
    provider := argon2.NewArgon2Provider(db, "test-secret")
    
    tests := []struct {
        name    string
        request auth.RegisterRequest
        wantErr bool
    }{
        {
            name: "valid registration",
            request: auth.RegisterRequest{
                Email:         "test@example.com",
                Password:      "SecurePass123!",
                FullName:      "Test User",
                AcceptedTerms: true,
            },
            wantErr: false,
        },
        {
            name: "weak password",
            request: auth.RegisterRequest{
                Email:    "test2@example.com",
                Password: "weak",
                FullName: "Test User 2",
            },
            wantErr: true,
        },
        {
            name: "invalid email",
            request: auth.RegisterRequest{
                Email:    "invalid-email",
                Password: "SecurePass123!",
                FullName: "Test User 3",
            },
            wantErr: true,
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            user, err := provider.Register(context.Background(), tt.request)
            
            if tt.wantErr {
                assert.Error(t, err)
                assert.Nil(t, user)
            } else {
                assert.NoError(t, err)
                assert.NotNil(t, user)
                assert.Equal(t, tt.request.Email, user.Email)
                assert.NotEmpty(t, user.ID)
            }
        })
    }
}

func TestArgon2Provider_Login(t *testing.T) {
    // Setup
    db, err := sqlite.NewSQLiteDB(":memory:")
    require.NoError(t, err)
    defer db.Close()
    
    err = db.Migrate(context.Background())
    require.NoError(t, err)
    
    provider := argon2.NewArgon2Provider(db, "test-secret")
    
    // Create test user
    _, err = provider.Register(context.Background(), auth.RegisterRequest{
        Email:    "test@example.com",
        Password: "SecurePass123!",
        FullName: "Test User",
    })
    require.NoError(t, err)
    
    tests := []struct {
        name    string
        request auth.LoginRequest
        wantErr bool
    }{
        {
            name: "valid login",
            request: auth.LoginRequest{
                Email:    "test@example.com",
                Password: "SecurePass123!",
            },
            wantErr: false,
        },
        {
            name: "wrong password",
            request: auth.LoginRequest{
                Email:    "test@example.com",
                Password: "WrongPassword",
            },
            wantErr: true,
        },
        {
            name: "non-existent user",
            request: auth.LoginRequest{
                Email:    "nonexistent@example.com",
                Password: "SecurePass123!",
            },
            wantErr: true,
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            response, err := provider.Login(context.Background(), tt.request)
            
            if tt.wantErr {
                assert.Error(t, err)
                assert.Nil(t, response)
            } else {
                assert.NoError(t, err)
                assert.NotNil(t, response)
                assert.NotEmpty(t, response.AccessToken)
                assert.NotEmpty(t, response.RefreshToken)
            }
        })
    }
}
```

### Integration Tests

```go
// backend/tests/integration/recipe_flow_test.go
package integration_test

import (
    "bytes"
    "context"
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"
    
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
    "github.com/yourusername/meal-planner/internal/config"
    "github.com/yourusername/meal-planner/internal/server"
)

func TestRecipeFlow(t *testing.T) {
    // Setup test server
    cfg := config.LoadTestConfig()
    srv, err := server.NewServer(cfg)
    require.NoError(t, err)
    
    testServer := httptest.NewServer(srv.Router)
    defer testServer.Close()
    
    client := &http.Client{}
    
    // Register user
    registerBody := map[string]interface{}{
        "email":    "test@example.com",
        "password": "SecurePass123!",
        "fullName": "Test User",
    }
    registerJSON, _ := json.Marshal(registerBody)
    
    resp, err := client.Post(
        testServer.URL+"/api/auth/register",
        "application/json",
        bytes.NewBuffer(registerJSON),
    )
    require.NoError(t, err)
    assert.Equal(t, http.StatusCreated, resp.StatusCode)
    
    var registerResponse struct {
        AccessToken string `json:"accessToken"`
    }
    json.NewDecoder(resp.Body).Decode(&registerResponse)
    resp.Body.Close()
    
    token := registerResponse.AccessToken
    
    // Create recipe
    recipeBody := map[string]interface{}{
        "title":       "Test Recipe",
        "description": "A test recipe",
        "prepTime":    15,
        "cookTime":    30,
        "servings":    4,
        "ingredients": []map[string]interface{}{
            {
                "name":     "flour",
                "quantity": 2,
                "unit":     "cups",
            },
        },
        "instructions": []string{
            "Mix ingredients",
            "Cook for 30 minutes",
        },
    }
    recipeJSON, _ := json.Marshal(recipeBody)
    
    req, _ := http.NewRequest(
        "POST",
        testServer.URL+"/api/recipes",
        bytes.NewBuffer(recipeJSON),
    )
    req.Header.Set("Authorization", "Bearer "+token)
    req.Header.Set("Content-Type", "application/json")
    
    resp, err = client.Do(req)
    require.NoError(t, err)
    assert.Equal(t, http.StatusCreated, resp.StatusCode)
    
    var createResponse struct {
        ID string `json:"id"`
    }
    json.NewDecoder(resp.Body).Decode(&createResponse)
    resp.Body.Close()
    
    recipeID := createResponse.ID
    assert.NotEmpty(t, recipeID)
    
    // Get recipe
    req, _ = http.NewRequest(
        "GET",
        testServer.URL+"/api/recipes/"+recipeID,
        nil,
    )
    req.Header.Set("Authorization", "Bearer "+token)
    
    resp, err = client.Do(req)
    require.NoError(t, err)
    assert.Equal(t, http.StatusOK, resp.StatusCode)
    
    var getResponse map[string]interface{}
    json.NewDecoder(resp.Body).Decode(&getResponse)
    resp.Body.Close()
    
    assert.Equal(t, "Test Recipe", getResponse["title"])
}
```

### Flutter Testing

```dart
// app/test/unit/meal_planning_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:meal_planner/src/features/meal_planning/domain/repositories/meal_plan_repository.dart';
import 'package:meal_planner/src/features/meal_planning/presentation/providers/meal_planning_provider.dart';

@GenerateMocks([MealPlanRepository])
void main() {
  late MealPlanRepository mockRepository;
  late MealPlanningProvider provider;

  setUp(() {
    mockRepository = MockMealPlanRepository();
    provider = MealPlanningProvider(mockRepository);
  });

  group('MealPlanningProvider', () {
    test('initial state is loading', () {
      expect(provider.state, isA<MealPlanningLoading>());
    });

    test('loadMealPlans success updates state', () async {
      // Arrange
      final mockPlans = [
        MealPlan(id: '1', name: 'Week 1', startDate: DateTime.now()),
      ];
      when(mockRepository.getMealPlans(any))
          .thenAnswer((_) async => Right(mockPlans));

      // Act
      await provider.loadMealPlans();

      // Assert
      expect(provider.state, isA<MealPlanningLoaded>());
      expect((provider.state as MealPlanningLoaded).plans.length, 1);
    });

    test('loadMealPlans failure updates state with error', () async {
      // Arrange
      when(mockRepository.getMealPlans(any))
          .thenAnswer((_) async => Left(ServerFailure('Error')));

      // Act
      await provider.loadMealPlans();

      // Assert
      expect(provider.state, isA<MealPlanningError>());
    });
  });
}
```

### End-to-End Tests

```yaml
# backend/tests/e2e/docker-compose.test.yml
version: '3.9'

services:
  test-db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: test_db
      POSTGRES_USER: test_user
      POSTGRES_PASSWORD: test_pass
    tmpfs:
      - /var/lib/postgresql/data

  test-backend:
    build:
      context: ../../backend
      dockerfile: Dockerfile.test
    depends_on:
      - test-db
    environment:
      DB_TYPE: postgres
      DB_HOST: test-db
      DB_NAME: test_db
      DB_USER: test_user
      DB_PASSWORD: test_pass
      JWT_SECRET: test_secret
    command: go test -v ./tests/e2e/...
```

---

## CI/CD Pipeline

### GitHub Actions - Backend CI

```yaml
# .github/workflows/backend_ci.yml
name: Backend CI

on:
  push:
    branches: [main, develop]
    paths:
      - 'backend/**'
      - '.github/workflows/backend_ci.yml'
  pull_request:
    branches: [main, develop]
    paths:
      - 'backend/**'

jobs:
  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      
      - name: golangci-lint
        uses: golangci/golangci-lint-action@v4
        with:
          version: latest
          working-directory: backend

  test:
    name: Test
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_DB: test_db
          POSTGRES_USER: test_user
          POSTGRES_PASSWORD: test_pass
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      
      - name: Cache Go modules
        uses: actions/cache@v4
        with:
          path: ~/go/pkg/mod
          key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
          restore-keys: |
            ${{ runner.os }}-go-
      
      - name: Download dependencies
        working-directory: backend
        run: go mod download
      
      - name: Run tests
        working-directory: backend
        env:
          DB_TYPE: postgres
          DB_HOST: localhost
          DB_PORT: 5432
          DB_NAME: test_db
          DB_USER: test_user
          DB_PASSWORD: test_pass
          JWT_SECRET: test_secret
        run: |
          go test -v -race -coverprofile=coverage.out -covermode=atomic ./...
      
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v4
        with:
          files: ./backend/coverage.out
          flags: backend

  build:
    name: Build
    runs-on: ubuntu-latest
    needs: [lint, test]
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      
      - name: Build binary
        working-directory: backend
        run: |
          CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app ./cmd/server
      
      - name: Build Docker image
        working-directory: backend
        run: |
          docker build -t meal-planner-backend:${{ github.sha }} .
```

### GitHub Actions - Frontend CI

```yaml
# .github/workflows/frontend_ci.yml
name: Frontend CI

on:
  push:
    branches: [main, develop]
    paths:
      - 'app/**'
      - '.github/workflows/frontend_ci.yml'
  pull_request:
    branches: [main, develop]
    paths:
      - 'app/**'

jobs:
  analyze:
    name: Analyze
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
      
      - name: Get dependencies
        working-directory: app
        run: flutter pub get
      
      - name: Verify formatting
        working-directory: app
        run: dart format --set-exit-if-changed .
      
      - name: Analyze code
        working-directory: app
        run: flutter analyze
      
      - name: Check for outdated dependencies
        working-directory: app
        run: flutter pub outdated

  test:
    name: Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
      
      - name: Get dependencies
        working-directory: app
        run: flutter pub get
      
      - name: Run tests
        working-directory: app
        run: flutter test --coverage
      
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v4
        with:
          files: ./app/coverage/lcov.info
          flags: frontend

  build-android:
    name: Build Android
    runs-on: ubuntu-latest
    needs: [analyze, test]
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'
      
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
      
      - name: Get dependencies
        working-directory: app
        run: flutter pub get
      
      - name: Build APK
        working-directory: app
        run: flutter build apk --release
      
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: android-apk
          path: app/build/app/outputs/flutter-apk/app-release.apk

  build-ios:
    name: Build iOS
    runs-on: macos-latest
    needs: [analyze, test]
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
      
      - name: Get dependencies
        working-directory: app
        run: flutter pub get
      
      - name: Build iOS (no codesign)
        working-directory: app
        run: flutter build ios --release --no-codesign

  build-web:
    name: Build Web
    runs-on: ubuntu-latest
    needs: [analyze, test]
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
      
      - name: Get dependencies
        working-directory: app
        run: flutter pub get
      
      - name: Build web
        working-directory: app
        run: flutter build web --release
      
      - name: Upload web build
        uses: actions/upload-artifact@v4
        with:
          name: web-build
          path: app/build/web/
```

### GitHub Actions - Integration Tests

```yaml
# .github/workflows/integration_tests.yml
name: Integration Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  integration-test:
    name: Integration Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Start services
        run: |
          cd deployment/docker
          cp .env.example .env
          echo "POSTGRES_PASSWORD=test_password" >> .env
          echo "JWT_SECRET=test_jwt_secret_for_ci_pipeline" >> .env
          docker-compose -f docker-compose.yml -f docker-compose.test.yml up -d
      
      - name: Wait for services
        run: |
          timeout 60 bash -c 'until docker-compose -f deployment/docker/docker-compose.yml ps | grep -q "healthy"; do sleep 2; done'
      
      - name: Run integration tests
        run: |
          docker-compose -f deployment/docker/docker-compose.yml exec -T backend go test -v ./tests/integration/...
      
      - name: Stop services
        if: always()
        run: |
          cd deployment/docker
          docker-compose -f docker-compose.yml -f docker-compose.test.yml down -v
```

### GitHub Actions - Release

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  create-release:
    name: Create Release
    runs-on: ubuntu-latest
    outputs:
      upload_url: ${{ steps.create_release.outputs.upload_url }}
    steps:
      - uses: actions/checkout@v4
      
      - name: Create Release
        id: create_release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}
          draft: false
          prerelease: false

  build-and-push-docker:
    name: Build and Push Docker Images
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
      
      - name: Extract version
        id: get_version
        run: echo "VERSION=${GITHUB_REF#refs/tags/v}" >> $GITHUB_OUTPUT
      
      - name: Build and push backend
        uses: docker/build-push-action@v5
        with:
          context: ./backend
          push: true
          tags: |
            yourusername/meal-planner-backend:${{ steps.get_version.outputs.VERSION }}
            yourusername/meal-planner-backend:latest
          cache-from: type=registry,ref=yourusername/meal-planner-backend:buildcache
          cache-to: type=registry,ref=yourusername/meal-planner-backend:buildcache,mode=max

  build-flutter-releases:
    name: Build Flutter Releases
    needs: create-release
    strategy:
      matrix:
        include:
          - os: ubuntu-latest
            target: android
            artifact: app-release.apk
          - os: macos-latest
            target: ios
            artifact: Runner.app
          - os: ubuntu-latest
            target: web
            artifact: web-build
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
      
      - name: Get dependencies
        working-directory: app
        run: flutter pub get
      
      - name: Build ${{ matrix.target }}
        working-directory: app
        run: |
          if [ "${{ matrix.target }}" = "android" ]; then
            flutter build apk --release
          elif [ "${{ matrix.target }}" = "ios" ]; then
            flutter build ios --release --no-codesign
          elif [ "${{ matrix.target }}" = "web" ]; then
            flutter build web --release
          fi
      
      - name: Upload Release Asset
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          upload_url: ${{ needs.create-release.outputs.upload_url }}
          asset_path: app/build/${{ matrix.target }}/${{ matrix.artifact }}
          asset_name: meal-planner-${{ matrix.target }}-${{ github.ref_name }}
          asset_content_type: application/octet-stream
```

---

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-4)

**Week 1: Project Setup**
- Initialize Git repository
- Set up project structure
- Configure CI/CD pipelines
- Set up development environment
- Create initial documentation

**Week 2: Database & Auth Layer**
- Implement database abstraction interface
- Create PostgreSQL implementation
- Create SQLite implementation
- Implement Argon2 authentication
- Write unit tests for auth layer
- Set up database migrations

**Week 3: Basic API Endpoints**
- Implement user registration/login
- Create recipe CRUD endpoints
- Add ingredient management
- Implement basic error handling
- Add logging middleware
- Write integration tests

**Week 4: Flutter Foundation**
- Set up Flutter project structure
- Implement authentication screens
- Create offline-first data layer
- Set up navigation
- Implement state management with Riverpod
- Create reusable UI components

### Phase 2: Core Features (Weeks 5-8)

**Week 5: Recipe Management**
- Complete recipe CRUD in backend
- Add recipe image upload
- Implement recipe search
- Build recipe UI in Flutter
- Add recipe creation/editing screens
- Implement offline recipe caching

**Week 6: Meal Planning**
- Create meal plan data models
- Implement meal planning API
- Build meal plan calendar UI
- Add drag-and-drop meal scheduling
- Implement recurring meal plans
- Add meal plan templates

**Week 7: Nutrition Tracking**
- Integrate USDA FoodData API
- Implement nutrition calculation
- Create nutrition logging API
- Build nutrition tracking UI
- Add daily nutrition dashboard
- Implement nutrition history charts

**Week 8: Pantry & Shopping**
- Create pantry management API
- Implement shopping list generation
- Add barcode scanning (Open Food Facts)
- Build pantry UI
- Create shopping list UI
- Implement list sharing

### Phase 3: AI Integration (Weeks 9-12)

**Week 9: AI Provider Setup**
- Implement AI provider interface
- Create Ollama integration
- Add OpenAI provider
- Implement Gemini provider
- Add Claude provider
- Write AI integration tests

**Week 10: Recipe AI Features**
- Implement recipe extraction from images
- Add recipe URL import
- Create recipe variation generator
- Implement ingredient substitution suggestions
- Build AI-powered recipe search
- Add nutrition estimation

**Week 11: Meal Planning AI**
- Implement AI meal plan generation
- Add dietary preference support
- Create meal plan optimization
- Implement smart shopping list generation
- Add AI recipe recommendations
- Build preference learning

**Week 12: AI Polish & Testing**
- Optimize AI prompts
- Add streaming responses
- Implement response caching
- Create AI fallback mechanisms
- Write comprehensive AI tests
- Add AI feature documentation

### Phase 4: Advanced Features (Weeks 13-16)

**Week 13: Multi-User & Sharing**
- Implement household management
- Add user invitations
- Create shared meal plans
- Implement real-time sync
- Add collaborative shopping lists
- Build household settings UI

**Week 14: Enhanced Sync & Offline**
- Implement conflict resolution
- Add background sync
- Create sync status indicators
- Optimize offline data storage
- Implement selective sync
- Add data compression

**Week 15: Additional Integrations**
- Create Supabase database plugin
- Implement Supabase auth plugin
- Add OAuth providers (stretch goal)
- Implement S3 storage option
- Create plugin documentation
- Write migration guides

**Week 16: Polish & Deployment**
- Performance optimization
- Security audit
- Comprehensive testing
- Create deployment documentation
- Build Docker images
- Create release packages
- Write user documentation

### Phase 5: Launch Preparation (Weeks 17-20)

**Week 17: Documentation**
- Complete API documentation
- Write user guides
- Create video tutorials
- Build plugin development guide
- Document deployment scenarios
- Create troubleshooting guide

**Week 18: Community Setup**
- Set up GitHub organization
- Create contribution guidelines
- Set up issue templates
- Create Discord/forum
- Write code of conduct
- Plan release strategy

**Week 19: Testing & Bug Fixes**
- Community beta testing
- Bug fix sprint
- Performance tuning
- Security hardening
- UI/UX refinements
- Accessibility improvements

**Week 20: Launch**
- Final release preparation
- Create release announcements
- Publish to app stores
- Launch marketing campaign
- Monitor initial feedback
- Provide launch support

---

## Key Technologies & Dependencies

### Backend (Go)

```go
// go.mod dependencies
require (
    github.com/gin-gonic/gin v1.10.0              // HTTP framework
    github.com/jackc/pgx/v5 v5.5.5                // PostgreSQL driver
    github.com/mattn/go-sqlite3 v1.14.22          // SQLite driver
    github.com/supabase-community/supabase-go v0.0.1 // Supabase client
    golang.org/x/crypto v0.21.0                   // Argon2, bcrypt
    github.com/golang-jwt/jwt/v5 v5.2.1           // JWT tokens
    github.com/google/uuid v1.6.0                 // UUID generation
    github.com/go-playground/validator/v10 v10.19.0 // Input validation
    github.com/spf13/viper v1.18.2                // Configuration
    github.com/rs/zerolog v1.32.0                 // Structured logging
    github.com/stretchr/testify v1.9.0            // Testing framework
    github.com/golang-migrate/migrate/v4 v4.17.0  // Database migrations
    
    // AI providers
    github.com/sashabaranov/go-openai v1.20.4     // OpenAI client
    github.com/google/generative-ai-go v0.5.0     // Gemini client
    
    // External APIs
    github.com/PuerkitoBio/goquery v1.9.1         // HTML parsing (recipe scraping)
    github.com/go-resty/resty/v2 v2.12.0          // HTTP client
)
```

### Frontend (Flutter)

```yaml
# pubspec.yaml dependencies
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  
  # Networking
  dio: ^5.4.3+1
  retrofit: ^4.1.0
  
  # Local Database
  drift: ^2.16.0
  sqlite3_flutter_libs: ^0.5.0
  
  # Storage
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.3
  
  # UI Components
  flutter_hooks: ^0.20.5
  go_router: ^14.1.4
  
  # Forms & Validation
  flutter_form_builder: ^9.2.1
  form_builder_validators: ^10.0.1
  
  # Date & Time
  intl: ^0.19.0
  table_calendar: ^3.1.1
  
  # Images
  cached_network_image: ^3.3.1
  image_picker: ^1.1.1
  
  # Barcode Scanning
  mobile_scanner: ^5.0.0
  
  # Charts
  fl_chart: ^0.68.0
  
  # Utilities
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0
  equatable: ^2.0.5
  dartz: ^0.10.1  # Functional programming
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Code Generation
  build_runner: ^2.4.9
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  retrofit_generator: ^8.1.0
  drift_dev: ^2.16.0
  
  # Testing
  mockito: ^5.4.4
  flutter_lints: ^4.0.0
```

---

## Security Considerations

### Password Security
- Argon2id for password hashing (memory-hard, GPU-resistant)
- Minimum 12-character passwords
- Password strength requirements
- Rate limiting on authentication endpoints
- Account lockout after failed attempts

### Token Security
- JWT with short expiration (15 minutes access, 7 days refresh)
- Secure token storage (Flutter Secure Storage)
- Token rotation on refresh
- Token revocation support

### API Security
- HTTPS only in production
- CORS configuration
- Rate limiting per IP and per user
- Input validation and sanitization
- SQL injection prevention (parameterized queries)
- XSS prevention (output encoding)

### Data Privacy
- User data isolation (row-level security in PostgreSQL)
- Encrypted sensitive data at rest
- Secure file uploads (type validation, size limits)
- GDPR compliance considerations (data export, deletion)

### Infrastructure Security
- Container security scanning
- Regular dependency updates
- Secrets management (environment variables, not hardcoded)
- Database backups with encryption
- Audit logging for sensitive operations

---

## Plugin Development Guide

### Creating a Custom Database Plugin

```go
// internal/database/custom/custom.go
package custom

import (
    "context"
    
    "github.com/yourusername/meal-planner/internal/database"
)

type CustomDB struct {
    // Your database client
}

// NewCustomDB creates a new custom database instance
func NewCustomDB(config map[string]string) (*CustomDB, error) {
    // Initialize your database client
    return &CustomDB{}, nil
}

// Implement all methods from database.Database interface
func (db *CustomDB) Connect(ctx context.Context) error {
    // Implementation
}

// ... implement all other required methods
```

Register in factory:

```go
// internal/database/factory.go
func NewDatabase(cfg *config.Config) (Database, error) {
    switch cfg.Database.Type {
    case "custom":
        return custom.NewCustomDB(cfg.Database.CustomConfig)
    // ... other cases
    }
}
```

### Creating a Custom Auth Plugin

```go
// internal/auth/custom/custom.go
package custom

import (
    "context"
    
    "github.com/yourusername/meal-planner/internal/auth"
)

type CustomAuthProvider struct {
    // Your auth provider client
}

// NewCustomAuthProvider creates a new custom auth provider
func NewCustomAuthProvider(config map[string]string) (*CustomAuthProvider, error) {
    // Initialize your auth provider
    return &CustomAuthProvider{}, nil
}

// Implement all methods from auth.AuthProvider interface
func (p *CustomAuthProvider) Register(ctx context.Context, req auth.RegisterRequest) (*auth.User, error) {
    // Implementation
}

// ... implement all other required methods
```

---

## Monitoring & Observability

### Logging

```go
// Structured logging with zerolog
log.Info().
    Str("user_id", userID).
    Str("action", "create_recipe").
    Dur("duration", time.Since(start)).
    Msg("Recipe created successfully")
```

### Metrics (Prometheus-style)

```go
// Example metrics to track
- http_requests_total (counter)
- http_request_duration_seconds (histogram)
- database_queries_total (counter)
- database_query_duration_seconds (histogram)
- ai_completion_requests_total (counter)
- ai_completion_tokens_used (counter)
- sync_operations_total (counter)
- active_users (gauge)
```

### Health Checks

```go
// /health endpoint
{
    "status": "healthy",
    "version": "1.0.0",
    "checks": {
        "database": "healthy",
        "storage": "healthy",
        "ai_provider": "healthy"
    },
    "uptime": "72h15m30s"
}
```

---

## Performance Optimization

### Backend
- Connection pooling (PostgreSQL, HTTP clients)
- Query optimization (indexes, query analysis)
- Caching (Redis for high-traffic deployments)
- Pagination for list endpoints
- Batch operations where possible
- Image compression and thumbnails
- Database query result caching

### Frontend
- Lazy loading for images
- Virtual scrolling for long lists
- Optimistic updates
- Debouncing search inputs
- Image caching
- Code splitting
- Offline-first architecture reduces server load

### Database
- Proper indexing strategy
- Materialized views for complex queries
- Partitioning for large tables
- Query optimization
- Regular VACUUM and ANALYZE (PostgreSQL)

---

## Backup & Disaster Recovery

### Automated Backups

```bash
#!/bin/bash
# deployment/scripts/backup.sh

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups"

# Database backup
docker exec meal-planner-db pg_dump -U $POSTGRES_USER $POSTGRES_DB | gzip > $BACKUP_DIR/db_backup_$TIMESTAMP.sql.gz

# Uploads backup
tar -czf $BACKUP_DIR/uploads_backup_$TIMESTAMP.tar.gz -C /app/uploads .

# Retain only last 30 days
find $BACKUP_DIR -name "*.gz" -mtime +30 -delete
```

### Restore Procedure

```bash
#!/bin/bash
# deployment/scripts/restore.sh

BACKUP_FILE=$1

# Stop services
docker-compose down

# Restore database
gunzip < $BACKUP_FILE | docker exec -i meal-planner-db psql -U $POSTGRES_USER $POSTGRES_DB

# Restore uploads
tar -xzf uploads_backup.tar.gz -C /app/uploads

# Start services
docker-compose up -d
```

---

## License Compliance (AGPL-3.0)

### Required Actions

1. **Source Code Availability**: Include prominent link to source code in application
2. **License Notice**: Add AGPL-3.0 license header to all source files
3. **Network Use Disclosure**: Inform users they're interacting with AGPL software
4. **Modification Disclosure**: Track and disclose modifications in CHANGELOG
5. **Dependency Licensing**: Ensure all dependencies are compatible with AGPL-3.0

### License Header Template

```go
/*
 * Meal Planning Application
 * Copyright (C) 2025 [Your Name/Organization]
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
```

---

## Deployment Scenarios

### Scenario 1: Home Server (Raspberry Pi / NUC)
- SQLite database
- Ollama for local AI
- Single user or small household
- No external services cost
- Budget: $0/month (hardware already owned)

### Scenario 2: VPS Deployment
- PostgreSQL database
- Ollama or cloud AI (OpenAI free tier)
- 10-50 users
- Automated backups
- Budget: $10-15/month (VPS + domain)

### Scenario 3: Cloud-Native (Supabase)
- Supabase for database + auth
- Cloud AI (Gemini/Claude)
- Scalable to 100+ users
- Managed services
- Budget: $25-50/month (scales with usage)

---

## Success Metrics

### Technical Metrics
- API response time < 200ms (p95)
- App launch time < 2s
- Offline sync success rate > 99%
- Test coverage > 80%
- Zero critical security vulnerabilities

### User Experience Metrics
- App crash rate < 0.1%
- Successful recipe import rate > 95%
- AI feature satisfaction > 4/5 stars
- Time to create first meal plan < 5 minutes
- Average daily active usage > 10 minutes

### Community Metrics
- GitHub stars growth
- Plugin ecosystem contributions
- Community forum activity
- Documentation completeness
- Issue resolution time

---

## End Notes

This implementation plan provides a comprehensive roadmap for building a self-hosted meal planning application with modular architecture and AI capabilities. Key success factors:

1. **Modularity First**: Database and auth abstractions enable community plugins
2. **Offline-First**: Flutter + local database ensures usability without internet
3. **AI Flexibility**: Support for local (Ollama) and cloud AI providers
4. **Developer Experience**: Clear interfaces, comprehensive tests, good documentation
5. **Community Driven**: AGPL-3.0 license, plugin system, contribution guidelines
6. **Budget Conscious**: Self-hosting keeps costs under $15/month
7. **Production Ready**: Docker deployment, CI/CD, monitoring, backups

The architecture is designed to support solo development initially while enabling community contributions through well-defined interfaces and plugin systems.
