# CI/CD Pipeline Documentation

Comprehensive CI/CD pipeline for Space Food - Self-Hosted Meal Planning Application

## Overview

This project uses **GitHub Actions** for continuous integration and deployment, with comprehensive testing, linting, security scanning, and deployment automation.

### Pipeline Components

```
┌─────────────────────────────────────────────────────────────┐
│                    CODE PUSH / PR                            │
└────────────────────┬────────────────────────────────────────┘
                     │
      ┌──────────────┼──────────────┐
      │              │              │
      ▼              ▼              ▼
┌──────────┐  ┌───────────┐  ┌──────────┐
│ Backend  │  │  Flutter  │  │   Lint   │
│  Tests   │  │   Tests   │  │ & Format │
└────┬─────┘  └─────┬─────┘  └────┬─────┘
     │              │              │
     └──────────────┼──────────────┘
                    │
                    ▼
          ┌─────────────────┐
          │  Security Scan  │
          └────────┬─────────┘
                   │
                   ▼
          ┌─────────────────┐
          │  Docker Build   │
          └────────┬─────────┘
                   │
            [Main Branch]
                   │
                   ▼
          ┌─────────────────┐
          │     Deploy      │
          │  (Staging/Prod) │
          └─────────────────┘
```

## Workflows

### 1. Backend Tests (`backend-tests.yml`)

**Triggers:**
- Push to `main`, `develop`, or `claude/**` branches
- Pull requests to `main` or `develop`
- Changes in `backend/` directory

**Jobs:**

#### Test Job
- **Matrix Strategy**: Go 1.22 and 1.23
- **Services**: PostgreSQL 15 (test database)
- **Steps**:
  1. Checkout code
  2. Setup Go with caching
  3. Download dependencies
  4. Run database migrations
  5. Run short tests (unit tests only)
  6. Run all tests with coverage
  7. Run Food Variety tests specifically
  8. Generate coverage reports
  9. Upload to Codecov
  10. Check 70% coverage threshold

**Coverage Requirements:**
- Overall: 70% minimum
- Food Variety feature: Tracked separately

#### Benchmark Job
- Runs performance benchmarks
- Uploads results as artifacts
- Runs for 5 seconds per benchmark

#### Security Scan Job
- Gosec security scanner
- govulncheck for known vulnerabilities
- Uploads SARIF results to GitHub Security

**Run Manually:**
```bash
# Trigger workflow manually
gh workflow run backend-tests.yml
```

### 2. Flutter Tests (`flutter-tests.yml`)

**Triggers:**
- Push to `main`, `develop`, or `claude/**` branches
- Pull requests to `main` or `develop`
- Changes in `app/` directory

**Jobs:**

#### Test Job
- **Matrix Strategy**: Flutter 3.19.0 and stable
- **Steps**:
  1. Checkout code
  2. Setup Flutter with caching
  3. Get dependencies
  4. Run code generation (build_runner)
  5. Analyze code
  6. Run all tests with coverage
  7. Run Food Variety tests specifically
  8. Generate coverage reports (lcov)
  9. Upload to Codecov
  10. Check 60% coverage threshold

#### Integration Test Job
- Runs Flutter integration tests
- Uses Flutter test framework

#### Build Android Job
- Builds debug APK
- Uploads APK as artifact (14 days retention)

#### Build iOS Job
- Builds iOS app (no codesign)
- Runs on macOS runner

#### Golden Tests Job
- Runs screenshot/golden tests
- Uploads failures for review

**Run Manually:**
```bash
# Trigger workflow manually
gh workflow run flutter-tests.yml
```

### 3. Lint & Code Quality (`lint.yml`)

**Triggers:**
- All pushes and PRs

**Jobs:**

#### golangci-lint
- Comprehensive Go linting
- Uses `.golangci.yml` configuration
- 10-minute timeout

#### go-fmt
- Checks Go formatting
- Runs `gofmt` and `go vet`

#### flutter-analyze
- Runs `flutter analyze`
- Checks Dart formatting (80 char line length)

#### dart-lint
- Strict Dart analysis
- Fatal on info-level issues

#### sql-lint
- Lints SQL migrations with sqlfluff
- PostgreSQL dialect

#### markdown-lint
- Lints all markdown files
- Uses markdownlint-cli2

#### yaml-lint
- Lints GitHub Actions workflows
- 120 char line length

#### license-check
- Verifies AGPL-3.0 headers in all source files
- Checks both Go and Dart files

#### dependency-review
- Reviews new dependencies in PRs
- Fails on moderate+ severity vulnerabilities

