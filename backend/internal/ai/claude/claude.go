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

package claude

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/rghsoftware/space-food/internal/ai"
)

// Provider implements the AI provider interface for Anthropic Claude
type Provider struct {
	apiKey string
	model  string
	client *http.Client
}

// NewProvider creates a new Claude provider
func NewProvider(apiKey, model string) *Provider {
	return &Provider{
		apiKey: apiKey,
		model:  model,
		client: &http.Client{
			Timeout: 120 * time.Second,
		},
	}
}

type claudeRequest struct {
	Model       string          `json:"model"`
	Messages    []claudeMessage `json:"messages"`
	MaxTokens   int             `json:"max_tokens"`
	Temperature float64         `json:"temperature,omitempty"`
	System      string          `json:"system,omitempty"`
}

type claudeMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type claudeResponse struct {
	Content []struct {
		Text string `json:"text"`
	} `json:"content"`
	StopReason string `json:"stop_reason"`
	Usage      struct {
		InputTokens  int `json:"input_tokens"`
		OutputTokens int `json:"output_tokens"`
	} `json:"usage"`
}

// Generate generates text completion based on a prompt
func (p *Provider) Generate(ctx context.Context, req ai.GenerateRequest) (*ai.GenerateResponse, error) {
	claudeReq := claudeRequest{
		Model: p.model,
		Messages: []claudeMessage{
			{
				Role:    "user",
				Content: req.Prompt,
			},
		},
		MaxTokens: 4096,
	}

	if req.MaxTokens > 0 {
		claudeReq.MaxTokens = req.MaxTokens
	}

	if req.Temperature > 0 {
		claudeReq.Temperature = req.Temperature
	}

	if req.SystemMsg != "" {
		claudeReq.System = req.SystemMsg
	}

	body, err := json.Marshal(claudeReq)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	httpReq, err := http.NewRequestWithContext(ctx, "POST", "https://api.anthropic.com/v1/messages", bytes.NewBuffer(body))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("x-api-key", p.apiKey)
	httpReq.Header.Set("anthropic-version", "2023-06-01")

	resp, err := p.client.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("claude returned status %d: %s", resp.StatusCode, string(body))
	}

	var claudeResp claudeResponse
	if err := json.NewDecoder(resp.Body).Decode(&claudeResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	if len(claudeResp.Content) == 0 {
		return nil, fmt.Errorf("no content in response")
	}

	return &ai.GenerateResponse{
		Text:         claudeResp.Content[0].Text,
		TokensUsed:   claudeResp.Usage.InputTokens + claudeResp.Usage.OutputTokens,
		FinishReason: claudeResp.StopReason,
	}, nil
}

// Chat performs a chat-based conversation
func (p *Provider) Chat(ctx context.Context, req ai.ChatRequest) (*ai.ChatResponse, error) {
	messages := make([]claudeMessage, len(req.Messages))
	for i, msg := range req.Messages {
		messages[i] = claudeMessage{
			Role:    msg.Role,
			Content: msg.Content,
		}
	}

	claudeReq := claudeRequest{
		Model:     p.model,
		Messages:  messages,
		MaxTokens: 4096,
	}

	if req.MaxTokens > 0 {
		claudeReq.MaxTokens = req.MaxTokens
	}

	if req.Temperature > 0 {
		claudeReq.Temperature = req.Temperature
	}

	if req.SystemMsg != "" {
		claudeReq.System = req.SystemMsg
	}

	body, err := json.Marshal(claudeReq)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	httpReq, err := http.NewRequestWithContext(ctx, "POST", "https://api.anthropic.com/v1/messages", bytes.NewBuffer(body))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("x-api-key", p.apiKey)
	httpReq.Header.Set("anthropic-version", "2023-06-01")

	resp, err := p.client.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("claude returned status %d: %s", resp.StatusCode, string(body))
	}

	var claudeResp claudeResponse
	if err := json.NewDecoder(resp.Body).Decode(&claudeResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	if len(claudeResp.Content) == 0 {
		return nil, fmt.Errorf("no content in response")
	}

	return &ai.ChatResponse{
		Message: ai.Message{
			Role:    "assistant",
			Content: claudeResp.Content[0].Text,
		},
		TokensUsed:   claudeResp.Usage.InputTokens + claudeResp.Usage.OutputTokens,
		FinishReason: claudeResp.StopReason,
	}, nil
}

// Stream generates text with streaming response
func (p *Provider) Stream(ctx context.Context, req ai.GenerateRequest, callback func(string) error) error {
	// Claude streaming would require SSE implementation
	// For now, fall back to non-streaming
	resp, err := p.Generate(ctx, req)
	if err != nil {
		return err
	}
	return callback(resp.Text)
}

// GetName returns the provider name
func (p *Provider) GetName() string {
	return "claude"
}

// IsAvailable checks if the provider is available and configured
func (p *Provider) IsAvailable() bool {
	return p.apiKey != ""
}
