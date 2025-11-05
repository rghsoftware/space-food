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

package auth

import (
	"context"
	"time"
)

// AuthProvider defines the contract for authentication implementations
type AuthProvider interface {
	// Register creates a new user account
	Register(ctx context.Context, req RegisterRequest) (*User, error)

	// Login authenticates a user and returns tokens
	Login(ctx context.Context, req LoginRequest) (*AuthResponse, error)

	// RefreshToken generates new access token from refresh token
	RefreshToken(ctx context.Context, refreshToken string) (*AuthResponse, error)

	// ValidateToken validates an access token and returns user info
	ValidateToken(ctx context.Context, token string) (*User, error)

	// Logout invalidates user tokens
	Logout(ctx context.Context, userID string) error

	// ChangePassword changes user password
	ChangePassword(ctx context.Context, userID string, oldPassword, newPassword string) error

	// ResetPassword initiates password reset
	ResetPassword(ctx context.Context, email string) error

	// VerifyEmail verifies user email
	VerifyEmail(ctx context.Context, token string) error
}

// User represents an authenticated user
type User struct {
	ID            string
	Email         string
	FirstName     string
	LastName      string
	EmailVerified bool
	Active        bool
	CreatedAt     time.Time
}

// RegisterRequest contains user registration data
type RegisterRequest struct {
	Email     string
	Password  string
	FirstName string
	LastName  string
}

// LoginRequest contains user login credentials
type LoginRequest struct {
	Email    string
	Password string
}

// AuthResponse contains authentication tokens and user info
type AuthResponse struct {
	AccessToken  string
	RefreshToken string
	ExpiresIn    int // seconds
	User         *User
}

// TokenClaims represents JWT token claims
type TokenClaims struct {
	UserID    string
	Email     string
	IssuedAt  time.Time
	ExpiresAt time.Time
}