#### adhd-friendly-check ⭐
- **Unique feature**: Checks for judgmental language
- Banned words: "should not", "must not", "bad food", "problem food"
- Verifies positive messaging patterns

**Linting Rules:**
```yaml
Go: 25+ linters (errcheck, gosimple, gosec, etc.)
Dart: flutter analyze + dart analyze
SQL: sqlfluff with PostgreSQL dialect
Markdown: markdownlint
YAML: yamllint
```

### 4. Docker Build & Push (`docker-build.yml`)

**Triggers:**
- Push to `main` or `develop`
- Tags matching `v*.*.*`
- PRs to `main`

**Jobs:**

#### Build Backend
- Multi-architecture: linux/amd64, linux/arm64
- Pushes to GitHub Container Registry
- Tags: branch, PR, semver, commit SHA
- Cache optimization with GitHub Actions cache

#### Build Frontend
- Multi-architecture builds
- Same tagging strategy

#### Docker Compose Test
- Tests full stack deployment
- Verifies health endpoints
- Runs smoke tests

#### Vulnerability Scan
- Trivy security scanner
- Grype vulnerability scanner
- Uploads SARIF to GitHub Security
- Fails on high severity issues

**Container Images:**
```
ghcr.io/rghsoftware/space-food/backend:latest
ghcr.io/rghsoftware/space-food/backend:main
ghcr.io/rghsoftware/space-food/backend:v1.0.0
ghcr.io/rghsoftware/space-food/app:latest
```

### 5. Deploy (`deploy.yml`)

**Triggers:**
- Tags matching `v*.*.*`
- Manual workflow dispatch

**Environments:**
- **Staging**: `v*.*.*-beta` tags
- **Production**: `v*.*.*` release tags

**Jobs:**

#### Deploy Staging
- Deploys to staging environment
- Environment URL: staging.spacefood.example.com

#### Deploy Production
- Deploys to production environment
- Creates GitHub Release
- Environment URL: spacefood.example.com

#### Database Migration
- Runs after staging deployment
- Uses golang-migrate

#### Post-Deployment Tests
- Smoke tests on deployed environment
- Health check verification

#### Notify Deployment
- Sends Slack notification
- Includes deployment status and version

**Deploy Manually:**
```bash
# Deploy to staging
gh workflow run deploy.yml -f environment=staging

# Deploy to production
gh workflow run deploy.yml -f environment=production
```

## Configuration Files

### `.codecov.yml`

Code coverage configuration:

```yaml
Coverage Targets:
- Project: 70% minimum
- Patch: 60% minimum
- Threshold: 2% deviation allowed

Flags:
- backend: Backend Go code
- flutter: Flutter Dart code
- food_variety: Food Variety feature specifically

Ignore:
- Test files (*_test.go, test/**)
- Generated files (*.freezed.dart, *.g.dart)
- Mock files (mock_*.go, mocks/**)
```

### `.golangci.yml`

Go linting configuration:

**Enabled Linters (20+):**
- errcheck, gosimple, govet, staticcheck
- gofmt, goimports, misspell
- goconst, gocyclo, dupl
- gosec (security), revive, stylecheck
- And more...

**Settings:**
```yaml
Cyclomatic Complexity: Max 15
Min Constant Length: 3 chars
Min Occurrences: 3 for constants
Locale: US English
```

### `.pre-commit-config.yaml`

Pre-commit hooks for local development:

**Hooks:**
1. **General**: trailing-whitespace, end-of-file-fixer, check-yaml
2. **Go**: go-fmt, go-vet, go-imports, go-unit-tests, go-build
3. **Security**: gitleaks (secret scanning)
4. **Markdown**: markdownlint
5. **YAML**: yamllint
6. **Flutter**: flutter-format, flutter-analyze
7. **ADHD-Friendly**: check-judgmental-language ⭐
8. **License**: check-license-headers
9. **Commit Messages**: conventional-pre-commit

**Install:**
```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Run manually
pre-commit run --all-files
```

## Secrets Required

Configure these in GitHub Settings > Secrets and variables > Actions:

### Required Secrets

```bash
CODECOV_TOKEN        # Codecov upload token
GITHUB_TOKEN         # Automatically provided by GitHub
```

### Optional Secrets (for full deployment)

```bash
DATABASE_URL         # Production database connection string
SLACK_WEBHOOK_URL    # Slack notifications
SONAR_TOKEN          # SonarCloud code quality
```

## Branch Protection Rules

Recommended settings for `main` branch:

