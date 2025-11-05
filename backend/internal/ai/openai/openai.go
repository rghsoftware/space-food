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

package openai

import (
	"context"
	"fmt"

	"github.com/rghsoftware/space-food/internal/ai"
	"github.com/sashabaranov/go-openai"
)

// Provider implements the AI provider interface for OpenAI
type Provider struct {
	client *openai.Client
	model  string
}

// NewProvider creates a new OpenAI provider
func NewProvider(apiKey, model string) *Provider {
	return &Provider{
		client: openai.NewClient(apiKey),
		model:  model,
	}
}

// Generate generates text completion based on a prompt
func (p *Provider) Generate(ctx context.Context, req ai.GenerateRequest) (*ai.GenerateResponse, error) {
	messages := []openai.ChatCompletionMessage{
		{
			Role:    openai.ChatMessageRoleUser,
			Content: req.Prompt,
		},
	}

	if req.SystemMsg != "" {
		messages = append([]openai.ChatCompletionMessage{
			{
				Role:    openai.ChatMessageRoleSystem,
				Content: req.SystemMsg,
			},
		}, messages...)
	}

	chatReq := openai.ChatCompletionRequest{
		Model:    p.model,
		Messages: messages,
	}

	if req.MaxTokens > 0 {
		chatReq.MaxTokens = req.MaxTokens
	}

	if req.Temperature > 0 {
		chatReq.Temperature = float32(req.Temperature)
	}

	resp, err := p.client.CreateChatCompletion(ctx, chatReq)
	if err != nil {
		return nil, fmt.Errorf("openai request failed: %w", err)
	}

	if len(resp.Choices) == 0 {
		return nil, fmt.Errorf("no choices returned from openai")
	}

	return &ai.GenerateResponse{
		Text:         resp.Choices[0].Message.Content,
		TokensUsed:   resp.Usage.TotalTokens,
		FinishReason: string(resp.Choices[0].FinishReason),
	}, nil
}

// Chat performs a chat-based conversation
func (p *Provider) Chat(ctx context.Context, req ai.ChatRequest) (*ai.ChatResponse, error) {
	messages := make([]openai.ChatCompletionMessage, len(req.Messages))
	for i, msg := range req.Messages {
		messages[i] = openai.ChatCompletionMessage{
			Role:    msg.Role,
			Content: msg.Content,
		}
	}

	if req.SystemMsg != "" {
		messages = append([]openai.ChatCompletionMessage{
			{
				Role:    openai.ChatMessageRoleSystem,
				Content: req.SystemMsg,
			},
		}, messages...)
	}

	chatReq := openai.ChatCompletionRequest{
		Model:    p.model,
		Messages: messages,
	}

	if req.MaxTokens > 0 {
		chatReq.MaxTokens = req.MaxTokens
	}

	if req.Temperature > 0 {
		chatReq.Temperature = float32(req.Temperature)
	}

	resp, err := p.client.CreateChatCompletion(ctx, chatReq)
	if err != nil {
		return nil, fmt.Errorf("openai request failed: %w", err)
	}

	if len(resp.Choices) == 0 {
		return nil, fmt.Errorf("no choices returned from openai")
	}

	return &ai.ChatResponse{
		Message: ai.Message{
			Role:    resp.Choices[0].Message.Role,
			Content: resp.Choices[0].Message.Content,
		},
		TokensUsed:   resp.Usage.TotalTokens,
		FinishReason: string(resp.Choices[0].FinishReason),
	}, nil
}

// Stream generates text with streaming response
func (p *Provider) Stream(ctx context.Context, req ai.GenerateRequest, callback func(string) error) error {
	messages := []openai.ChatCompletionMessage{
		{
			Role:    openai.ChatMessageRoleUser,
			Content: req.Prompt,
		},
	}

	if req.SystemMsg != "" {
		messages = append([]openai.ChatCompletionMessage{
			{
				Role:    openai.ChatMessageRoleSystem,
				Content: req.SystemMsg,
			},
		}, messages...)
	}

	chatReq := openai.ChatCompletionRequest{
		Model:    p.model,
		Messages: messages,
		Stream:   true,
	}

	stream, err := p.client.CreateChatCompletionStream(ctx, chatReq)
	if err != nil {
		return fmt.Errorf("failed to create stream: %w", err)
	}
	defer stream.Close()

	for {
		response, err := stream.Recv()
		if err != nil {
			break
		}

		if len(response.Choices) > 0 {
			content := response.Choices[0].Delta.Content
			if content != "" {
				if err := callback(content); err != nil {
					return err
				}
			}
		}
	}

	return nil
}

// GetName returns the provider name
func (p *Provider) GetName() string {
	return "openai"
}

// IsAvailable checks if the provider is available and configured
func (p *Provider) IsAvailable() bool {
	// Simple check - could be enhanced with actual API call
	return p.client != nil
}
