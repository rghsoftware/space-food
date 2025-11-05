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

package database

import (
	"fmt"

	"github.com/rghsoftware/space-food/internal/config"
	"github.com/rghsoftware/space-food/internal/database/postgres"
	"github.com/rghsoftware/space-food/internal/database/sqlite"
)

// NewDatabase creates a new database instance based on configuration
func NewDatabase(cfg *config.Config) (Database, error) {
	switch cfg.Database.Type {
	case "postgres":
		connString := fmt.Sprintf(
			"host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
			cfg.Database.Host,
			cfg.Database.Port,
			cfg.Database.User,
			cfg.Database.Password,
			cfg.Database.Name,
			cfg.Database.SSLMode,
		)
		return postgres.NewPostgresDB(connString, cfg.Database.MaxConns, cfg.Database.MinConns)

	case "sqlite":
		return sqlite.NewSQLiteDB(cfg.Database.SQLitePath)

	default:
		return nil, fmt.Errorf("unsupported database type: %s", cfg.Database.Type)
	}
}
