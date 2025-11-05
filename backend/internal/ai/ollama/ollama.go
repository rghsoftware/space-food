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

package ollama

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

// Provider implements the AI provider interface for Ollama
type Provider struct {
	host   string
	model  string
	client *http.Client
}

// NewProvider creates a new Ollama provider
func NewProvider(host, model string) *Provider {
	return &Provider{
		host:  host,
		model: model,
		client: &http.Client{
			Timeout: 120 * time.Second,
		},
	}
}

// Generate generates text completion based on a prompt
func (p *Provider) Generate(ctx context.Context, req ai.GenerateRequest) (*ai.GenerateResponse, error) {
	prompt := req.Prompt
	if req.SystemMsg != "" {
		prompt = req.SystemMsg + "\n\n" + prompt
	}

	ollamaReq := map[string]interface{}{
		"model":  p.model,
		"prompt": prompt,
		"stream": false,
	}

	if req.MaxTokens > 0 {
		ollamaReq["options"] = map[string]interface{}{
			"num_predict": req.MaxTokens,
		}
	}

	if req.Temperature > 0 {
		options := ollamaReq["options"].(map[string]interface{})
		options["temperature"] = req.Temperature
	}

	body, err := json.Marshal(ollamaReq)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	httpReq, err := http.NewRequestWithContext(ctx, "POST", p.host+"/api/generate", bytes.NewBuffer(body))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}
	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := p.client.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("ollama returned status %d: %s", resp.StatusCode, string(body))
	}

	var ollamaResp struct {
		Response string `json:"response"`
		Done     bool   `json:"done"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&ollamaResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &ai.GenerateResponse{
		Text:         ollamaResp.Response,
		FinishReason: "stop",
	}, nil
}

// Chat performs a chat-based conversation
func (p *Provider) Chat(ctx context.Context, req ai.ChatRequest) (*ai.ChatResponse, error) {
	messages := make([]map[string]string, len(req.Messages))
	for i, msg := range req.Messages {
		messages[i] = map[string]string{
			"role":    msg.Role,
			"content": msg.Content,
		}
	}

	ollamaReq := map[string]interface{}{
		"model":    p.model,
		"messages": messages,
		"stream":   false,
	}

	if req.MaxTokens > 0 {
		ollamaReq["options"] = map[string]interface{}{
			"num_predict": req.MaxTokens,
		}
	}

	body, err := json.Marshal(ollamaReq)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	httpReq, err := http.NewRequestWithContext(ctx, "POST", p.host+"/api/chat", bytes.NewBuffer(body))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}
	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := p.client.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("ollama returned status %d: %s", resp.StatusCode, string(body))
	}

	var ollamaResp struct {
		Message struct {
			Role    string `json:"role"`
			Content string `json:"content"`
		} `json:"message"`
		Done bool `json:"done"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&ollamaResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &ai.ChatResponse{
		Message: ai.Message{
			Role:    ollamaResp.Message.Role,
			Content: ollamaResp.Message.Content,
		},
		FinishReason: "stop",
	}, nil
}

// Stream generates text with streaming response
func (p *Provider) Stream(ctx context.Context, req ai.GenerateRequest, callback func(string) error) error {
	prompt := req.Prompt
	if req.SystemMsg != "" {
		prompt = req.SystemMsg + "\n\n" + prompt
	}

	ollamaReq := map[string]interface{}{
		"model":  p.model,
		"prompt": prompt,
		"stream": true,
	}

	body, err := json.Marshal(ollamaReq)
	if err != nil {
		return fmt.Errorf("failed to marshal request: %w", err)
	}

	httpReq, err := http.NewRequestWithContext(ctx, "POST", p.host+"/api/generate", bytes.NewBuffer(body))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}
	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := p.client.Do(httpReq)
	if err != nil {
		return fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	decoder := json.NewDecoder(resp.Body)
	for {
		var chunk struct {
			Response string `json:"response"`
			Done     bool   `json:"done"`
		}

		if err := decoder.Decode(&chunk); err != nil {
			if err == io.EOF {
				break
			}
			return fmt.Errorf("failed to decode chunk: %w", err)
		}

		if chunk.Response != "" {
			if err := callback(chunk.Response); err != nil {
				return err
			}
		}

		if chunk.Done {
			break
		}
	}

	return nil
}

// GetName returns the provider name
func (p *Provider) GetName() string {
	return "ollama"
}

// IsAvailable checks if the provider is available and configured
func (p *Provider) IsAvailable() bool {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, "GET", p.host+"/api/tags", nil)
	if err != nil {
		return false
	}

	resp, err := p.client.Do(req)
	if err != nil {
		return false
	}
	defer resp.Body.Close()

	return resp.StatusCode == http.StatusOK
}
