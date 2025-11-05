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
	"context"
	"io"
)

// Provider defines the interface for file storage
type Provider interface {
	// Upload stores a file and returns its URL
	Upload(ctx context.Context, filename string, contentType string, data io.Reader) (string, error)

	// Delete removes a file by its URL
	Delete(ctx context.Context, url string) error

	// GetURL returns the public URL for a stored file
	GetURL(filename string) string
}
