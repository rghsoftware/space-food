# Space Food Configuration Reference

Complete reference for all configuration options in Space Food.

---

## Configuration Methods

Space Food supports multiple configuration methods (in order of precedence):

1. **Environment Variables** (highest priority)
2. **Config File** (`config.yaml`)
3. **Default Values** (lowest priority)

### Environment Variables

All config values can be set via environment variables with the `SPACE_FOOD_` prefix:

```bash
SPACE_FOOD_SERVER_PORT=8080
SPACE_FOOD_DATABASE_TYPE=postgres
```

Nested values use underscores:
```bash
SPACE_FOOD_AI_OPENAI_APIKEY=sk-...
```

### Config File

Create `config.yaml` in one of these locations:
- `./config.yaml` (current directory)
- `./config/config.yaml`
- `/etc/space-food/config.yaml`

```yaml
server:
  host: 0.0.0.0
  port: 8080

database:
  type: postgres
  host: localhost
```

---

## Server Configuration

### `server.host`

**Type:** `string`
**Default:** `0.0.0.0`
**Env:** `SPACE_FOOD_SERVER_HOST`

The host address to bind the HTTP server to.

**Values:**
- `0.0.0.0` - Listen on all interfaces (production)
- `127.0.0.1` - Localhost only (development)
- Specific IP - Bind to specific network interface

**Example:**
```bash
SPACE_FOOD_SERVER_HOST=0.0.0.0
```

### `server.port`

**Type:** `integer`
**Default:** `8080`
**Env:** `SPACE_FOOD_SERVER_PORT`

The port to run the HTTP server on.

**Example:**
```bash
SPACE_FOOD_SERVER_PORT=3000
```

### `server.environment`

**Type:** `string`
**Default:** `development`
**Env:** `SPACE_FOOD_SERVER_ENVIRONMENT`

Application environment mode.

**Values:**
- `development` - Detailed errors, CORS enabled, debug logging
- `production` - Minimal errors, strict CORS, optimized logging

**Example:**
```bash
SPACE_FOOD_SERVER_ENVIRONMENT=production
```

### `server.trustedproxy`

**Type:** `[]string`
**Default:** `[]`
**Env:** `SPACE_FOOD_SERVER_TRUSTEDPROXY` (comma-separated)

List of trusted proxy IP addresses for X-Forwarded-* headers.

**Example:**
```bash
SPACE_FOOD_SERVER_TRUSTEDPROXY=10.0.0.1,10.0.0.2
```

---

## Database Configuration

### `database.type`

**Type:** `string`
**Default:** `postgres`
**Env:** `SPACE_FOOD_DATABASE_TYPE`

Database engine to use.

**Values:**
- `postgres` - PostgreSQL (recommended for production)
- `sqlite` - SQLite (development, single-user)

**Example:**
```bash
SPACE_FOOD_DATABASE_TYPE=postgres
```

### PostgreSQL Configuration

### `database.host`

**Type:** `string`
**Default:** `localhost`
**Env:** `SPACE_FOOD_DATABASE_HOST`

PostgreSQL server hostname.

### `database.port`

**Type:** `integer`
**Default:** `5432`
**Env:** `SPACE_FOOD_DATABASE_PORT`

PostgreSQL server port.

### `database.name`

**Type:** `string`
**Default:** `space_food`
**Env:** `SPACE_FOOD_DATABASE_NAME`

Database name.

### `database.user`

**Type:** `string`
**Default:** `postgres`
**Env:** `SPACE_FOOD_DATABASE_USER`

Database username.

### `database.password`

**Type:** `string`
**Default:** `""`
**Env:** `SPACE_FOOD_DATABASE_PASSWORD`

Database password.

**Security Note:** Never commit passwords to version control. Use environment variables or secrets management.

### `database.sslmode`

**Type:** `string`
**Default:** `disable`
**Env:** `SPACE_FOOD_DATABASE_SSLMODE`

SSL/TLS mode for PostgreSQL connection.

**Values:**
- `disable` - No SSL (local development)
- `require` - Require SSL (production)
- `verify-ca` - Verify certificate authority
- `verify-full` - Full certificate verification

### `database.maxconns`

**Type:** `integer`
**Default:** `25`
**Env:** `SPACE_FOOD_DATABASE_MAXCONNS`

Maximum number of database connections in the pool.

**Tuning:**
- Small deployments (1-10 users): 10-25
- Medium deployments (10-100 users): 25-50
- Large deployments (100+ users): 50-100

### `database.minconns`

**Type:** `integer`
**Default:** `5`
**Env:** `SPACE_FOOD_DATABASE_MINCONNS`

Minimum number of idle connections to maintain.

### SQLite Configuration

