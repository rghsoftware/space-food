# Space Food 🚀🍴

A self-hosted, cross-platform meal planning application with AI-powered features. Built with Flutter and Go, designed for privacy-conscious users who want full control over their meal planning data.

## Features

### Recipe Management
- ✅ Create, edit, and delete recipes with full details
- ✅ Upload recipe images (local or S3 storage)
- ✅ Import recipes from URLs with automatic scraping
- ✅ Organize with categories and tags
- ✅ Full-text search across recipes
- ✅ Nutrition information per recipe

### Meal Planning
- ✅ Create meal plans for any date range
- ✅ Schedule meals by type (breakfast, lunch, dinner, snack)
- ✅ Household sharing for family meal planning
- ✅ AI-powered meal plan generation

### Pantry & Shopping
- ✅ Track pantry inventory with expiration dates
- ✅ Auto-generate shopping lists from meal plans
- ✅ Toggle items as completed
- ✅ Organize by categories and locations
- ✅ Household-shared pantry and shopping lists

### Nutrition Tracking
- ✅ Log meals and nutrition daily
- ✅ View daily and weekly nutrition summaries
- ✅ USDA FoodData Central integration
- ✅ Search 300,000+ foods for accurate nutrition data
- ✅ AI-powered nutrition analysis

### AI Integration (Multi-Provider)
- ✅ Recipe suggestions based on ingredients
- ✅ Recipe variations (vegetarian, low-carb, etc.)
- ✅ Ingredient substitution suggestions
- ✅ Nutrition analysis and recommendations
- ✅ AI meal plan generation
- ✅ Support for Ollama, OpenAI, Gemini, and Claude

### Household Sharing
- ✅ Create households for families
- ✅ Role-based access (owner, admin, member)
- ✅ Share recipes, meal plans, pantry, and shopping lists
- ✅ Collaborative meal planning

### Technical Features
- 🔒 **Self-Hosted** - Your data stays on your server
- 🛡️ **Secure** - Argon2id password hashing, JWT authentication
- 📦 **Easy Deployment** - Docker Compose with auto-SSL via Caddy
- 🔌 **Pluggable** - Modular database and AI providers
- 📱 **API-First** - Complete REST API for integrations
- 📝 **Well-Documented** - Comprehensive API and deployment docs

## Architecture

### Tech Stack

- **Frontend**: Flutter (iOS, Android, Web, Desktop)
- **Backend**: Go with Gin framework
- **Database**: PostgreSQL (default) or SQLite
- **Authentication**: Argon2id password hashing with JWT tokens
- **AI Providers**: Ollama (local), OpenAI, Google Gemini, Anthropic Claude
- **Deployment**: Docker Compose with Caddy reverse proxy

### Key Design Principles

- **Modular Architecture**: Pluggable database and authentication providers
- **Offline-First**: Local SQLite/Drift database with server sync
- **Privacy-Focused**: All data stored on your infrastructure
- **Developer-Friendly**: Clean architecture, comprehensive documentation

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Go 1.22+ (for local development)
- Flutter 3.0+ (for app development)

### Deployment with Docker

1. Clone the repository:
```bash
git clone https://github.com/rghsoftware/space-food.git
cd space-food
```

2. Configure environment:
```bash
cd deployment/docker
cp .env.example .env
# Edit .env with your configuration
```

3. Start the services:
```bash
docker-compose up -d
```

4. The API will be available at `http://localhost:8080`

### Local Development

#### Backend

```bash
cd backend

# Install dependencies
go mod download

# Set up environment variables
export SPACE_FOOD_DATABASE_TYPE=postgres
export SPACE_FOOD_DATABASE_HOST=localhost
export SPACE_FOOD_DATABASE_PORT=5432
export SPACE_FOOD_DATABASE_NAME=space_food
export SPACE_FOOD_DATABASE_USER=postgres
export SPACE_FOOD_DATABASE_PASSWORD=postgres
export SPACE_FOOD_AUTH_JWTSECRET=your-secret-key

# Run the server
go run cmd/server/main.go
```

#### Flutter App

```bash
cd app

# Install dependencies
flutter pub get

# Run on your preferred platform
flutter run -d chrome  # Web
flutter run -d macos   # macOS
flutter run            # Connected device
```

## Configuration

### Database Options

The application supports multiple database backends:

- **PostgreSQL** (recommended for production)
- **SQLite** (great for single-user or embedded deployments)
- **Supabase** (plugin available for cloud-native deployments)

Configure via environment variables:
```bash
SPACE_FOOD_DATABASE_TYPE=postgres  # or sqlite
```

### Authentication Options

- **Argon2** (default) - Secure password hashing
- **OAuth2** (coming soon) - Social login providers
- **Supabase Auth** (plugin available)

### AI Integration

Space Food supports multiple AI providers:

```bash
# Ollama (local, privacy-focused)
SPACE_FOOD_AI_DEFAULTPROVIDER=ollama
SPACE_FOOD_AI_OLLAMA_ENABLED=true
SPACE_FOOD_AI_OLLAMA_HOST=http://localhost:11434
SPACE_FOOD_AI_OLLAMA_MODEL=llama2

# OpenAI
SPACE_FOOD_AI_OPENAI_ENABLED=true
SPACE_FOOD_AI_OPENAI_APIKEY=your-api-key

# Google Gemini
SPACE_FOOD_AI_GEMINI_ENABLED=true
SPACE_FOOD_AI_GEMINI_APIKEY=your-api-key

# Anthropic Claude
SPACE_FOOD_AI_CLAUDE_ENABLED=true
SPACE_FOOD_AI_CLAUDE_APIKEY=your-api-key
```