```yaml
Require:
  ✅ Pull request reviews (1 approver)
  ✅ Status checks to pass:
     - Backend Tests (Go 1.22)
     - Flutter Tests (stable)
     - golangci-lint
     - flutter-analyze
     - ADHD-Friendly Design Check
  ✅ Branches to be up to date
  ✅ Conversations resolved
  ✅ Signed commits (recommended)

Restrictions:
  ❌ Force pushes
  ❌ Deletions
```

## Status Badges

Add to README.md:

```markdown
[![Backend Tests](https://github.com/rghsoftware/space-food/workflows/Backend%20Tests/badge.svg)](https://github.com/rghsoftware/space-food/actions/workflows/backend-tests.yml)
[![Flutter Tests](https://github.com/rghsoftware/space-food/workflows/Flutter%20Tests/badge.svg)](https://github.com/rghsoftware/space-food/actions/workflows/flutter-tests.yml)
[![codecov](https://codecov.io/gh/rghsoftware/space-food/branch/main/graph/badge.svg)](https://codecov.io/gh/rghsoftware/space-food)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
```

## Local Development

### Run Tests Locally

**Backend:**
```bash
cd backend

# All tests
go test ./...

# With coverage
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out

# Food Variety tests only
cd internal/features/food_variety
go test -v -coverprofile=coverage.out
```

**Flutter:**
```bash
cd app

# All tests
flutter test

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Run Linters Locally

**Backend:**
```bash
cd backend

# golangci-lint
golangci-lint run

# Format code
gofmt -s -w .
go mod tidy
```

**Flutter:**
```bash
cd app

# Analyze
flutter analyze

# Format
dart format lib/ test/

# Fix issues
dart fix --apply
```

### Run Docker Build Locally

```bash
# Backend
docker build -t space-food-backend:local ./backend

# Frontend
docker build -t space-food-app:local ./app

# Full stack
docker-compose up
```

## Monitoring & Alerts

### GitHub Actions Dashboard

View workflow runs:
```
https://github.com/rghsoftware/space-food/actions
```

### Codecov Dashboard

View coverage reports:
```
https://codecov.io/gh/rghsoftware/space-food
```

### Alerts Setup

**GitHub:**
- Configure email notifications: Settings > Notifications
- Watch repository: Watch > All Activity

**Slack Integration:**
1. Create Slack app
2. Add Incoming Webhook
3. Add `SLACK_WEBHOOK_URL` to GitHub Secrets
4. Deploy workflow will notify on completion

## Troubleshooting

### Common Issues

#### 1. Tests Failing Locally But Pass in CI

```bash
# Ensure dependencies are up to date
cd backend && go mod download
cd app && flutter pub get

# Clear caches
go clean -cache -testcache
flutter clean && flutter pub get
```

#### 2. Coverage Below Threshold

```bash
# View uncovered lines
go tool cover -func=coverage.out | grep -v 100.0%

# For Flutter
lcov --summary coverage/lcov.info
```

#### 3. Linter Failures

```bash
# Auto-fix many issues
golangci-lint run --fix
dart fix --apply
```

#### 4. Docker Build Fails

```bash
# Build with no cache
docker build --no-cache -t space-food-backend ./backend

# Check logs
docker-compose logs
```

#### 5. Pre-commit Hooks Failing

```bash
# Update hooks
pre-commit autoupdate

# Skip hooks (emergency only)
git commit --no-verify
```

### Getting Help

1. Check workflow logs in GitHub Actions
2. Review this documentation
3. Check [TESTING.md](backend/internal/features/food_variety/TESTING.md)
4. Open an issue with `ci/cd` label

## Performance Optimization

### Caching Strategy

**Go:**
```yaml
cache-dependency-path: backend/go.sum
Cached: ~/.cache/go-build, ~/go/pkg/mod
```

**Flutter:**
```yaml
Flutter SDK cached automatically
Pub cache: Enabled
```

**Docker:**
```yaml
cache-from: type=gha
cache-to: type=gha,mode=max
Multi-stage builds for smaller images
```

### Parallelization

```yaml
Matrix Builds:
- Go: 1.22, 1.23
- Flutter: 3.19.0, stable
- Platform: linux/amd64, linux/arm64

Concurrent Jobs:
- All lint jobs run in parallel
- Test jobs run independently
- Build jobs run after tests pass
```

## Future Enhancements

- [ ] Add E2E tests with Playwright
- [ ] Implement canary deployments
- [ ] Add performance regression testing
- [ ] Setup automated dependency updates (Dependabot)
- [ ] Add accessibility testing
- [ ] Implement blue-green deployments
- [ ] Add APK signing for Android releases
- [ ] Setup TestFlight for iOS beta testing

## License

Space Food - Self-Hosted Meal Planning Application
Copyright (C) 2025 RGH Software
Licensed under AGPL-3.0
