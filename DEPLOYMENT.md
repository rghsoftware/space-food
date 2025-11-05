# Space Food Deployment Guide

This guide covers deploying Space Food in various environments, from local development to production.

---

## Table of Contents

1. [Quick Start (Docker Compose)](#quick-start-docker-compose)
2. [Environment Variables](#environment-variables)
3. [Database Setup](#database-setup)
4. [Storage Configuration](#storage-configuration)
5. [AI Provider Setup](#ai-provider-setup)
6. [Production Deployment](#production-deployment)
7. [Reverse Proxy Configuration](#reverse-proxy-configuration)
8. [SSL/TLS Setup](#ssltls-setup)
9. [Backup and Restore](#backup-and-restore)
10. [Monitoring and Logging](#monitoring-and-logging)

---

## Quick Start (Docker Compose)

The fastest way to get Space Food running is with Docker Compose.

### Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- 2GB RAM minimum
- 10GB disk space

### Step 1: Clone Repository

```bash
git clone https://github.com/rghsoftware/space-food.git
cd space-food
```

### Step 2: Configure Environment

```bash
cd deployment/docker
cp .env.example .env
nano .env  # Edit configuration
```

### Step 3: Start Services

```bash
docker-compose up -d
```

### Step 4: Verify Deployment

```bash
# Check service status
docker-compose ps

# Check logs
docker-compose logs -f backend

# Test API
curl http://localhost:8080/health
```

The application should now be running at:
- API: http://localhost:8080
- Static files: http://localhost:8080/uploads

---

## Environment Variables

### Required Variables

```bash
# Database Configuration
SPACE_FOOD_DATABASE_TYPE=postgres          # postgres, sqlite
SPACE_FOOD_DATABASE_HOST=localhost
SPACE_FOOD_DATABASE_PORT=5432
SPACE_FOOD_DATABASE_NAME=space_food
SPACE_FOOD_DATABASE_USER=postgres
SPACE_FOOD_DATABASE_PASSWORD=yourpassword

# Authentication
SPACE_FOOD_AUTH_JWTSECRET=your-secret-key-min-32-chars  # IMPORTANT: Change this!
```

### Optional Variables

```bash
# Server Configuration
SPACE_FOOD_SERVER_HOST=0.0.0.0
SPACE_FOOD_SERVER_PORT=8080
SPACE_FOOD_SERVER_ENVIRONMENT=production

# Authentication
SPACE_FOOD_AUTH_JWTEXPIRY=15              # Access token expiry (minutes)
SPACE_FOOD_AUTH_REFRESHEXPIRY=7           # Refresh token expiry (days)

# Storage
SPACE_FOOD_STORAGE_TYPE=local             # local, s3
SPACE_FOOD_STORAGE_LOCALPATH=./uploads

# S3 Storage (if using)
SPACE_FOOD_STORAGE_S3BUCKET=my-bucket
SPACE_FOOD_STORAGE_S3REGION=us-east-1
SPACE_FOOD_STORAGE_S3KEY=your-access-key
SPACE_FOOD_STORAGE_S3SECRET=your-secret-key

# AI Configuration
SPACE_FOOD_AI_DEFAULTPROVIDER=ollama      # ollama, openai, gemini, claude
SPACE_FOOD_AI_OLLAMA_ENABLED=true
SPACE_FOOD_AI_OLLAMA_HOST=http://localhost:11434
SPACE_FOOD_AI_OLLAMA_MODEL=llama2

SPACE_FOOD_AI_OPENAI_ENABLED=false
SPACE_FOOD_AI_OPENAI_APIKEY=sk-...
SPACE_FOOD_AI_OPENAI_MODEL=gpt-3.5-turbo

SPACE_FOOD_AI_GEMINI_ENABLED=false
SPACE_FOOD_AI_GEMINI_APIKEY=...
SPACE_FOOD_AI_GEMINI_MODEL=gemini-pro

SPACE_FOOD_AI_CLAUDE_ENABLED=false
SPACE_FOOD_AI_CLAUDE_APIKEY=sk-ant-...
SPACE_FOOD_AI_CLAUDE_MODEL=claude-3-sonnet-20240229

# Nutrition
SPACE_FOOD_NUTRITION_USDAAPIKEY=your-usda-api-key  # Get from https://fdc.nal.usda.gov/api-key-signup.html

# Logging
SPACE_FOOD_LOGGING_LEVEL=info             # debug, info, warn, error
SPACE_FOOD_LOGGING_FORMAT=json            # json, console
```

### Generating Secure JWT Secret

```bash
# Generate a secure random secret
openssl rand -base64 32

# Or use Python
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```

---

## Database Setup

### PostgreSQL (Recommended for Production)

#### Option 1: Docker Compose (Included)

Already configured in `deployment/docker/docker-compose.yml`.

#### Option 2: External PostgreSQL

```bash
# Create database
psql -U postgres
CREATE DATABASE space_food;
CREATE USER space_food_user WITH PASSWORD 'yourpassword';
GRANT ALL PRIVILEGES ON DATABASE space_food TO space_food_user;
\q

# Update .env
SPACE_FOOD_DATABASE_TYPE=postgres
SPACE_FOOD_DATABASE_HOST=your-postgres-host
SPACE_FOOD_DATABASE_PORT=5432
SPACE_FOOD_DATABASE_NAME=space_food
SPACE_FOOD_DATABASE_USER=space_food_user
SPACE_FOOD_DATABASE_PASSWORD=yourpassword
```

### SQLite (Development/Single User)

```bash
# Update .env
SPACE_FOOD_DATABASE_TYPE=sqlite
SPACE_FOOD_DATABASE_SQLITEPATH=./data/space_food.db

# Create data directory
mkdir -p ./data
```

**Pros:**
- Zero configuration
- Perfect for development
- Low resource usage

**Cons:**
- Not recommended for multiple concurrent users
- Limited scalability

### Database Migrations

Migrations run automatically on startup. To run manually:

```bash
# Inside backend directory
go run cmd/server/main.go

# Or with Docker
docker-compose exec backend /app/server
```

---

## Storage Configuration

### Local Filesystem Storage

**Best for:** Single-server deployments, development

```bash
SPACE_FOOD_STORAGE_TYPE=local
SPACE_FOOD_STORAGE_LOCALPATH=./uploads

# Create directory
mkdir -p ./uploads
chmod 755 ./uploads
```

**Docker Volume Setup:**

```yaml
# docker-compose.yml
services:
  backend:
    volumes:
      - ./uploads:/app/uploads
```

### AWS S3 Storage

**Best for:** Production, multi-server deployments, CDN integration

#### Step 1: Create S3 Bucket

```bash
aws s3 mb s3://space-food-uploads --region us-east-1
```

#### Step 2: Configure Bucket Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::space-food-uploads/*"
    }
  ]
}
```

#### Step 3: Create IAM User

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::space-food-uploads/*"
    }
  ]
}
```

#### Step 4: Configure Environment

```bash
SPACE_FOOD_STORAGE_TYPE=s3
SPACE_FOOD_STORAGE_S3BUCKET=space-food-uploads
SPACE_FOOD_STORAGE_S3REGION=us-east-1
SPACE_FOOD_STORAGE_S3KEY=AKIA...
SPACE_FOOD_STORAGE_S3SECRET=...
```

---

## AI Provider Setup

### Ollama (Local, Free)

**Recommended for:** Self-hosted, privacy-focused deployments

#### Step 1: Install Ollama

```bash
# Linux
curl https://ollama.ai/install.sh | sh

# macOS
brew install ollama

# Or use Docker
docker run -d -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama
```

#### Step 2: Pull Model

```bash
ollama pull llama2
# or
ollama pull mistral
```

#### Step 3: Configure

```bash
SPACE_FOOD_AI_DEFAULTPROVIDER=ollama
SPACE_FOOD_AI_OLLAMA_ENABLED=true
SPACE_FOOD_AI_OLLAMA_HOST=http://localhost:11434
SPACE_FOOD_AI_OLLAMA_MODEL=llama2
```

### OpenAI

**Recommended for:** Production, best quality results

```bash
# Get API key from https://platform.openai.com/api-keys

SPACE_FOOD_AI_DEFAULTPROVIDER=openai
SPACE_FOOD_AI_OPENAI_ENABLED=true
SPACE_FOOD_AI_OPENAI_APIKEY=sk-...
SPACE_FOOD_AI_OPENAI_MODEL=gpt-3.5-turbo  # or gpt-4
```

**Estimated costs:**
- GPT-3.5-turbo: ~$0.50-2/month for typical usage
- GPT-4: ~$5-15/month for typical usage

### Google Gemini

**Recommended for:** Cost-effective alternative to OpenAI

```bash
# Get API key from https://makersuite.google.com/app/apikey

SPACE_FOOD_AI_DEFAULTPROVIDER=gemini
SPACE_FOOD_AI_GEMINI_ENABLED=true
SPACE_FOOD_AI_GEMINI_APIKEY=...
SPACE_FOOD_AI_GEMINI_MODEL=gemini-pro
```

### Anthropic Claude

**Recommended for:** High-quality, context-aware responses

```bash
# Get API key from https://console.anthropic.com/

SPACE_FOOD_AI_DEFAULTPROVIDER=claude
SPACE_FOOD_AI_CLAUDE_ENABLED=true
SPACE_FOOD_AI_CLAUDE_APIKEY=sk-ant-...
SPACE_FOOD_AI_CLAUDE_MODEL=claude-3-sonnet-20240229
```

---

## Production Deployment

### Single Server Deployment

**Recommended specs:**
- 2 CPU cores
- 4GB RAM
- 20GB SSD
- Ubuntu 22.04 LTS

#### Step 1: Install Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install docker-compose-plugin
```

#### Step 2: Setup Application

```bash
# Create app directory
sudo mkdir -p /opt/space-food
sudo chown $USER:$USER /opt/space-food
cd /opt/space-food

# Clone repository
git clone https://github.com/rghsoftware/space-food.git .

# Configure
cd deployment/docker
cp .env.example .env
nano .env  # Edit production settings
```

#### Step 3: Start Services

```bash
docker compose up -d
```

#### Step 4: Setup Systemd Service (Optional)

```bash
sudo nano /etc/systemd/system/space-food.service
```

```ini
[Unit]
Description=Space Food Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/space-food/deployment/docker
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
User=spaceFood

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable space-food
sudo systemctl start space-food
```

### High Availability Setup

For production deployments with multiple servers:

1. **External PostgreSQL** (managed service like AWS RDS, DigitalOcean Managed DB)
2. **S3 Storage** (or compatible like MinIO, Wasabi)
3. **Load Balancer** (HAProxy, Nginx, AWS ALB)
4. **Multiple Backend Instances**

---

## Reverse Proxy Configuration

### Caddy (Included in Docker Compose)

Caddy is pre-configured in `deployment/caddy/Caddyfile`:

```caddy
{$DOMAIN:localhost} {
    reverse_proxy backend:8080

    encode gzip

    log {
        output file /var/log/caddy/access.log
    }
}
```

**To use custom domain:**

```bash
# Edit .env
DOMAIN=meals.yourdomain.com

# Restart
docker-compose restart caddy
```

Caddy automatically handles SSL/TLS with Let's Encrypt!

### Nginx

Create `/etc/nginx/sites-available/space-food`:

```nginx
server {
    listen 80;
    server_name meals.yourdomain.com;

    client_max_body_size 10M;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /uploads/ {
        alias /opt/space-food/uploads/;
        expires 7d;
        add_header Cache-Control "public, immutable";
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/space-food /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Apache

```apache
<VirtualHost *:80>
    ServerName meals.yourdomain.com

    ProxyPreserveHost On
    ProxyPass / http://localhost:8080/
    ProxyPassReverse / http://localhost:8080/

    <Directory /opt/space-food/uploads>
        Options -Indexes +FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    Alias /uploads /opt/space-food/uploads
</VirtualHost>
```

---

## SSL/TLS Setup

### Option 1: Caddy (Automatic)

Caddy handles SSL automatically with Let's Encrypt. Just set your domain:

```bash
DOMAIN=meals.yourdomain.com
```

### Option 2: Certbot (Nginx/Apache)

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Nginx
sudo certbot --nginx -d meals.yourdomain.com

# Apache
sudo certbot --apache -d meals.yourdomain.com

# Auto-renewal
sudo systemctl status certbot.timer
```

### Option 3: Cloudflare (Free SSL + CDN)

1. Add domain to Cloudflare
2. Point A record to server IP
3. Enable SSL/TLS (Full or Full Strict)
4. Enable HTTP to HTTPS redirect
5. Configure Cloudflare Origin Certificate (optional)

---

## Backup and Restore

### Database Backup

#### PostgreSQL

```bash
# Backup
docker-compose exec postgres pg_dump -U postgres space_food > backup_$(date +%Y%m%d).sql

# Automated daily backups
cat > /etc/cron.daily/space-food-backup <<'EOF'
#!/bin/bash
cd /opt/space-food/deployment/docker
docker-compose exec -T postgres pg_dump -U postgres space_food | gzip > /backups/space_food_$(date +%Y%m%d).sql.gz
find /backups -name "space_food_*.sql.gz" -mtime +30 -delete
EOF
chmod +x /etc/cron.daily/space-food-backup
```

#### SQLite

```bash
# Backup
cp ./data/space_food.db ./data/space_food_backup_$(date +%Y%m%d).db

# Or with SQLite tools
sqlite3 ./data/space_food.db ".backup './data/backup.db'"
```

### File Storage Backup

#### Local Storage

```bash
# Sync to remote backup
rsync -avz ./uploads/ user@backup-server:/backups/space-food-uploads/
```

#### S3 Storage

Already backed up on S3. Enable versioning for additional protection:

```bash
aws s3api put-bucket-versioning \
  --bucket space-food-uploads \
  --versioning-configuration Status=Enabled
```

### Restore

#### PostgreSQL

```bash
# Stop application
docker-compose stop backend

# Restore database
cat backup_20250115.sql | docker-compose exec -T postgres psql -U postgres space_food

# Start application
docker-compose start backend
```

#### SQLite

```bash
# Stop application
docker-compose stop backend

# Restore
cp ./data/backup.db ./data/space_food.db

# Start application
docker-compose start backend
```

---

## Monitoring and Logging

### Logging

Logs are written to stdout and can be viewed with:

```bash
# All services
docker-compose logs -f

# Backend only
docker-compose logs -f backend

# Last 100 lines
docker-compose logs --tail=100 backend
```

### Log Format

Logs use structured JSON format:

```json
{
  "level": "info",
  "time": "2025-01-15T10:00:00Z",
  "message": "Starting HTTP server",
  "address": "0.0.0.0:8080"
}
```

### Log Aggregation

#### Loki + Grafana

```yaml
# docker-compose.override.yml
version: '3.8'
services:
  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"
    volumes:
      - loki-data:/loki

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-data:/var/lib/grafana

volumes:
  loki-data:
  grafana-data:
```

### Health Monitoring

```bash
# Simple health check
curl http://localhost:8080/health

# Monitoring script
cat > /usr/local/bin/space-food-healthcheck <<'EOF'
#!/bin/bash
STATUS=$(curl -s http://localhost:8080/health | jq -r '.status')
if [ "$STATUS" != "healthy" ]; then
  echo "Space Food is unhealthy!"
  # Send alert (email, Slack, etc.)
fi
EOF
chmod +x /usr/local/bin/space-food-healthcheck

# Add to cron (every 5 minutes)
*/5 * * * * /usr/local/bin/space-food-healthcheck
```

### Resource Monitoring

```bash
# View resource usage
docker stats

# View specific container
docker stats backend
```

---

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.

---

## Security Checklist

- [ ] Changed default JWT secret
- [ ] Using HTTPS in production
- [ ] Database password is secure (16+ random characters)
- [ ] Firewall configured (only ports 80, 443, 22 open)
- [ ] Regular backups configured
- [ ] Log monitoring setup
- [ ] Keep Docker images updated
- [ ] S3 bucket not publicly writable (only read)
- [ ] Rate limiting configured (reverse proxy level)
- [ ] Environment variables not committed to git

---

## Cost Estimation

### Minimal Self-Hosted Setup

- VPS (2 CPU, 4GB RAM): $5-10/month
- Domain: $10-15/year
- SSL: Free (Let's Encrypt)
- **Total: ~$5-12/month**

### With AI (Cloud)

- VPS: $5-10/month
- OpenAI API: $0.50-5/month
- **Total: ~$6-15/month**

### With AI (Self-Hosted)

- VPS (4 CPU, 8GB RAM): $20-40/month
- Ollama (included): Free
- **Total: ~$20-40/month**

---

## Next Steps

1. Review [API Documentation](API.md)
2. Configure your environment
3. Deploy using Docker Compose
4. Set up backups
5. Configure monitoring
6. Add custom domain and SSL
7. Invite your household members!
