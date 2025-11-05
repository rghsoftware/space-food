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

### Current Status: Phase 1 (Foundation)
- ✅ Project structure
- ✅ Database abstraction layer
- ✅ Authentication system
- ✅ Basic API endpoints
- ✅ Flutter project setup
- 🚧 Recipe management UI
- 🚧 Meal planning features

### Coming Soon
- Meal planning and calendar
- Nutrition tracking
- AI-powered features
- Multi-user households
- Mobile barcode scanning

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
