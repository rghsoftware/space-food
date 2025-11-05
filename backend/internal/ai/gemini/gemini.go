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

package gemini

import (
	"context"
	"fmt"

	"github.com/google/generative-ai-go/genai"
	"github.com/rghsoftware/space-food/internal/ai"
	"google.golang.org/api/option"
)

// Provider implements the AI provider interface for Google Gemini
type Provider struct {
	client *genai.Client
	model  string
}

// NewProvider creates a new Gemini provider
func NewProvider(ctx context.Context, apiKey, model string) (*Provider, error) {
	client, err := genai.NewClient(ctx, option.WithAPIKey(apiKey))
	if err != nil {
		return nil, fmt.Errorf("failed to create gemini client: %w", err)
	}

	return &Provider{
		client: client,
		model:  model,
	}, nil
}

// Close closes the Gemini client
func (p *Provider) Close() error {
	return p.client.Close()
}

// Generate generates text completion based on a prompt
func (p *Provider) Generate(ctx context.Context, req ai.GenerateRequest) (*ai.GenerateResponse, error) {
	model := p.client.GenerativeModel(p.model)

	if req.Temperature > 0 {
		temp := float32(req.Temperature)
		model.Temperature = &temp
	}

	if req.MaxTokens > 0 {
		maxTokens := int32(req.MaxTokens)
		model.MaxOutputTokens = &maxTokens
	}

	prompt := req.Prompt
	if req.SystemMsg != "" {
		prompt = req.SystemMsg + "\n\n" + prompt
	}

	resp, err := model.GenerateContent(ctx, genai.Text(prompt))
	if err != nil {
		return nil, fmt.Errorf("gemini generate failed: %w", err)
	}

	if len(resp.Candidates) == 0 || len(resp.Candidates[0].Content.Parts) == 0 {
		return nil, fmt.Errorf("no content generated")
	}

	text := fmt.Sprintf("%v", resp.Candidates[0].Content.Parts[0])

	return &ai.GenerateResponse{
		Text:         text,
		FinishReason: string(resp.Candidates[0].FinishReason),
	}, nil
}

// Chat performs a chat-based conversation
func (p *Provider) Chat(ctx context.Context, req ai.ChatRequest) (*ai.ChatResponse, error) {
	model := p.client.GenerativeModel(p.model)

	if req.Temperature > 0 {
		temp := float32(req.Temperature)
		model.Temperature = &temp
	}

	if req.MaxTokens > 0 {
		maxTokens := int32(req.MaxTokens)
		model.MaxOutputTokens = &maxTokens
	}

	chat := model.StartChat()

	// Add previous messages to chat history
	for _, msg := range req.Messages {
		var role string
		if msg.Role == "user" {
			role = "user"
		} else {
			role = "model"
		}

		chat.History = append(chat.History, &genai.Content{
			Parts: []genai.Part{genai.Text(msg.Content)},
			Role:  role,
		})
	}

	// Get the last user message
	if len(req.Messages) == 0 {
		return nil, fmt.Errorf("no messages provided")
	}

	lastMsg := req.Messages[len(req.Messages)-1]
	resp, err := chat.SendMessage(ctx, genai.Text(lastMsg.Content))
	if err != nil {
		return nil, fmt.Errorf("gemini chat failed: %w", err)
	}

	if len(resp.Candidates) == 0 || len(resp.Candidates[0].Content.Parts) == 0 {
		return nil, fmt.Errorf("no content generated")
	}

	text := fmt.Sprintf("%v", resp.Candidates[0].Content.Parts[0])

	return &ai.ChatResponse{
		Message: ai.Message{
			Role:    "assistant",
			Content: text,
		},
		FinishReason: string(resp.Candidates[0].FinishReason),
	}, nil
}

// Stream generates text with streaming response
func (p *Provider) Stream(ctx context.Context, req ai.GenerateRequest, callback func(string) error) error {
	model := p.client.GenerativeModel(p.model)

	if req.Temperature > 0 {
		temp := float32(req.Temperature)
		model.Temperature = &temp
	}

	prompt := req.Prompt
	if req.SystemMsg != "" {
		prompt = req.SystemMsg + "\n\n" + prompt
	}

	iter := model.GenerateContentStream(ctx, genai.Text(prompt))
	for {
		resp, err := iter.Next()
		if err != nil {
			break
		}

		if len(resp.Candidates) > 0 && len(resp.Candidates[0].Content.Parts) > 0 {
			text := fmt.Sprintf("%v", resp.Candidates[0].Content.Parts[0])
			if err := callback(text); err != nil {
				return err
			}
		}
	}

	return nil
}

// GetName returns the provider name
func (p *Provider) GetName() string {
	return "gemini"
}

// IsAvailable checks if the provider is available and configured
func (p *Provider) IsAvailable() bool {
	return p.client != nil
}
