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

package ai

import (
	"context"
	"fmt"

	"github.com/rghsoftware/space-food/internal/ai/claude"
	"github.com/rghsoftware/space-food/internal/ai/gemini"
	"github.com/rghsoftware/space-food/internal/ai/ollama"
	"github.com/rghsoftware/space-food/internal/ai/openai"
	"github.com/rghsoftware/space-food/internal/config"
)

// NewProvider creates an AI provider based on configuration
func NewProvider(ctx context.Context, cfg *config.Config) (Provider, error) {
	switch cfg.AI.DefaultProvider {
	case "ollama":
		if cfg.AI.Ollama.Enabled {
			return ollama.NewProvider(cfg.AI.Ollama.Host, cfg.AI.Ollama.Model), nil
		}
		return nil, fmt.Errorf("ollama is not enabled")

	case "openai":
		if cfg.AI.OpenAI.Enabled {
			return openai.NewProvider(cfg.AI.OpenAI.APIKey, cfg.AI.OpenAI.Model), nil
		}
		return nil, fmt.Errorf("openai is not enabled")

	case "gemini":
		if cfg.AI.Gemini.Enabled {
			return gemini.NewProvider(ctx, cfg.AI.Gemini.APIKey, cfg.AI.Gemini.Model)
		}
		return nil, fmt.Errorf("gemini is not enabled")

	case "claude":
		if cfg.AI.Claude.Enabled {
			return claude.NewProvider(cfg.AI.Claude.APIKey, cfg.AI.Claude.Model), nil
		}
		return nil, fmt.Errorf("claude is not enabled")

	default:
		return nil, fmt.Errorf("unknown AI provider: %s", cfg.AI.DefaultProvider)
	}
}

// GetAvailableProviders returns a list of all configured and available providers
func GetAvailableProviders(ctx context.Context, cfg *config.Config) []Provider {
	var providers []Provider

	if cfg.AI.Ollama.Enabled {
		p := ollama.NewProvider(cfg.AI.Ollama.Host, cfg.AI.Ollama.Model)
		if p.IsAvailable() {
			providers = append(providers, p)
		}
	}

	if cfg.AI.OpenAI.Enabled {
		p := openai.NewProvider(cfg.AI.OpenAI.APIKey, cfg.AI.OpenAI.Model)
		if p.IsAvailable() {
			providers = append(providers, p)
		}
	}

	if cfg.AI.Gemini.Enabled {
		if p, err := gemini.NewProvider(ctx, cfg.AI.Gemini.APIKey, cfg.AI.Gemini.Model); err == nil {
			if p.IsAvailable() {
				providers = append(providers, p)
			}
		}
	}

	if cfg.AI.Claude.Enabled {
		p := claude.NewProvider(cfg.AI.Claude.APIKey, cfg.AI.Claude.Model)
		if p.IsAvailable() {
			providers = append(providers, p)
		}
	}

	return providers
}
