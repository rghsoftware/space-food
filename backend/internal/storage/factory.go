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

package storage

import (
	"fmt"

	"github.com/rghsoftware/space-food/internal/config"
)

// NewProvider creates a storage provider based on configuration
func NewProvider(cfg *config.Config) (Provider, error) {
	switch cfg.Storage.Type {
	case "local":
		return NewLocalProvider(cfg.Storage.LocalPath, fmt.Sprintf("http://%s:%d", cfg.Server.Host, cfg.Server.Port))
	case "s3":
		if cfg.Storage.S3Bucket == "" || cfg.Storage.S3Region == "" {
			return nil, fmt.Errorf("S3 storage requires bucket and region configuration")
		}
		return NewS3Provider(cfg.Storage.S3Bucket, cfg.Storage.S3Region, cfg.Storage.S3Key, cfg.Storage.S3Secret)
	default:
		return nil, fmt.Errorf("unsupported storage type: %s", cfg.Storage.Type)
	}
}
