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

package household

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/rghsoftware/space-food/internal/database"
	"github.com/rghsoftware/space-food/internal/middleware"
)

// Handler handles household HTTP requests
type Handler struct {
	db database.Database
}

// NewHandler creates a new household handler
func NewHandler(db database.Database) *Handler {
	return &Handler{
		db: db,
	}
}

// RegisterRoutes registers household routes
func (h *Handler) RegisterRoutes(router *gin.RouterGroup) {
	router.POST("", h.CreateHousehold)
	router.GET("", h.ListUserHouseholds)
	router.GET("/:id", h.GetHousehold)
	router.PUT("/:id", h.UpdateHousehold)
	router.DELETE("/:id", h.DeleteHousehold)
	router.GET("/:id/members", h.ListHouseholdMembers)
	router.POST("/:id/members", h.AddHouseholdMember)
	router.DELETE("/:id/members/:userID", h.RemoveHouseholdMember)
}

// CreateHousehold creates a new household
// @Summary Create household
// @Tags households
// @Accept json
// @Produce json
// @Param household body Household true "Household"
// @Success 201 {object} Household
// @Router /households [post]
func (h *Handler) CreateHousehold(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	var household database.Household
	if err := c.ShouldBindJSON(&household); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	household.ID = uuid.New().String()
	household.OwnerID = user.ID
	household.CreatedAt = time.Now()
	household.UpdatedAt = time.Now()

	if err := h.db.CreateHousehold(c.Request.Context(), &household); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Add creator as owner member
	member := &database.HouseholdMember{
		HouseholdID: household.ID,
		UserID:      user.ID,
		Role:        "owner",
		JoinedAt:    time.Now(),
	}

	if err := h.db.AddHouseholdMember(c.Request.Context(), member); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, household)
}

// ListUserHouseholds lists households for the authenticated user
// @Summary List user households
// @Tags households
// @Produce json
// @Success 200 {array} Household
// @Router /households [get]
func (h *Handler) ListUserHouseholds(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	households, err := h.db.GetUserHouseholds(c.Request.Context(), user.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, households)
}

// GetHousehold retrieves a household by ID
// @Summary Get household
// @Tags households
// @Produce json
// @Param id path string true "Household ID"
// @Success 200 {object} Household
// @Router /households/{id} [get]
func (h *Handler) GetHousehold(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	id := c.Param("id")

	household, err := h.db.GetHouseholdByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "household not found"})
		return
	}

	// Verify user is a member
	members, err := h.db.ListHouseholdMembers(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	isMember := false
	for _, member := range members {
		if member.UserID == user.ID {
			isMember = true
			break
		}
	}

	if !isMember {
		c.JSON(http.StatusForbidden, gin.H{"error": "not a member of this household"})
		return
	}

	c.JSON(http.StatusOK, household)
}

// UpdateHousehold updates a household
// @Summary Update household
// @Tags households
// @Accept json
// @Produce json
// @Param id path string true "Household ID"
// @Param household body Household true "Household"
// @Success 200 {object} Household
// @Router /households/{id} [put]
func (h *Handler) UpdateHousehold(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	id := c.Param("id")

	// Verify ownership
	existing, err := h.db.GetHouseholdByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "household not found"})
		return
	}

	if existing.OwnerID != user.ID {
		c.JSON(http.StatusForbidden, gin.H{"error": "only the owner can update household settings"})
		return
	}

	var household database.Household
	if err := c.ShouldBindJSON(&household); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	household.ID = id
	household.OwnerID = existing.OwnerID
	household.UpdatedAt = time.Now()

	if err := h.db.UpdateHousehold(c.Request.Context(), &household); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, household)
}

// DeleteHousehold deletes a household
// @Summary Delete household
// @Tags households
// @Param id path string true "Household ID"
// @Success 204
// @Router /households/{id} [delete]
func (h *Handler) DeleteHousehold(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	id := c.Param("id")

	// Verify ownership
	household, err := h.db.GetHouseholdByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "household not found"})
		return
	}

	if household.OwnerID != user.ID {
		c.JSON(http.StatusForbidden, gin.H{"error": "only the owner can delete the household"})
		return
	}

	if err := h.db.DeleteHousehold(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}

