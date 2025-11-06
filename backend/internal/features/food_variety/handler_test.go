/*
 * Space Food - Self-Hosted Meal Planning Application
 * Copyright (C) 2025 RGH Software
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

package food_variety

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
)

// MockService implements Service interface for handler testing
type MockService struct {
	mock.Mock
}

func (m *MockService) TrackFoodConsumption(ctx context.Context, userID uuid.UUID, foodName string) error {
	args := m.Called(ctx, userID, foodName)
	return args.Error(0)
}

func (m *MockService) GetActiveHyperfixations(ctx context.Context, userID uuid.UUID) ([]FoodHyperfixation, error) {
	args := m.Called(ctx, userID)
	return args.Get(0).([]FoodHyperfixation), args.Error(1)
}

func (m *MockService) RecordHyperfixation(ctx context.Context, userID uuid.UUID, foodName, notes string) error {
	args := m.Called(ctx, userID, foodName, notes)
	return args.Error(0)
}

func (m *MockService) GenerateChainSuggestions(ctx context.Context, userID uuid.UUID, foodName string, count int) ([]FoodChainSuggestion, error) {
	args := m.Called(ctx, userID, foodName, count)
	return args.Get(0).([]FoodChainSuggestion), args.Error(1)
}

func (m *MockService) GetUserChainSuggestions(ctx context.Context, userID uuid.UUID, limit, offset int) ([]FoodChainSuggestion, error) {
	args := m.Called(ctx, userID, limit, offset)
	return args.Get(0).([]FoodChainSuggestion), args.Error(1)
}

func (m *MockService) RecordChainFeedback(ctx context.Context, suggestionID uuid.UUID, wasLiked bool, feedback string) error {
	args := m.Called(ctx, suggestionID, wasLiked, feedback)
	return args.Error(0)
}

func (m *MockService) GetVariationIdeas(ctx context.Context, foodName string) ([]FoodVariation, error) {
	args := m.Called(ctx, foodName)
	return args.Get(0).([]FoodVariation), args.Error(1)
}

func (m *MockService) GetVarietyAnalysis(ctx context.Context, userID uuid.UUID) (*VarietyAnalysis, error) {
	args := m.Called(ctx, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*VarietyAnalysis), args.Error(1)
}

func (m *MockService) GetNutritionSettings(ctx context.Context, userID uuid.UUID) (*NutritionTrackingSettings, error) {
	args := m.Called(ctx, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*NutritionTrackingSettings), args.Error(1)
}

func (m *MockService) UpdateNutritionSettings(ctx context.Context, userID uuid.UUID, update UpdateNutritionSettingsRequest) (*NutritionTrackingSettings, error) {
	args := m.Called(ctx, userID, update)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*NutritionTrackingSettings), args.Error(1)
}

func (m *MockService) GetWeeklyInsights(ctx context.Context, userID uuid.UUID) ([]NutritionInsight, error) {
	args := m.Called(ctx, userID)
	return args.Get(0).([]NutritionInsight), args.Error(1)
}

func (m *MockService) GenerateWeeklyInsights(ctx context.Context, userID uuid.UUID) ([]NutritionInsight, error) {
	args := m.Called(ctx, userID)
	return args.Get(0).([]NutritionInsight), args.Error(1)
}

func (m *MockService) DismissInsight(ctx context.Context, insightID uuid.UUID) error {
	args := m.Called(ctx, insightID)
	return args.Error(0)
}

func (m *MockService) CreateRotationSchedule(ctx context.Context, schedule *FoodRotationSchedule) error {
	args := m.Called(ctx, schedule)
	return args.Error(0)
}

func (m *MockService) GetUserRotationSchedules(ctx context.Context, userID uuid.UUID) ([]FoodRotationSchedule, error) {
	args := m.Called(ctx, userID)
	return args.Get(0).([]FoodRotationSchedule), args.Error(1)
}

func (m *MockService) UpdateRotationSchedule(ctx context.Context, schedule *FoodRotationSchedule) error {
	args := m.Called(ctx, schedule)
	return args.Error(0)
}

func (m *MockService) DeleteRotationSchedule(ctx context.Context, scheduleID uuid.UUID) error {
	args := m.Called(ctx, scheduleID)
	return args.Error(0)
}

// Test setup helper
func setupTestHandler() (*gin.Engine, *MockService) {
	gin.SetMode(gin.TestMode)
	router := gin.New()
	mockService := new(MockService)
	handler := NewHandler(mockService)

	// Mock middleware to set user ID
	router.Use(func(c *gin.Context) {
		c.Set("user_id", uuid.New().String())
		c.Next()
	})

	handler.RegisterRoutes(router.Group("/api/v1"))
	return router, mockService
}

// Test GET /food-variety/hyperfixations
func TestHandler_GetActiveHyperfixations(t *testing.T) {
	router, mockService := setupTestHandler()

	userID := uuid.New()
	expectedHyperfixations := []FoodHyperfixation{
		{
			ID:                  uuid.New(),
			UserID:              userID,
			FoodName:            "Chicken nuggets",
			FrequencyCount:      8,
			PeakFrequencyPerDay: 2.5,
			IsActive:            true,
		},
	}

	mockService.On("GetActiveHyperfixations", mock.Anything, mock.AnythingOfType("uuid.UUID")).
		Return(expectedHyperfixations, nil)

	// Execute request
	req := httptest.NewRequest(http.MethodGet, "/api/v1/food-variety/hyperfixations", nil)
	resp := httptest.NewRecorder()
	router.ServeHTTP(resp, req)

	// Assert
	assert.Equal(t, http.StatusOK, resp.Code)

	var result map[string][]FoodHyperfixation
	err := json.Unmarshal(resp.Body.Bytes(), &result)
	require.NoError(t, err)

	assert.Len(t, result["hyperfixations"], 1)
	assert.Equal(t, "Chicken nuggets", result["hyperfixations"][0].FoodName)
	mockService.AssertExpectations(t)
}

// Test POST /food-variety/chain-suggestions/generate
func TestHandler_GenerateChainSuggestions(t *testing.T) {
	tests := []struct {
		name           string
		requestBody    interface{}
		mockReturn     []FoodChainSuggestion
		mockError      error
		expectedStatus int
		checkResponse  func(t *testing.T, body []byte)
	}{
		{
			name: "successful generation",
			requestBody: map[string]interface{}{
				"food_name": "Chicken nuggets",
				"count":     5,
			},
			mockReturn: []FoodChainSuggestion{
				{
					SuggestedFoodName: "Popcorn chicken",
					SimilarityScore:   0.95,
					Reasoning:         "Nearly identical - same crispy chicken.",
				},
			},
			expectedStatus: http.StatusOK,
			checkResponse: func(t *testing.T, body []byte) {
				var result map[string][]FoodChainSuggestion
				err := json.Unmarshal(body, &result)
				require.NoError(t, err)
				assert.Len(t, result["suggestions"], 1)
				assert.Equal(t, "Popcorn chicken", result["suggestions"][0].SuggestedFoodName)
			},
		},
		{
			name: "missing food name",
			requestBody: map[string]interface{}{
				"count": 5,
			},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name: "invalid count",
			requestBody: map[string]interface{}{
				"food_name": "Pizza",
				"count":     -1,
			},
			expectedStatus: http.StatusBadRequest,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			router, mockService := setupTestHandler()

			if tt.mockReturn != nil {
				mockService.On("GenerateChainSuggestions",
					mock.Anything,
					mock.AnythingOfType("uuid.UUID"),
					mock.AnythingOfType("string"),
					mock.AnythingOfType("int")).
					Return(tt.mockReturn, tt.mockError)
			}

			// Prepare request
			bodyBytes, _ := json.Marshal(tt.requestBody)
			req := httptest.NewRequest(http.MethodPost,
				"/api/v1/food-variety/chain-suggestions/generate",
				bytes.NewReader(bodyBytes))
			req.Header.Set("Content-Type", "application/json")
			resp := httptest.NewRecorder()

			// Execute
			router.ServeHTTP(resp, req)

			// Assert
			assert.Equal(t, tt.expectedStatus, resp.Code)
			if tt.checkResponse != nil {
				tt.checkResponse(t, resp.Body.Bytes())
			}
		})
	}
}

// Test PUT /food-variety/chain-suggestions/:suggestion_id/feedback
func TestHandler_RecordChainFeedback(t *testing.T) {
	router, mockService := setupTestHandler()

	suggestionID := uuid.New()
	requestBody := map[string]interface{}{
		"was_liked": true,
		"feedback":  "Loved it! Very similar texture.",
	}

	mockService.On("RecordChainFeedback",
		mock.Anything,
		suggestionID,
		true,
		"Loved it! Very similar texture.").
		Return(nil)

	// Prepare request
	bodyBytes, _ := json.Marshal(requestBody)
	req := httptest.NewRequest(http.MethodPut,
		"/api/v1/food-variety/chain-suggestions/"+suggestionID.String()+"/feedback",
		bytes.NewReader(bodyBytes))
	req.Header.Set("Content-Type", "application/json")
	resp := httptest.NewRecorder()

	// Execute
	router.ServeHTTP(resp, req)

	// Assert
	assert.Equal(t, http.StatusOK, resp.Code)
	mockService.AssertExpectations(t)
}

// Test GET /food-variety/analysis
func TestHandler_GetVarietyAnalysis(t *testing.T) {
	router, mockService := setupTestHandler()

	userID := uuid.New()
	expectedAnalysis := &VarietyAnalysis{
		UniqueFoodsLast7Days:  8,
		UniqueFoodsLast30Days: 15,
		TopFoods: []FoodFrequency{
			{FoodName: "Pizza", Count: 10, Percentage: 25.0},
		},
		ActiveHyperfixations: []FoodHyperfixation{},
		SuggestedRotations: []string{
			"You're doing great with food variety!",
		},
		VarietyScore: 8,
	}

	mockService.On("GetVarietyAnalysis", mock.Anything, mock.AnythingOfType("uuid.UUID")).
		Return(expectedAnalysis, nil)

	// Execute request
	req := httptest.NewRequest(http.MethodGet, "/api/v1/food-variety/analysis", nil)
	resp := httptest.NewRecorder()
	router.ServeHTTP(resp, req)

	// Assert
	assert.Equal(t, http.StatusOK, resp.Code)

	var result VarietyAnalysis
	err := json.Unmarshal(resp.Body.Bytes(), &result)
	require.NoError(t, err)

	assert.Equal(t, 8, result.UniqueFoodsLast7Days)
	assert.Equal(t, 8, result.VarietyScore)
	assert.Len(t, result.TopFoods, 1)
	mockService.AssertExpectations(t)
}

// Test PUT /food-variety/nutrition/settings
func TestHandler_UpdateNutritionSettings(t *testing.T) {
	router, mockService := setupTestHandler()

	userID := uuid.New()
	requestBody := UpdateNutritionSettingsRequest{
		TrackingEnabled:   boolPtr(true),
		ShowCalorieCounts: boolPtr(false),
		ShowMacros:        boolPtr(true),
		FocusNutrients:    []string{"protein", "iron"},
	}

	expectedSettings := &NutritionTrackingSettings{
		ID:                  uuid.New(),
		UserID:              userID,
		TrackingEnabled:     true,
		ShowCalorieCounts:   false,
		ShowMacros:          true,
		ShowMicronutrients:  false,
		FocusNutrients:      []string{"protein", "iron"},
		ShowWeeklySummary:   true,
		ShowDailySummary:    false,
		ReminderStyle:       "gentle",
	}

	mockService.On("UpdateNutritionSettings",
		mock.Anything,
		mock.AnythingOfType("uuid.UUID"),
		mock.AnythingOfType("UpdateNutritionSettingsRequest")).
		Return(expectedSettings, nil)

	// Prepare request
	bodyBytes, _ := json.Marshal(requestBody)
	req := httptest.NewRequest(http.MethodPut,
		"/api/v1/food-variety/nutrition/settings",
		bytes.NewReader(bodyBytes))
	req.Header.Set("Content-Type", "application/json")
	resp := httptest.NewRecorder()

	// Execute
	router.ServeHTTP(resp, req)

	// Assert
	assert.Equal(t, http.StatusOK, resp.Code)

	var result NutritionTrackingSettings
	err := json.Unmarshal(resp.Body.Bytes(), &result)
	require.NoError(t, err)

	assert.True(t, result.TrackingEnabled)
	assert.False(t, result.ShowCalorieCounts)
	assert.True(t, result.ShowMacros)
	assert.Len(t, result.FocusNutrients, 2)
	mockService.AssertExpectations(t)
}

// Test POST /food-variety/rotation-schedules
func TestHandler_CreateRotationSchedule(t *testing.T) {
	tests := []struct {
		name           string
		requestBody    interface{}
		mockError      error
		expectedStatus int
	}{
		{
			name: "valid schedule",
			requestBody: map[string]interface{}{
				"schedule_name": "Weekday Lunches",
				"rotation_days": 7,
				"foods": []map[string]interface{}{
					{"food_name": "Pizza", "portion_size": "2 slices"},
					{"food_name": "Pasta", "portion_size": "1 bowl"},
				},
			},
			expectedStatus: http.StatusCreated,
		},
		{
			name: "missing schedule name",
			requestBody: map[string]interface{}{
				"rotation_days": 7,
				"foods": []map[string]interface{}{
					{"food_name": "Pizza"},
				},
			},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name: "empty foods list",
			requestBody: map[string]interface{}{
				"schedule_name": "Test",
				"rotation_days": 7,
				"foods":         []map[string]interface{}{},
			},
			expectedStatus: http.StatusBadRequest,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			router, mockService := setupTestHandler()

			if tt.expectedStatus == http.StatusCreated {
				mockService.On("CreateRotationSchedule",
					mock.Anything,
					mock.AnythingOfType("*food_variety.FoodRotationSchedule")).
					Return(tt.mockError)
			}

			// Prepare request
			bodyBytes, _ := json.Marshal(tt.requestBody)
			req := httptest.NewRequest(http.MethodPost,
				"/api/v1/food-variety/rotation-schedules",
				bytes.NewReader(bodyBytes))
			req.Header.Set("Content-Type", "application/json")
			resp := httptest.NewRecorder()

			// Execute
			router.ServeHTTP(resp, req)

			// Assert
			assert.Equal(t, tt.expectedStatus, resp.Code)
		})
	}
}

// Test DELETE /food-variety/rotation-schedules/:schedule_id
func TestHandler_DeleteRotationSchedule(t *testing.T) {
	router, mockService := setupTestHandler()

	scheduleID := uuid.New()

	mockService.On("DeleteRotationSchedule", mock.Anything, scheduleID).Return(nil)

	// Execute request
	req := httptest.NewRequest(http.MethodDelete,
		"/api/v1/food-variety/rotation-schedules/"+scheduleID.String(),
		nil)
	resp := httptest.NewRecorder()
	router.ServeHTTP(resp, req)

	// Assert
	assert.Equal(t, http.StatusOK, resp.Code)
	mockService.AssertExpectations(t)
}

// Test error handling
func TestHandler_ErrorHandling(t *testing.T) {
	tests := []struct {
		name           string
		endpoint       string
		method         string
		mockSetup      func(*MockService)
		expectedStatus int
		checkError     func(t *testing.T, body []byte)
	}{
		{
			name:     "service error returns 500",
			endpoint: "/api/v1/food-variety/analysis",
			method:   http.MethodGet,
			mockSetup: func(m *MockService) {
				m.On("GetVarietyAnalysis", mock.Anything, mock.AnythingOfType("uuid.UUID")).
					Return((*VarietyAnalysis)(nil), errors.New("database error"))
			},
			expectedStatus: http.StatusInternalServerError,
			checkError: func(t *testing.T, body []byte) {
				var result map[string]string
				json.Unmarshal(body, &result)
				assert.Contains(t, result["error"], "database error")
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			router, mockService := setupTestHandler()
			tt.mockSetup(mockService)

			req := httptest.NewRequest(tt.method, tt.endpoint, nil)
			resp := httptest.NewRecorder()
			router.ServeHTTP(resp, req)

			assert.Equal(t, tt.expectedStatus, resp.Code)
			if tt.checkError != nil {
				tt.checkError(t, resp.Body.Bytes())
			}
		})
	}
}

// Helper function
func boolPtr(b bool) *bool {
	return &b
}