### `database.sqlitepath`

**Type:** `string`
**Default:** `./data/space_food.db`
**Env:** `SPACE_FOOD_DATABASE_SQLITEPATH`

Path to SQLite database file.

**Example:**
```bash
SPACE_FOOD_DATABASE_SQLITEPATH=/var/lib/space-food/db.sqlite
```

---

## Authentication Configuration

### `auth.type`

**Type:** `string`
**Default:** `argon2`
**Env:** `SPACE_FOOD_AUTH_TYPE`

Authentication provider type.

**Values:**
- `argon2` - Argon2id password hashing (default, recommended)

### `auth.jwtsecret`

**Type:** `string`
**Default:** `""`
**Env:** `SPACE_FOOD_AUTH_JWTSECRET`

**⚠️ REQUIRED** - Secret key for signing JWT tokens.

**Requirements:**
- Minimum 32 characters
- Use cryptographically random string
- Never share or commit to version control

**Generate:**
```bash
openssl rand -base64 32
```

### `auth.jwtexpiry`

**Type:** `integer`
**Default:** `15`
**Env:** `SPACE_FOOD_AUTH_JWTEXPIRY`

Access token expiration time in **minutes**.

**Recommended:**
- High security: 5-15 minutes
- Balanced: 15-60 minutes
- Convenience: 60-120 minutes

### `auth.refreshexpiry`

**Type:** `integer`
**Default:** `7`
**Env:** `SPACE_FOOD_AUTH_REFRESHEXPIRY`

Refresh token expiration time in **days**.

**Recommended:**
- High security: 1-7 days
- Balanced: 7-30 days
- Convenience: 30-90 days

### Argon2 Parameters

### `auth.argon2memory`

**Type:** `uint32`
**Default:** `65536`
**Env:** `SPACE_FOOD_AUTH_ARGON2MEMORY`

Memory cost in KB for Argon2 hashing.

**Tuning:**
- Low resources: 32768 (32MB)
- Balanced: 65536 (64MB) - default
- High security: 131072 (128MB)

### `auth.argon2time`

**Type:** `uint32`
**Default:** `3`
**Env:** `SPACE_FOOD_AUTH_ARGON2TIME`

Number of iterations.

**Tuning:**
- Fast: 1-2 iterations
- Balanced: 3 iterations - default
- Secure: 4-5 iterations

### `auth.argon2threads`

**Type:** `uint8`
**Default:** `4`
**Env:** `SPACE_FOOD_AUTH_ARGON2THREADS`

Number of parallel threads.

**Tuning:** Set to number of CPU cores available.

---

## AI Configuration

### `ai.defaultprovider`

**Type:** `string`
**Default:** `ollama`
**Env:** `SPACE_FOOD_AI_DEFAULTPROVIDER`

Default AI provider to use.

**Values:**
- `ollama` - Local Ollama instance
- `openai` - OpenAI API
- `gemini` - Google Gemini API
- `claude` - Anthropic Claude API

### Ollama Configuration

### `ai.ollama.enabled`

**Type:** `boolean`
**Default:** `true`
**Env:** `SPACE_FOOD_AI_OLLAMA_ENABLED`

Enable Ollama provider.

### `ai.ollama.host`

**Type:** `string`
**Default:** `http://localhost:11434`
**Env:** `SPACE_FOOD_AI_OLLAMA_HOST`

Ollama server URL.

### `ai.ollama.model`

**Type:** `string`
**Default:** `llama2`
**Env:** `SPACE_FOOD_AI_OLLAMA_MODEL`

Ollama model to use.

**Popular models:**
- `llama2` - General purpose, 7B params
- `mistral` - Fast, efficient
- `codellama` - Code-focused
- `llama2:13b` - Larger, more capable
- `llama2:70b` - Best quality (requires powerful hardware)

### OpenAI Configuration

### `ai.openai.enabled`

**Type:** `boolean`
**Default:** `false`
**Env:** `SPACE_FOOD_AI_OPENAI_ENABLED`

Enable OpenAI provider.

### `ai.openai.apikey`

**Type:** `string`
**Default:** `""`
**Env:** `SPACE_FOOD_AI_OPENAI_APIKEY`

OpenAI API key. Get from https://platform.openai.com/api-keys

### `ai.openai.model`

**Type:** `string`
**Default:** `gpt-3.5-turbo`
**Env:** `SPACE_FOOD_AI_OPENAI_MODEL`

OpenAI model to use.

**Models:**
- `gpt-3.5-turbo` - Fast, cost-effective
- `gpt-4` - Best quality, higher cost
- `gpt-4-turbo` - Latest GPT-4 model

### Google Gemini Configuration

### `ai.gemini.enabled`

