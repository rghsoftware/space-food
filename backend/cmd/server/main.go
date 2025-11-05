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

package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/rghsoftware/space-food/internal/ai"
	"github.com/rghsoftware/space-food/internal/api/rest"
	"github.com/rghsoftware/space-food/internal/auth/argon2"
	"github.com/rghsoftware/space-food/internal/config"
	"github.com/rghsoftware/space-food/internal/database"
	"github.com/rghsoftware/space-food/pkg/logger"
)

func main() {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to load config: %v\n", err)
		os.Exit(1)
	}

	// Initialize logger
	logger.Init(cfg.Logging.Level, cfg.Logging.Format)
	log := logger.Get()

	log.Info().Msg("Starting Space Food API server")

	// Initialize database
	db, err := database.NewDatabase(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("Failed to create database")
	}

	ctx := context.Background()
	if err := db.Connect(ctx); err != nil {
		log.Fatal().Err(err).Msg("Failed to connect to database")
	}
	defer db.Close()

	log.Info().Msg("Connected to database")

	// Run migrations
	if err := db.Migrate(ctx); err != nil {
		log.Fatal().Err(err).Msg("Failed to run migrations")
	}

	log.Info().Msg("Database migrations completed")

	// Initialize authentication provider
	authProvider := argon2.NewArgon2AuthProvider(db, cfg)

	// Initialize AI provider (optional)
	var aiService *ai.Service
	aiProvider, err := ai.NewProvider(ctx, cfg)
	if err != nil {
		log.Warn().Err(err).Msg("AI provider not available, AI features will be disabled")
	} else {
		aiService = ai.NewService(aiProvider)
		log.Info().Str("provider", aiProvider.GetName()).Msg("AI provider initialized")
	}

	// Setup router
	router := rest.SetupRouter(db, authProvider, aiService, cfg)

	// Start server
	addr := fmt.Sprintf("%s:%d", cfg.Server.Host, cfg.Server.Port)
	log.Info().Str("address", addr).Msg("Starting HTTP server")

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		if err := router.Run(addr); err != nil {
			log.Fatal().Err(err).Msg("Failed to start server")
		}
	}()

	<-quit
	log.Info().Msg("Shutting down server...")

	// Give time for cleanup
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	log.Info().Msg("Server stopped")
}
