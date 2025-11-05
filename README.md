# Space Food 🚀🍴

A self-hosted, cross-platform meal planning application with AI-powered features. Built with Flutter and Go, designed for privacy-conscious users who want full control over their meal planning data.

## Features

- 🍳 **Recipe Management** - Create, store, and organize your recipes
- 📅 **Meal Planning** - Plan your meals for the week or month
- 🏪 **Pantry Tracking** - Keep track of ingredients and expiration dates
- 📝 **Shopping Lists** - Auto-generate shopping lists from meal plans
- 📊 **Nutrition Tracking** - Monitor your nutritional intake
- 🤖 **AI Integration** - Recipe suggestions, meal plan generation, and more
- 📱 **Cross-Platform** - iOS, Android, Web, and Desktop support
- 🔒 **Self-Hosted** - Your data stays on your server
- 🔄 **Offline-First** - Works without internet connection

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

## API Documentation

The REST API is available at `/api/v1`. Key endpoints:

### Authentication
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login
- `POST /api/v1/auth/refresh` - Refresh token

### Recipes
- `GET /api/v1/recipes` - List recipes
- `POST /api/v1/recipes` - Create recipe
- `GET /api/v1/recipes/:id` - Get recipe
- `PUT /api/v1/recipes/:id` - Update recipe
- `DELETE /api/v1/recipes/:id` - Delete recipe
- `GET /api/v1/recipes/search?q=query` - Search recipes

### Meal Plans
- `GET /api/v1/meal-plans` - List meal plans
- `POST /api/v1/meal-plans` - Create meal plan
- `GET /api/v1/meal-plans/:id` - Get meal plan
- `PUT /api/v1/meal-plans/:id` - Update meal plan
- `DELETE /api/v1/meal-plans/:id` - Delete meal plan

### Pantry
- `GET /api/v1/pantry` - List pantry items
- `POST /api/v1/pantry` - Create pantry item
- `GET /api/v1/pantry/:id` - Get pantry item
- `PUT /api/v1/pantry/:id` - Update pantry item
- `DELETE /api/v1/pantry/:id` - Delete pantry item

### Shopping List
- `GET /api/v1/shopping-list` - List shopping list items
- `POST /api/v1/shopping-list` - Create shopping list item
- `GET /api/v1/shopping-list/:id` - Get shopping list item
- `PUT /api/v1/shopping-list/:id` - Update shopping list item
- `DELETE /api/v1/shopping-list/:id` - Delete shopping list item
- `PATCH /api/v1/shopping-list/:id/toggle` - Toggle item completed status

### Nutrition Tracking
- `GET /api/v1/nutrition/logs` - List nutrition logs
- `GET /api/v1/nutrition/logs/today` - Get today's nutrition logs
- `POST /api/v1/nutrition/logs` - Create nutrition log
- `GET /api/v1/nutrition/summary` - Get nutrition summary

### AI-Powered Features (Requires AI provider configuration)
**AI Recipe Features:**
- `POST /api/v1/ai/recipes/suggest` - Generate recipe suggestions based on ingredients/requirements
- `POST /api/v1/ai/recipes/variations` - Generate variations of existing recipes
- `POST /api/v1/ai/recipes/analyze-nutrition` - AI-powered nutrition analysis
- `POST /api/v1/ai/recipes/substitutions` - Suggest ingredient substitutions

**AI Meal Planning:**
- `POST /api/v1/ai/meal-planning/generate` - Generate complete meal plans with AI

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

## Roadmap

See [implementation-plan.md](implementation-plan.md) for the complete development roadmap.

### Current Status: Phase 3 (AI Integration)
- ✅ Project structure
- ✅ Database abstraction layer
- ✅ Authentication system
- ✅ Recipe management API (full CRUD with search)
- ✅ Meal planning API (full CRUD)
- ✅ Pantry management API
- ✅ Shopping list API (with toggle functionality)
- ✅ Nutrition tracking API (with daily summaries)
- ✅ AI integration (Ollama, OpenAI, Gemini, Claude)
- ✅ AI recipe suggestions and variations
- ✅ AI meal plan generation
- ✅ AI nutrition analysis
- ✅ AI ingredient substitutions
- ✅ Flutter project setup
- 🚧 Recipe management UI
- 🚧 Meal planning calendar UI
- 🚧 Nutrition dashboard UI

### Coming Soon (Phase 4+)
- USDA FoodData integration for nutrition data
- Recipe URL import and web scraping
- Barcode scanning for pantry items
- Multi-user households and sharing
- Real-time sync and conflict resolution
- Image upload for recipes
- Flutter UI for AI features

## License

This project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0).

This means:
- ✅ Free to use, modify, and distribute
- ✅ Must share modifications if you deploy publicly
- ✅ Network use counts as distribution
- ✅ Must keep the same license

See [LICENSE](LICENSE) for full details.

## Support

- 📖 [Documentation](docs/)
- 🐛 [Issue Tracker](https://github.com/rghsoftware/space-food/issues)
- 💬 [Discussions](https://github.com/rghsoftware/space-food/discussions)

## Acknowledgments

Built with ❤️ for the self-hosting community.

Special thanks to:
- The Go and Flutter communities
- USDA FoodData Central for nutrition data
- Open Food Facts for product information
- All contributors and testers

---

**Self-hosted. Privacy-focused. Community-driven.**
