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
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/google/uuid"
)

// LocalProvider implements file storage on the local filesystem
type LocalProvider struct {
	basePath string
	baseURL  string
}

// NewLocalProvider creates a new local storage provider
func NewLocalProvider(basePath, baseURL string) (*LocalProvider, error) {
	// Create base directory if it doesn't exist
	if err := os.MkdirAll(basePath, 0755); err != nil {
		return nil, fmt.Errorf("failed to create storage directory: %w", err)
	}

	return &LocalProvider{
		basePath: basePath,
		baseURL:  baseURL,
	}, nil
}

// Upload stores a file and returns its URL
func (p *LocalProvider) Upload(ctx context.Context, filename string, contentType string, data io.Reader) (string, error) {
	// Generate unique filename
	ext := filepath.Ext(filename)
	uniqueID := uuid.New().String()
	newFilename := uniqueID + ext

	// Create file path
	filePath := filepath.Join(p.basePath, newFilename)

	// Create file
	f, err := os.Create(filePath)
	if err != nil {
		return "", fmt.Errorf("failed to create file: %w", err)
	}
	defer f.Close()

	// Copy data to file
	if _, err := io.Copy(f, data); err != nil {
		os.Remove(filePath)
		return "", fmt.Errorf("failed to write file: %w", err)
	}

	return p.GetURL(newFilename), nil
}

// Delete removes a file by its URL
func (p *LocalProvider) Delete(ctx context.Context, url string) error {
	// Extract filename from URL
	filename := filepath.Base(url)
	filePath := filepath.Join(p.basePath, filename)

	// Remove file
	if err := os.Remove(filePath); err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("failed to delete file: %w", err)
	}

	return nil
}

// GetURL returns the public URL for a stored file
func (p *LocalProvider) GetURL(filename string) string {
	return strings.TrimSuffix(p.baseURL, "/") + "/uploads/" + filename
}
