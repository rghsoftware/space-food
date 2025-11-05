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

package config

import (
	"fmt"
	"strings"

	"github.com/spf13/viper"
)

// Config represents the application configuration
type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	Auth     AuthConfig
	AI       AIConfig
	Storage  StorageConfig
	Logging  LoggingConfig
}

// ServerConfig contains server-related configuration
type ServerConfig struct {
	Host         string
	Port         int
	Environment  string
	TrustedProxy []string
}

// DatabaseConfig contains database configuration
type DatabaseConfig struct {
	Type         string // postgres, sqlite, supabase
	Host         string
	Port         int
	Name         string
	User         string
	Password     string
	SSLMode      string
	MaxConns     int
	MinConns     int
	SQLitePath   string
	CustomConfig map[string]string
}

// AuthConfig contains authentication configuration
type AuthConfig struct {
	Type           string // argon2, oauth, supabase
	JWTSecret      string
	JWTExpiry      int // minutes
	RefreshExpiry  int // days
	Argon2Memory   uint32
	Argon2Time     uint32
	Argon2Threads  uint8
	CustomConfig   map[string]string
}

// AIConfig contains AI provider configuration
type AIConfig struct {
	DefaultProvider string // ollama, openai, gemini, claude
	Ollama          OllamaConfig
	OpenAI          OpenAIConfig
	Gemini          GeminiConfig
	Claude          ClaudeConfig
}

// OllamaConfig for Ollama AI provider
type OllamaConfig struct {
	Enabled  bool
	Host     string
	Model    string
}

// OpenAIConfig for OpenAI provider
type OpenAIConfig struct {
	Enabled bool
	APIKey  string
	Model   string
}

// GeminiConfig for Google Gemini provider
type GeminiConfig struct {
	Enabled bool
	APIKey  string
	Model   string
}

// ClaudeConfig for Anthropic Claude provider
type ClaudeConfig struct {
	Enabled bool
	APIKey  string
	Model   string
}

// StorageConfig contains file storage configuration
type StorageConfig struct {
	Type      string // local, s3
	LocalPath string
	S3Bucket  string
	S3Region  string
	S3Key     string
	S3Secret  string
}

// LoggingConfig contains logging configuration
type LoggingConfig struct {
	Level  string
	Format string // json, console
}

// Load reads configuration from environment variables and config file
func Load() (*Config, error) {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath(".")
	viper.AddConfigPath("./config")
	viper.AddConfigPath("/etc/space-food")

	// Set defaults
	setDefaults()

	// Read config file (optional)
	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return nil, fmt.Errorf("error reading config file: %w", err)
		}
	}

	// Override with environment variables
	viper.SetEnvPrefix("SPACE_FOOD")
	viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	viper.AutomaticEnv()

	var cfg Config
	if err := viper.Unmarshal(&cfg); err != nil {
		return nil, fmt.Errorf("error unmarshaling config: %w", err)
	}

	return &cfg, nil
}

func setDefaults() {
	// Server defaults
	viper.SetDefault("server.host", "0.0.0.0")
	viper.SetDefault("server.port", 8080)
	viper.SetDefault("server.environment", "development")

	// Database defaults
	viper.SetDefault("database.type", "postgres")
	viper.SetDefault("database.host", "localhost")
	viper.SetDefault("database.port", 5432)
	viper.SetDefault("database.name", "space_food")
	viper.SetDefault("database.user", "postgres")
	viper.SetDefault("database.sslmode", "disable")
	viper.SetDefault("database.maxconns", 25)
	viper.SetDefault("database.minconns", 5)
	viper.SetDefault("database.sqlitepath", "./data/space_food.db")

	// Auth defaults
	viper.SetDefault("auth.type", "argon2")
	viper.SetDefault("auth.jwtexpiry", 15)
	viper.SetDefault("auth.refreshexpiry", 7)
	viper.SetDefault("auth.argon2memory", 65536)
	viper.SetDefault("auth.argon2time", 3)
	viper.SetDefault("auth.argon2threads", 4)

	// AI defaults
	viper.SetDefault("ai.defaultprovider", "ollama")
	viper.SetDefault("ai.ollama.enabled", true)
	viper.SetDefault("ai.ollama.host", "http://localhost:11434")
	viper.SetDefault("ai.ollama.model", "llama2")
	viper.SetDefault("ai.openai.enabled", false)
	viper.SetDefault("ai.openai.model", "gpt-3.5-turbo")
	viper.SetDefault("ai.gemini.enabled", false)
	viper.SetDefault("ai.gemini.model", "gemini-pro")
	viper.SetDefault("ai.claude.enabled", false)
	viper.SetDefault("ai.claude.model", "claude-3-sonnet-20240229")

	// Storage defaults
	viper.SetDefault("storage.type", "local")
	viper.SetDefault("storage.localpath", "./uploads")

	// Logging defaults
	viper.SetDefault("logging.level", "info")
	viper.SetDefault("logging.format", "json")
}