// ListHouseholdMembers lists members of a household
// @Summary List household members
// @Tags households
// @Produce json
// @Param id path string true "Household ID"
// @Success 200 {array} HouseholdMember
// @Router /households/{id}/members [get]
func (h *Handler) ListHouseholdMembers(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	id := c.Param("id")

	// Verify user is a member
	members, err := h.db.ListHouseholdMembers(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	isMember := false
	for _, member := range members {
		if member.UserID == user.ID {
			isMember = true
			break
		}
	}

	if !isMember {
		c.JSON(http.StatusForbidden, gin.H{"error": "not a member of this household"})
		return
	}

	c.JSON(http.StatusOK, members)
}

// AddHouseholdMember adds a member to a household
// @Summary Add household member
// @Tags households
// @Accept json
// @Produce json
// @Param id path string true "Household ID"
// @Param member body object true "Member details"
// @Success 201 {object} HouseholdMember
// @Router /households/{id}/members [post]
func (h *Handler) AddHouseholdMember(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	householdID := c.Param("id")

	// Verify user is owner or admin
	household, err := h.db.GetHouseholdByID(c.Request.Context(), householdID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "household not found"})
		return
	}

	members, err := h.db.ListHouseholdMembers(c.Request.Context(), householdID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	isAuthorized := false
	for _, member := range members {
		if member.UserID == user.ID && (member.Role == "owner" || member.Role == "admin") {
			isAuthorized = true
			break
		}
	}

	if !isAuthorized {
		c.JSON(http.StatusForbidden, gin.H{"error": "only owners and admins can add members"})
		return
	}

	var req struct {
		UserID string `json:"user_id" binding:"required"`
		Role   string `json:"role" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Validate role
	if req.Role != "member" && req.Role != "admin" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "role must be 'member' or 'admin'"})
		return
	}

	// Only owner can add admins
	if req.Role == "admin" && household.OwnerID != user.ID {
		c.JSON(http.StatusForbidden, gin.H{"error": "only the owner can add admins"})
		return
	}

	member := &database.HouseholdMember{
		HouseholdID: householdID,
		UserID:      req.UserID,
		Role:        req.Role,
		JoinedAt:    time.Now(),
	}

	if err := h.db.AddHouseholdMember(c.Request.Context(), member); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, member)
}

// RemoveHouseholdMember removes a member from a household
// @Summary Remove household member
// @Tags households
// @Param id path string true "Household ID"
// @Param userID path string true "User ID"
// @Success 204
// @Router /households/{id}/members/{userID} [delete]
func (h *Handler) RemoveHouseholdMember(c *gin.Context) {
	user, ok := middleware.GetUserFromContext(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	householdID := c.Param("id")
	targetUserID := c.Param("userID")

	// Verify user is owner or admin, or removing themselves
	household, err := h.db.GetHouseholdByID(c.Request.Context(), householdID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "household not found"})
		return
	}

	// Owner cannot be removed
	if targetUserID == household.OwnerID {
		c.JSON(http.StatusForbidden, gin.H{"error": "owner cannot be removed"})
		return
	}

	members, err := h.db.ListHouseholdMembers(c.Request.Context(), householdID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	isAuthorized := false
	for _, member := range members {
		if member.UserID == user.ID {
			// User can remove themselves or if they're owner/admin
			if user.ID == targetUserID || member.Role == "owner" || member.Role == "admin" {
				isAuthorized = true
				break
			}
		}
	}

	if !isAuthorized {
		c.JSON(http.StatusForbidden, gin.H{"error": "not authorized to remove this member"})
		return
	}

	if err := h.db.RemoveHouseholdMember(c.Request.Context(), householdID, targetUserID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}
