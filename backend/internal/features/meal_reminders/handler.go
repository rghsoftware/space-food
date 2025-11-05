package meal_reminders

import (
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// Handler handles HTTP requests for meal reminders
type Handler struct {
	service *Service
}

// NewHandler creates a new meal reminders handler
func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

// RegisterRoutes registers all meal reminder routes
func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	reminders := rg.Group("/meal-reminders")
	{
		reminders.POST("", h.CreateReminder)
		reminders.GET("", h.GetReminders)
		reminders.GET("/:id", h.GetReminder)
		reminders.PUT("/:id", h.UpdateReminder)
		reminders.DELETE("/:id", h.DeleteReminder)
	}

	logs := rg.Group("/meal-logs")
	{
		logs.POST("", h.LogMeal)
		logs.GET("/timeline", h.GetTimeline)
	}

	settings := rg.Group("/eating-timeline-settings")
	{
		settings.GET("", h.GetSettings)
		settings.PUT("", h.UpdateSettings)
	}
}

// CreateReminder handles POST /meal-reminders
func (h *Handler) CreateReminder(c *gin.Context) {
	var req CreateMealReminderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, err := uuid.Parse(c.GetString("user_id"))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user ID"})
		return
	}

	reminder, err := h.service.CreateReminder(c.Request.Context(), userID, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, reminder)
}

// GetReminders handles GET /meal-reminders
func (h *Handler) GetReminders(c *gin.Context) {
	userID, err := uuid.Parse(c.GetString("user_id"))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user ID"})
		return
	}

	reminders, err := h.service.GetUserReminders(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Return empty array instead of null
	if reminders == nil {
		reminders = []MealReminder{}
	}

	c.JSON(http.StatusOK, reminders)
}

// GetReminder handles GET /meal-reminders/:id
func (h *Handler) GetReminder(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid reminder ID"})
		return
	}

	userID, err := uuid.Parse(c.GetString("user_id"))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user ID"})
		return
	}

	reminder, err := h.service.GetReminder(c.Request.Context(), id, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if reminder == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "reminder not found"})
		return
	}

	c.JSON(http.StatusOK, reminder)
}

// UpdateReminder handles PUT /meal-reminders/:id
func (h *Handler) UpdateReminder(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid reminder ID"})
		return
	}

	var req UpdateMealReminderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, err := uuid.Parse(c.GetString("user_id"))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user ID"})
		return
	}

	reminder, err := h.service.UpdateReminder(c.Request.Context(), id, userID, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, reminder)
}

// DeleteReminder handles DELETE /meal-reminders/:id
func (h *Handler) DeleteReminder(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid reminder ID"})
		return
	}

	userID, err := uuid.Parse(c.GetString("user_id"))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user ID"})
		return
	}

	if err := h.service.DeleteReminder(c.Request.Context(), id, userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "reminder deleted"})
}

// LogMeal handles POST /meal-logs
func (h *Handler) LogMeal(c *gin.Context) {
	var req LogMealRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, err := uuid.Parse(c.GetString("user_id"))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user ID"})
		return
	}

	log, err := h.service.LogMeal(c.Request.Context(), userID, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, log)
}

// GetTimeline handles GET /meal-logs/timeline
func (h *Handler) GetTimeline(c *gin.Context) {
	userID, err := uuid.Parse(c.GetString("user_id"))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user ID"})
		return
	}

	// Parse date range from query params (default to last 7 days)
	endDate := time.Now().Add(24 * time.Hour) // Include today fully
	startDate := endDate.AddDate(0, 0, -7)

	if daysStr := c.Query("days"); daysStr != "" {
		var days int
		if _, err := fmt.Sscanf(daysStr, "%d", &days); err == nil && days > 0 && days <= 90 {
			startDate = endDate.AddDate(0, 0, -days)
		}
	}

	timeline, err := h.service.GetEatingTimeline(c.Request.Context(), userID, startDate, endDate)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Return empty array instead of null
	if timeline == nil {
		timeline = []EatingTimeline{}
	}

	c.JSON(http.StatusOK, timeline)
}

// GetSettings handles GET /eating-timeline-settings
func (h *Handler) GetSettings(c *gin.Context) {
	userID, err := uuid.Parse(c.GetString("user_id"))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user ID"})
		return
	}

	settings, err := h.service.GetTimelineSettings(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, settings)
}

// UpdateSettings handles PUT /eating-timeline-settings
func (h *Handler) UpdateSettings(c *gin.Context) {
	var req UpdateTimelineSettingsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, err := uuid.Parse(c.GetString("user_id"))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user ID"})
		return
	}

	settings, err := h.service.UpdateTimelineSettings(c.Request.Context(), userID, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, settings)
}
