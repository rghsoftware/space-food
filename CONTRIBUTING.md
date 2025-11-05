# Contributing to Space Food

Thank you for your interest in contributing to Space Food! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

Be respectful, inclusive, and constructive in all interactions. We're building this together as a community.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](https://github.com/rghsoftware/space-food/issues)
2. If not, create a new issue with:
   - Clear description of the bug
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (OS, versions, etc.)
   - Screenshots if applicable

### Suggesting Features

1. Check [existing feature requests](https://github.com/rghsoftware/space-food/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)
2. Create a new issue describing:
   - The problem you're trying to solve
   - Your proposed solution
   - Alternative solutions you've considered
   - Additional context

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Write or update tests
5. Ensure all tests pass
6. Update documentation as needed
7. Commit with clear messages
8. Push to your fork
9. Open a Pull Request

## Development Setup

### Backend (Go)

```bash
cd backend
go mod download
go run cmd/server/main.go
```

### Frontend (Flutter)

```bash
cd app
flutter pub get
flutter run
```

### Database

For local development, use Docker:

```bash
docker-compose -f deployment/docker/docker-compose.yml up postgres
```

## Code Style

### Go

- Follow standard Go formatting (`gofmt`)
- Use meaningful variable names
- Add comments for exported functions
- Keep functions focused and small
- Write tests for new functionality

### Flutter/Dart

- Follow Dart style guide
- Use `flutter analyze` to check code
- Prefer `const` constructors where possible
- Use meaningful widget names
- Follow the established architecture patterns

## Architecture Guidelines

### Backend

- Use the repository pattern for database operations
- Keep business logic in service layers
- Use interfaces for abstraction
- Follow the modular plugin pattern for database and auth providers

### Frontend

- Follow Clean Architecture principles
- Separate concerns: data, domain, presentation
- Use Riverpod for state management
- Implement offline-first with local database sync

## Testing

### Backend Tests

```bash
cd backend
go test ./...
go test -race ./...  # Check for race conditions
go test -cover ./... # Check coverage
```

### Frontend Tests

```bash
cd app
flutter test
flutter test --coverage
```

## License

By contributing, you agree that your contributions will be licensed under the AGPL-3.0 license.

All source files must include the license header:

```go
/*
 * Space Food - Self-Hosted Meal Planning Application
 * Copyright (C) 2025 RGH Software
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

## Plugin Development

### Database Plugins

1. Implement the `database.Database` interface
2. Add to factory in `internal/database/factory.go`
3. Document configuration options
4. Provide example configuration

### Authentication Plugins

1. Implement the `auth.AuthProvider` interface
2. Add to factory in `internal/auth/factory.go`
3. Document setup and configuration
4. Provide migration guides if applicable

## Documentation

- Update README.md for user-facing changes
- Update API documentation for endpoint changes
- Add code comments for complex logic
- Create migration guides for breaking changes

## Questions?

- Open a [Discussion](https://github.com/rghsoftware/space-food/discussions)
- Check existing [Issues](https://github.com/rghsoftware/space-food/issues)

Thank you for contributing! 🚀