## Project Structure

```
space-food/
├── backend/              # Go backend service
│   ├── cmd/             # Application entrypoints
│   ├── internal/        # Internal packages
│   │   ├── config/      # Configuration
│   │   ├── database/    # Database abstraction
│   │   ├── auth/        # Authentication
│   │   ├── features/    # Business logic
│   │   └── api/         # API layer
│   └── pkg/             # Reusable packages
├── app/                 # Flutter application
│   ├── lib/
│   │   ├── src/
│   │   │   ├── core/    # Core functionality
│   │   │   └── features/# Feature modules
│   └── test/            # Tests
├── deployment/          # Deployment configs
│   ├── docker/          # Docker Compose
│   └── caddy/           # Reverse proxy
└── docs/                # Documentation
```

## Documentation

- **[API Reference](API.md)** - Complete REST API documentation
- **[Deployment Guide](DEPLOYMENT.md)** - Deploy to production
- **[Configuration Reference](CONFIGURATION.md)** - All configuration options
- **[Troubleshooting](TROUBLESHOOTING.md)** - Common issues and solutions
- **[Contributing Guide](CONTRIBUTING.md)** - How to contribute
- **[Implementation Plan](implementation-plan.md)** - Development roadmap

### Quick API Reference

The REST API is available at `/api/v1`. Key endpoint categories:

- **Authentication** - Register, login, token refresh
- **Recipes** - Full CRUD, search, import from URL, image upload
- **Meal Planning** - Create and manage meal plans
- **Pantry** - Track inventory and expiration dates
- **Shopping Lists** - Generate and manage shopping lists
- **Nutrition** - Log meals, view summaries, search USDA database
- **Households** - Family sharing and collaboration
- **AI Features** - Recipe suggestions, meal plans, nutrition analysis

See [API.md](API.md) for complete endpoint documentation with request/response examples.

## Development

### Running Tests

Backend:
```bash
cd backend
go test ./...
```

Flutter:
```bash
cd app
flutter test
```

### Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Implementation Status

### ✅ Phase 1: Foundation (Complete)
- ✅ Go backend with Gin framework
- ✅ PostgreSQL and SQLite database support
- ✅ Argon2id authentication with JWT
- ✅ Database migrations
- ✅ Docker deployment configuration
- ✅ Flutter project scaffolding

### ✅ Phase 2: Core Features (Complete)
- ✅ Recipe management API (CRUD, search)
- ✅ Meal planning API with date ranges
- ✅ Pantry management API
- ✅ Shopping list API with toggle completion
- ✅ Nutrition tracking API with daily summaries

### ✅ Phase 3: AI Integration (Complete)
- ✅ AI provider abstraction layer
- ✅ Ollama integration (local/privacy-focused)
- ✅ OpenAI integration (GPT-3.5/GPT-4)
- ✅ Google Gemini integration
- ✅ Anthropic Claude integration
- ✅ Recipe suggestions and variations
- ✅ AI meal plan generation
- ✅ Nutrition analysis

### ✅ Phase 4: Advanced Features (Complete)
- ✅ Recipe URL import with web scraping
- ✅ USDA FoodData Central integration
- ✅ Image upload (local and S3 storage)
- ✅ Household/family sharing
- ✅ Role-based access control

### 🚧 Phase 5: Launch Preparation (In Progress)
- ✅ API documentation
- ✅ Deployment guide
- ✅ Configuration reference
- ✅ Troubleshooting guide
- ⏳ Community setup
- ⏳ Mobile app implementation
- ⏳ Beta testing

### Coming in Future Releases
- 📱 Full-featured mobile app (Flutter)
- 📱 Mobile barcode scanning
- 🔄 Offline-first data sync
- 🔐 OAuth2 authentication
- 🗄️ Supabase integration plugin
- 📊 Advanced nutrition analytics
- 🎨 Recipe image editing
- 🌍 Multi-language support

## License

This project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0).

This means:
- ✅ Free to use, modify, and distribute
- ✅ Must share modifications if you deploy publicly
- ✅ Network use counts as distribution
- ✅ Must keep the same license

See [LICENSE](LICENSE) for full details.

## Support

- 📖 **Documentation**
  - [API Reference](API.md)
  - [Deployment Guide](DEPLOYMENT.md)
  - [Configuration](CONFIGURATION.md)
  - [Troubleshooting](TROUBLESHOOTING.md)
- 🐛 [Issue Tracker](https://github.com/rghsoftware/space-food/issues)
- 💬 [Discussions](https://github.com/rghsoftware/space-food/discussions)
- 📝 [Contributing Guide](CONTRIBUTING.md)

## Acknowledgments

Built with ❤️ for the self-hosting community.

Special thanks to:
- The Go and Flutter communities
- USDA FoodData Central for nutrition data
- Open Food Facts for product information
- All contributors and testers

---

**Self-hosted. Privacy-focused. Community-driven.**
