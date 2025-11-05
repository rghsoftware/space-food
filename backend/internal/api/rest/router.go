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

package rest

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/rghsoftware/space-food/internal/auth"
	authfeature "github.com/rghsoftware/space-food/internal/features/auth"
	"github.com/rghsoftware/space-food/internal/features/recipes"
	"github.com/rghsoftware/space-food/internal/database"
	"github.com/rghsoftware/space-food/internal/middleware"
)

// SetupRouter sets up the API router
func SetupRouter(db database.Database, authProvider auth.AuthProvider) *gin.Engine {
	router := gin.Default()

	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		if err := db.Health(c.Request.Context()); err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{
				"status": "unhealthy",
				"error":  err.Error(),
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"status": "healthy",
		})
	})

	// API v1 routes
	v1 := router.Group("/api/v1")

	// Auth routes (public)
	authHandler := authfeature.NewHandler(authProvider)
	authGroup := v1.Group("/auth")
	authHandler.RegisterRoutes(authGroup)

	// Protected routes
	protected := v1.Group("")
	protected.Use(middleware.AuthMiddleware(authProvider))

	// Recipe routes
	recipeHandler := recipes.NewHandler(db)
	recipeGroup := protected.Group("/recipes")
	recipeHandler.RegisterRoutes(recipeGroup)

	// Additional feature routes will be added here:
	// - Meal plans
	// - Pantry
	// - Shopping lists
	// - Nutrition tracking

	return router
}