**Type:** `boolean`
**Default:** `false`
**Env:** `SPACE_FOOD_AI_GEMINI_ENABLED`

Enable Google Gemini provider.

### `ai.gemini.apikey`

**Type:** `string`
**Default:** `""`
**Env:** `SPACE_FOOD_AI_GEMINI_APIKEY`

Google Gemini API key. Get from https://makersuite.google.com/app/apikey

### `ai.gemini.model`

**Type:** `string`
**Default:** `gemini-pro`
**Env:** `SPACE_FOOD_AI_GEMINI_MODEL`

Gemini model to use.

**Models:**
- `gemini-pro` - Text generation
- `gemini-pro-vision` - Multimodal (text + images)

### Anthropic Claude Configuration

### `ai.claude.enabled`

**Type:** `boolean`
**Default:** `false`
**Env:** `SPACE_FOOD_AI_CLAUDE_ENABLED`

Enable Anthropic Claude provider.

### `ai.claude.apikey`

**Type:** `string`
**Default:** `""`
**Env:** `SPACE_FOOD_AI_CLAUDE_APIKEY`

Anthropic API key. Get from https://console.anthropic.com/

### `ai.claude.model`

**Type:** `string`
**Default:** `claude-3-sonnet-20240229`
**Env:** `SPACE_FOOD_AI_CLAUDE_MODEL`

Claude model to use.

**Models:**
- `claude-3-haiku-20240307` - Fast, cost-effective
- `claude-3-sonnet-20240229` - Balanced
- `claude-3-opus-20240229` - Best quality

---

## Nutrition Configuration

### `nutrition.usdaapikey`

**Type:** `string`
**Default:** `""`
**Env:** `SPACE_FOOD_NUTRITION_USDAAPIKEY`

USDA FoodData Central API key.

Get free API key from: https://fdc.nal.usda.gov/api-key-signup.html

**Note:** USDA food search endpoints will return 404 if this is not configured.

---

## Storage Configuration

### `storage.type`

**Type:** `string`
**Default:** `local`
**Env:** `SPACE_FOOD_STORAGE_TYPE`

File storage backend.

**Values:**
- `local` - Local filesystem
- `s3` - AWS S3 or compatible

### Local Storage Configuration

### `storage.localpath`

**Type:** `string`
**Default:** `./uploads`
**Env:** `SPACE_FOOD_STORAGE_LOCALPATH`

Path to store uploaded files.

**Requirements:**
- Directory must be writable
- Recommended: Use absolute path in production
- Volume mount for Docker deployments

**Example:**
```bash
SPACE_FOOD_STORAGE_LOCALPATH=/var/lib/space-food/uploads
```

### S3 Storage Configuration

### `storage.s3bucket`

**Type:** `string`
**Default:** `""`
**Env:** `SPACE_FOOD_STORAGE_S3BUCKET`

S3 bucket name.

### `storage.s3region`

**Type:** `string`
**Default:** `""`
**Env:** `SPACE_FOOD_STORAGE_S3REGION`

AWS region.

**Examples:** `us-east-1`, `eu-west-1`, `ap-southeast-1`

### `storage.s3key`

**Type:** `string`
**Default:** `""`
**Env:** `SPACE_FOOD_STORAGE_S3KEY`

AWS access key ID.

### `storage.s3secret`

**Type:** `string`
**Default:** `""`
**Env:** `SPACE_FOOD_STORAGE_S3SECRET`

AWS secret access key.

**S3-Compatible Services:**

Works with any S3-compatible service:
- AWS S3
- DigitalOcean Spaces
- Wasabi
- MinIO
- Backblaze B2

---

## Logging Configuration

### `logging.level`

**Type:** `string`
**Default:** `info`
**Env:** `SPACE_FOOD_LOGGING_LEVEL`

Log level.

**Values (in order of verbosity):**
- `debug` - Very detailed, includes SQL queries
- `info` - General information (recommended)
- `warn` - Warnings and errors only
- `error` - Errors only

### `logging.format`

**Type:** `string`
**Default:** `json`
**Env:** `SPACE_FOOD_LOGGING_FORMAT`

Log output format.

**Values:**
- `json` - Structured JSON logs (recommended for production)
- `console` - Human-readable console output (development)

**JSON Format:**
```json
{"level":"info","time":"2025-01-15T10:00:00Z","message":"Server started","port":8080}
```

**Console Format:**
```
10:00AM INF Server started port=8080
```

---

## Complete Example Configurations

### Development (Local)

