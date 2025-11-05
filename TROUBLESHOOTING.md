# Space Food Troubleshooting Guide

Common issues and their solutions.

---

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [Database Problems](#database-problems)
3. [Authentication Errors](#authentication-errors)
4. [API Errors](#api-errors)
5. [AI Provider Issues](#ai-provider-issues)
6. [Storage Problems](#storage-problems)
7. [Performance Issues](#performance-issues)
8. [Docker Issues](#docker-issues)
9. [Network and Connectivity](#network-and-connectivity)
10. [Getting Help](#getting-help)

---

## Installation Issues

### Docker Compose Fails to Start

**Symptoms:**
```
ERROR: Cannot start service backend: port is already allocated
```

**Solution:**
```bash
# Check what's using the port
sudo lsof -i :8080

# Kill the process or change the port
SPACE_FOOD_SERVER_PORT=3000 docker-compose up -d
```

### Permission Denied Errors

**Symptoms:**
```
mkdir /var/lib/space-food: permission denied
```

**Solution:**
```bash
# Fix ownership
sudo chown -R $USER:$USER /opt/space-food

# Or run with appropriate permissions
sudo docker-compose up -d
```

### Missing Environment File

**Symptoms:**
```
WARN[0000] The "DATABASE_PASSWORD" variable is not set
```

**Solution:**
```bash
# Copy example env file
cd deployment/docker
cp .env.example .env

# Edit with your values
nano .env
```

---

## Database Problems

### Connection Refused

**Symptoms:**
```
Failed to connect to database: connection refused
```

**Diagnosis:**
```bash
# Check if PostgreSQL is running
docker-compose ps postgres

# Check PostgreSQL logs
docker-compose logs postgres

# Test connection manually
docker-compose exec postgres psql -U postgres -c "SELECT 1"
```

**Solutions:**

**1. Database not started:**
```bash
docker-compose up -d postgres
sleep 5  # Wait for startup
docker-compose up -d backend
```

**2. Wrong credentials:**
```bash
# Check .env file
cat .env | grep DATABASE

# Ensure they match docker-compose.yml
```

**3. Network issues:**
```bash
# Recreate network
docker-compose down
docker-compose up -d
```

### Migration Failures

**Symptoms:**
```
Failed to run migrations: syntax error at line 23
```

**Solutions:**

**1. Check migration files:**
```bash
# PostgreSQL migrations
ls backend/internal/database/postgres/migrations/

# Verify SQL syntax
cat backend/internal/database/postgres/migrations/001_initial_schema.sql
```

**2. Manual migration:**
```bash
# Access database
docker-compose exec postgres psql -U postgres space_food

# Check applied migrations
SELECT * FROM schema_migrations;

# Run manually if needed
\i /path/to/migration.sql
```

**3. Reset database (DESTRUCTIVE):**
```bash
docker-compose down -v
docker-compose up -d
```

### Database Too Slow

**Symptoms:**
- Queries taking >5 seconds
- High CPU usage on database container

**Solutions:**

**1. Add indexes:**
```sql
-- Common queries
CREATE INDEX idx_recipes_user_id ON recipes(user_id);
CREATE INDEX idx_meal_plans_user_id ON meal_plans(user_id);
CREATE INDEX idx_nutrition_logs_user_date ON nutrition_logs(user_id, date);
```

**2. Increase connection pool:**
```bash
SPACE_FOOD_DATABASE_MAXCONNS=50
```

**3. Optimize PostgreSQL:**
```yaml
# docker-compose.yml
postgres:
  command:
    - "postgres"
    - "-c"
    - "shared_buffers=256MB"
    - "-c"
    - "max_connections=100"
```

---

## Authentication Errors

### "Invalid Token" Errors

**Symptoms:**
```json
{
  "error": "unauthorized: invalid token"
}
```

**Solutions:**

**1. Token expired:**
```bash
# Increase expiry time
SPACE_FOOD_AUTH_JWTEXPIRY=60  # 1 hour
```

**2. JWT secret changed:**
```bash
# Tokens become invalid when secret changes
# Users must log in again
# This is expected behavior after secret rotation
```

**3. Token malformed:**
```bash
# Check Authorization header format
# Correct: Authorization: Bearer eyJhbGc...
# Wrong: Authorization: eyJhbGc...
```

### "Registration Failed" Errors

**Symptoms:**
```json
{
  "error": "email already exists"
}
```

**Solutions:**

**1. Email already registered:**
```bash
# User exists, use login instead
# Or reset password (feature coming in v1.1)
```

**2. Weak password:**
```bash
# Ensure password meets requirements:
# - Minimum 8 characters
# - Recommended: Mix of letters, numbers, symbols
```

**3. Database connection:**
```bash
# Check database connectivity
curl http://localhost:8080/health
```

### Argon2 Memory Errors

**Symptoms:**
```
Failed to hash password: not enough memory
```

**Solution:**
```bash
# Reduce memory cost
SPACE_FOOD_AUTH_ARGON2MEMORY=32768  # 32MB instead of 64MB

# Or increase container memory
docker-compose up -d --scale backend=1 --memory=2g
```

---

## API Errors

### 404 Not Found

**Symptoms:**
```
curl http://localhost:8080/api/v1/recipes
404 page not found
```

**Solutions:**

**1. Check correct API path:**
```bash
# Correct paths
http://localhost:8080/api/v1/recipes
http://localhost:8080/api/v1/auth/login

# Wrong paths
http://localhost:8080/recipes  # Missing /api/v1
```

**2. Check if endpoint exists:**
```bash
# View available routes in logs
docker-compose logs backend | grep "Registered route"
```

### 500 Internal Server Error

**Symptoms:**
```json
{
  "error": "Internal server error"
}
```

**Diagnosis:**
```bash
# Check backend logs
docker-compose logs --tail=50 backend

# Enable debug logging
SPACE_FOOD_LOGGING_LEVEL=debug docker-compose up -d backend
```

**Common causes:**
- Database connection lost
- Invalid data in request
- Missing required configuration
- File system permissions

### CORS Errors (Browser)

**Symptoms:**
```
Access to fetch at 'http://localhost:8080' from origin 'http://localhost:3000'
has been blocked by CORS policy
```

**Solutions:**

**1. Development mode:**
```bash
SPACE_FOOD_SERVER_ENVIRONMENT=development
```

**2. Configure trusted origins:**
```go
// In production, configure allowed origins in router.go
router.Use(cors.New(cors.Config{
    AllowOrigins: []string{"https://yourdomain.com"},
}))
```

---

## AI Provider Issues

### "AI Provider Not Available"

**Symptoms:**
```
curl http://localhost:8080/api/v1/ai/recipes/suggest
404 Not Found
```

**Diagnosis:**
```bash
# Check backend logs for AI initialization
docker-compose logs backend | grep -i "ai\|provider"

# Should see one of:
# "AI provider initialized" - Success
# "AI provider not available" - Failed
```

**Solutions:**

**1. Ollama not running:**
```bash
# Check if Ollama is running
curl http://localhost:11434/api/version

# Start Ollama
ollama serve

# Or with Docker
docker run -d -p 11434:11434 ollama/ollama
```

**2. Ollama model not pulled:**
```bash
# Pull the model specified in config
ollama pull llama2

# Verify
ollama list
```

**3. API key not set:**
```bash
# For OpenAI
SPACE_FOOD_AI_OPENAI_ENABLED=true
SPACE_FOOD_AI_OPENAI_APIKEY=sk-...

# Check if key is valid
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $SPACE_FOOD_AI_OPENAI_APIKEY"
```

### Slow AI Responses

**Symptoms:**
- Requests timeout
- Taking >30 seconds

**Solutions:**

**1. Use faster model:**
```bash
# Ollama - use smaller model
SPACE_FOOD_AI_OLLAMA_MODEL=mistral  # faster than llama2

# OpenAI - use GPT-3.5
SPACE_FOOD_AI_OPENAI_MODEL=gpt-3.5-turbo  # faster than GPT-4
```

**2. Local GPU acceleration:**
```bash
# For Ollama with NVIDIA GPU
docker run -d --gpus all -p 11434:11434 ollama/ollama
```

**3. Increase timeout:**
```go
// Configure in AI provider
client.Timeout = 60 * time.Second
```

---

## Storage Problems

### Image Upload Fails

**Symptoms:**
```json
{
  "error": "failed to upload image: permission denied"
}
```

**Solutions:**

**1. Check directory permissions:**
```bash
# For local storage
ls -la ./uploads
chmod 755 ./uploads

# For Docker
docker-compose exec backend ls -la /app/uploads
```

**2. Check disk space:**
```bash
df -h
# Ensure uploads directory has space

# Clean old uploads if needed
find ./uploads -type f -mtime +90 -delete
```

**3. Check file size limit:**
```bash
# Default max: 10MB
# If you need larger files, configure Nginx/Caddy:

# Nginx
client_max_body_size 50M;

# Caddy
request_body {
    max_size 50MB
}
```

### S3 Upload Errors

**Symptoms:**
```
failed to upload to S3: AccessDenied
```

**Solutions:**

**1. Check IAM permissions:**
```json
{
  "Effect": "Allow",
  "Action": [
    "s3:PutObject",
    "s3:GetObject",
    "s3:DeleteObject"
  ],
  "Resource": "arn:aws:s3:::your-bucket/*"
}
```

**2. Verify credentials:**
```bash
# Test with AWS CLI
aws s3 ls s3://your-bucket --profile your-profile

# Check environment variables
echo $SPACE_FOOD_STORAGE_S3KEY
echo $SPACE_FOOD_STORAGE_S3SECRET
```

**3. Check bucket region:**
```bash
# Ensure region matches bucket region
aws s3api get-bucket-location --bucket your-bucket
```

### Images Not Displaying

**Symptoms:**
- Upload succeeds but images return 404

**Solutions:**

**1. Local storage - check static serving:**
```bash
# Verify uploads endpoint
curl http://localhost:8080/uploads/test.jpg

# Check router configuration
docker-compose logs backend | grep "Static"
```

**2. S3 storage - check bucket policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "PublicRead",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::your-bucket/*"
  }]
}
```

---

## Performance Issues

### High Memory Usage

**Symptoms:**
```
backend container using >2GB RAM
```

**Solutions:**

**1. Reduce connection pool:**
```bash
SPACE_FOOD_DATABASE_MAXCONNS=10
```

**2. Reduce Argon2 memory:**
```bash
SPACE_FOOD_AUTH_ARGON2MEMORY=32768
```

**3. Limit container resources:**
```yaml
# docker-compose.yml
backend:
  mem_limit: 1g
  memswap_limit: 1g
```

### High CPU Usage

**Symptoms:**
- CPU consistently >80%
- Slow response times

**Solutions:**

**1. Check for expensive queries:**
```bash
# Enable query logging
SPACE_FOOD_LOGGING_LEVEL=debug

# Look for slow queries
docker-compose logs backend | grep "query took"
```

**2. Add database indexes:**
```sql
-- Analyze slow queries
EXPLAIN ANALYZE SELECT * FROM recipes WHERE user_id = '...';

-- Add appropriate indexes
CREATE INDEX idx_recipes_user_id ON recipes(user_id);
```

**3. Scale horizontally:**
```yaml
# docker-compose.yml
backend:
  deploy:
    replicas: 3
```

### Slow Startup Time

**Symptoms:**
- Container takes >30 seconds to become healthy

**Solutions:**

**1. Check database connection:**
```bash
# Database might be slow to start
# Add health check wait
docker-compose up -d postgres
sleep 10
docker-compose up -d backend
```

**2. Reduce migrations:**
```bash
# If you have many migrations, consider squashing
# Combine all migrations into one file for fresh installs
```

---

## Docker Issues

### Container Keeps Restarting

**Symptoms:**
```bash
docker-compose ps
# Shows backend restarting constantly
```

**Diagnosis:**
```bash
# Check why it's failing
docker-compose logs backend

# Check exit code
docker inspect space-food-backend --format='{{.State.ExitCode}}'
```

**Common causes:**

**Exit code 1 - Application error:**
```bash
# Check logs for specific error
docker-compose logs backend | tail -50
```

**Exit code 137 - Out of memory:**
```bash
# Increase memory limit
docker-compose up -d --scale backend=1 --memory=2g
```

### Cannot Remove Container

**Symptoms:**
```
Error response from daemon: container is in use
```

**Solution:**
```bash
# Force remove
docker rm -f space-food-backend

# Or stop everything
docker-compose down --remove-orphans

# Nuclear option (removes ALL Docker resources)
docker system prune -a --volumes
```

### Old Images Taking Space

**Symptoms:**
```bash
docker system df
# Shows 10GB+ in images
```

**Solution:**
```bash
# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Full cleanup
docker system prune -a --volumes
```

---

## Network and Connectivity

### Cannot Access from External Network

**Symptoms:**
- Works on localhost
- Doesn't work from other devices

**Solutions:**

**1. Check host binding:**
```bash
# Should be 0.0.0.0, not 127.0.0.1
SPACE_FOOD_SERVER_HOST=0.0.0.0
```

**2. Check firewall:**
```bash
# Allow port 8080
sudo ufw allow 8080

# Or for production with Caddy
sudo ufw allow 80
sudo ufw allow 443
```

**3. Check Docker port mapping:**
```yaml
# docker-compose.yml
backend:
  ports:
    - "8080:8080"  # Not "127.0.0.1:8080:8080"
```

### SSL/TLS Certificate Errors

**Symptoms:**
```
NET::ERR_CERT_AUTHORITY_INVALID
```

**Solutions:**

**1. Let's Encrypt with Caddy:**
```bash
# Ensure DNS is pointing to your server
dig +short yourdomain.com

# Caddy auto-generates certs if:
# 1. Port 80 and 443 are open
# 2. Domain resolves to server
# 3. Server is publicly accessible
```

**2. Check Caddy logs:**
```bash
docker-compose logs caddy
# Look for certificate errors
```

**3. Force certificate renewal:**
```bash
docker-compose exec caddy caddy reload --config /etc/caddy/Caddyfile
```

---

## Getting Help

### Before Asking for Help

Please gather this information:

1. **Version info:**
```bash
docker-compose exec backend /app/server --version
```

2. **Logs:**
```bash
docker-compose logs --tail=100 > logs.txt
```

3. **Configuration:**
```bash
# Sanitized config (remove secrets!)
env | grep SPACE_FOOD | sed 's/=.*/=***/'
```

4. **System info:**
```bash
docker version
docker-compose version
uname -a
```

### Where to Get Help

1. **Documentation:**
   - [README.md](README.md) - Overview and quick start
   - [API.md](API.md) - API documentation
   - [DEPLOYMENT.md](DEPLOYMENT.md) - Deployment guide
   - [CONFIGURATION.md](CONFIGURATION.md) - Configuration reference

2. **GitHub Issues:**
   - Search existing issues: https://github.com/rghsoftware/space-food/issues
   - Create new issue with template

3. **Community:**
   - Discord server (link in README)
   - GitHub Discussions

### Bug Report Template

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What you expected to happen.

**Logs**
```
Paste relevant logs here
```

**Environment:**
- OS: [e.g., Ubuntu 22.04]
- Docker version: [e.g., 24.0.0]
- Space Food version: [e.g., v1.0.0]
- Database: [PostgreSQL/SQLite]

**Additional context**
Any other relevant information.
```

---

## Quick Diagnostic Script

Run this script to check your setup:

```bash
#!/bin/bash
echo "=== Space Food Diagnostic ==="
echo

echo "1. Docker Status:"
docker --version
docker-compose --version
echo

echo "2. Containers:"
docker-compose ps
echo

echo "3. Health Check:"
curl -s http://localhost:8080/health | jq .
echo

echo "4. Database Connection:"
docker-compose exec -T postgres psql -U postgres -c "SELECT version();" | head -1
echo

echo "5. Disk Space:"
df -h | grep -E "Filesystem|/var/lib/docker"
echo

echo "6. Recent Errors:"
docker-compose logs --tail=20 backend | grep -i error
echo

echo "=== End Diagnostic ==="
```

Save as `diagnostic.sh`, make executable, and run:
```bash
chmod +x diagnostic.sh
./diagnostic.sh
```

---

## Still Having Issues?

If none of these solutions work:

1. Try a fresh installation in a clean directory
2. Check if it's a known issue on GitHub
3. Create a detailed bug report with logs
4. Ask in community channels

Remember: Include full error messages and logs for faster help!
