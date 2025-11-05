# Multi-stage build for Space Food backend
FROM golang:1.22-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git gcc musl-dev sqlite-dev

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=1 GOOS=linux go build -a -installsuffix cgo -o server ./cmd/server

# Final stage
FROM alpine:latest

# Install runtime dependencies
RUN apk --no-cache add ca-certificates sqlite-libs

WORKDIR /root/

# Copy binary from builder
COPY --from=builder /app/server .

# Copy migrations
COPY --from=builder /app/internal/database/postgres/migrations ./migrations/postgres
COPY --from=builder /app/internal/database/sqlite/migrations ./migrations/sqlite

# Expose port
EXPOSE 8080

# Run the application
CMD ["./server"]