```yaml
server:
  host: 127.0.0.1
  port: 8080
  environment: development

database:
  type: sqlite
  sqlitepath: ./data/space_food.db

auth:
  type: argon2
  jwtsecret: dev-secret-change-in-production-minimum-32-chars
  jwtexpiry: 60
  refreshexpiry: 30

storage:
  type: local
  localpath: ./uploads

ai:
  defaultprovider: ollama
  ollama:
    enabled: true
    host: http://localhost:11434
    model: llama2

logging:
  level: debug
  format: console
```

### Production (Single Server)

```yaml
server:
  host: 0.0.0.0
  port: 8080
  environment: production

database:
  type: postgres
  host: localhost
  port: 5432
  name: space_food
  user: space_food
  password: ${DATABASE_PASSWORD}  # from env var
  sslmode: require
  maxconns: 25

auth:
  type: argon2
  jwtsecret: ${JWT_SECRET}  # from env var
  jwtexpiry: 15
  refreshexpiry: 7

storage:
  type: local
  localpath: /var/lib/space-food/uploads

ai:
  defaultprovider: openai
  openai:
    enabled: true
    apikey: ${OPENAI_API_KEY}  # from env var
    model: gpt-3.5-turbo

nutrition:
  usdaapikey: ${USDA_API_KEY}  # from env var

logging:
  level: info
  format: json
```

### Production (Cloud with S3)

```bash
# .env file
SPACE_FOOD_SERVER_HOST=0.0.0.0
SPACE_FOOD_SERVER_PORT=8080
SPACE_FOOD_SERVER_ENVIRONMENT=production

SPACE_FOOD_DATABASE_TYPE=postgres
SPACE_FOOD_DATABASE_HOST=db.example.com
SPACE_FOOD_DATABASE_PORT=5432
SPACE_FOOD_DATABASE_NAME=space_food
SPACE_FOOD_DATABASE_USER=space_food
SPACE_FOOD_DATABASE_PASSWORD=super-secure-password
SPACE_FOOD_DATABASE_SSLMODE=require

SPACE_FOOD_AUTH_JWTSECRET=cryptographically-random-secret-key-at-least-32-characters-long
SPACE_FOOD_AUTH_JWTEXPIRY=15
SPACE_FOOD_AUTH_REFRESHEXPIRY=7

SPACE_FOOD_STORAGE_TYPE=s3
SPACE_FOOD_STORAGE_S3BUCKET=meals-app-uploads
SPACE_FOOD_STORAGE_S3REGION=us-east-1
SPACE_FOOD_STORAGE_S3KEY=AKIA...
SPACE_FOOD_STORAGE_S3SECRET=...

SPACE_FOOD_AI_DEFAULTPROVIDER=openai
SPACE_FOOD_AI_OPENAI_ENABLED=true
SPACE_FOOD_AI_OPENAI_APIKEY=sk-...
SPACE_FOOD_AI_OPENAI_MODEL=gpt-3.5-turbo

SPACE_FOOD_NUTRITION_USDAAPIKEY=...

SPACE_FOOD_LOGGING_LEVEL=info
SPACE_FOOD_LOGGING_FORMAT=json
```

---

## Configuration Validation

On startup, Space Food validates all configuration and will:

1. **Error** on missing required values (JWT secret, database credentials)
2. **Warn** on insecure settings in production (weak passwords, disabled SSL)
3. **Info** on using default values

Check logs on startup:

```bash
docker-compose logs backend | grep -i "config\|error\|warn"
```

---

## Security Best Practices

1. **Never commit secrets** to version control
2. **Use environment variables** for sensitive data
3. **Rotate JWT secret** periodically
4. **Use strong database passwords** (16+ random characters)
5. **Enable SSL** for database connections in production
6. **Set appropriate file permissions** (600 for config files)
7. **Use read-only S3 buckets** (write from backend only)
8. **Keep tokens short-lived** (15 min access, 7 day refresh)

---

## Troubleshooting

### Config Not Loading

Check these locations in order:
```bash
./config.yaml
./config/config.yaml
/etc/space-food/config.yaml
```

### Environment Variables Not Working

Ensure proper prefix:
```bash
# Correct
SPACE_FOOD_SERVER_PORT=8080

# Wrong
SERVER_PORT=8080
```

### Database Connection Issues

Check connection string format:
```bash
# PostgreSQL format
postgres://user:password@host:port/database?sslmode=disable
```

Enable debug logging to see connection details:
```bash
SPACE_FOOD_LOGGING_LEVEL=debug
```

---

## Migration from v0.x to v1.0

If upgrading from earlier versions, note these changes:

1. **JWT secret now required** - No default value
2. **Database type explicit** - Must specify `postgres` or `sqlite`
3. **AI provider structure changed** - Each provider has its own config block
4. **Storage configuration** - New storage backend abstraction

See [CHANGELOG.md](CHANGELOG.md) for complete migration guide.
