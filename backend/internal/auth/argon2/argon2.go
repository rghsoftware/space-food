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

package argon2

import (
	"context"
	"crypto/rand"
	"crypto/subtle"
	"encoding/base64"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/rghsoftware/space-food/internal/auth"
	"github.com/rghsoftware/space-food/internal/config"
	"github.com/rghsoftware/space-food/internal/database"
	"golang.org/x/crypto/argon2"
)

var (
	ErrInvalidCredentials = errors.New("invalid credentials")
	ErrUserAlreadyExists  = errors.New("user already exists")
	ErrWeakPassword       = errors.New("password does not meet requirements")
)

// Argon2AuthProvider implements authentication using Argon2id
type Argon2AuthProvider struct {
	db            database.Database
	jwtSecret     []byte
	jwtExpiry     time.Duration
	refreshExpiry time.Duration
	argon2Memory  uint32
	argon2Time    uint32
	argon2Threads uint8
	saltLength    uint32
	keyLength     uint32
}

// NewArgon2AuthProvider creates a new Argon2 authentication provider
func NewArgon2AuthProvider(db database.Database, cfg *config.Config) *Argon2AuthProvider {
	return &Argon2AuthProvider{
		db:            db,
		jwtSecret:     []byte(cfg.Auth.JWTSecret),
		jwtExpiry:     time.Duration(cfg.Auth.JWTExpiry) * time.Minute,
		refreshExpiry: time.Duration(cfg.Auth.RefreshExpiry) * 24 * time.Hour,
		argon2Memory:  cfg.Auth.Argon2Memory,
		argon2Time:    cfg.Auth.Argon2Time,
		argon2Threads: cfg.Auth.Argon2Threads,
		saltLength:    16,
		keyLength:     32,
	}
}

// Register creates a new user account
func (a *Argon2AuthProvider) Register(ctx context.Context, req auth.RegisterRequest) (*auth.User, error) {
	// Validate password strength
	if err := validatePassword(req.Password); err != nil {
		return nil, err
	}

	// Check if user already exists
	existingUser, err := a.db.GetUserByEmail(ctx, req.Email)
	if err == nil && existingUser != nil {
		return nil, ErrUserAlreadyExists
	}

	// Hash password
	passwordHash, err := a.hashPassword(req.Password)
	if err != nil {
		return nil, fmt.Errorf("failed to hash password: %w", err)
	}

	// Create user
	now := time.Now()
	dbUser := &database.User{
		ID:            uuid.New().String(),
		Email:         req.Email,
		PasswordHash:  passwordHash,
		FirstName:     req.FirstName,
		LastName:      req.LastName,
		CreatedAt:     now,
		UpdatedAt:     now,
		EmailVerified: false,
		Active:        true,
	}

	if err := a.db.CreateUser(ctx, dbUser); err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	return &auth.User{
		ID:            dbUser.ID,
		Email:         dbUser.Email,
		FirstName:     dbUser.FirstName,
		LastName:      dbUser.LastName,
		EmailVerified: dbUser.EmailVerified,
		Active:        dbUser.Active,
		CreatedAt:     dbUser.CreatedAt,
	}, nil
}

// Login authenticates a user and returns tokens
func (a *Argon2AuthProvider) Login(ctx context.Context, req auth.LoginRequest) (*auth.AuthResponse, error) {
	// Get user by email
	dbUser, err := a.db.GetUserByEmail(ctx, req.Email)
	if err != nil {
		return nil, ErrInvalidCredentials
	}

	// Verify password
	if err := a.verifyPassword(req.Password, dbUser.PasswordHash); err != nil {
		return nil, ErrInvalidCredentials
	}

	// Check if user is active
	if !dbUser.Active {
		return nil, errors.New("account is inactive")
	}

	// Update last login time
	now := time.Now()
	dbUser.LastLoginAt = &now
	if err := a.db.UpdateUser(ctx, dbUser); err != nil {
		// Log error but don't fail login
	}

	// Generate tokens
	accessToken, err := a.generateAccessToken(dbUser)
	if err != nil {
		return nil, fmt.Errorf("failed to generate access token: %w", err)
	}

	refreshToken, err := a.generateRefreshToken(dbUser)
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token: %w", err)
	}

	return &auth.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresIn:    int(a.jwtExpiry.Seconds()),
		User: &auth.User{
			ID:            dbUser.ID,
			Email:         dbUser.Email,
			FirstName:     dbUser.FirstName,
			LastName:      dbUser.LastName,
			EmailVerified: dbUser.EmailVerified,
			Active:        dbUser.Active,
			CreatedAt:     dbUser.CreatedAt,
		},
	}, nil
}

// RefreshToken generates new access token from refresh token
func (a *Argon2AuthProvider) RefreshToken(ctx context.Context, refreshToken string) (*auth.AuthResponse, error) {
	// Validate refresh token
	claims, err := a.validateJWT(refreshToken)
	if err != nil {
		return nil, errors.New("invalid refresh token")
	}

	// Get user
	dbUser, err := a.db.GetUserByID(ctx, claims.UserID)
	if err != nil {
		return nil, errors.New("user not found")
	}

	// Generate new tokens
	accessToken, err := a.generateAccessToken(dbUser)
	if err != nil {
		return nil, fmt.Errorf("failed to generate access token: %w", err)
	}

	newRefreshToken, err := a.generateRefreshToken(dbUser)
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token: %w", err)
	}

	return &auth.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: newRefreshToken,
		ExpiresIn:    int(a.jwtExpiry.Seconds()),
		User: &auth.User{
			ID:            dbUser.ID,
			Email:         dbUser.Email,
			FirstName:     dbUser.FirstName,
			LastName:      dbUser.LastName,
			EmailVerified: dbUser.EmailVerified,
			Active:        dbUser.Active,
			CreatedAt:     dbUser.CreatedAt,
		},
	}, nil
}

// ValidateToken validates an access token and returns user info
func (a *Argon2AuthProvider) ValidateToken(ctx context.Context, token string) (*auth.User, error) {
	claims, err := a.validateJWT(token)
	if err != nil {
		return nil, err
	}

	dbUser, err := a.db.GetUserByID(ctx, claims.UserID)
	if err != nil {
		return nil, errors.New("user not found")
	}

	return &auth.User{
		ID:            dbUser.ID,
		Email:         dbUser.Email,
		FirstName:     dbUser.FirstName,
		LastName:      dbUser.LastName,
		EmailVerified: dbUser.EmailVerified,
		Active:        dbUser.Active,
		CreatedAt:     dbUser.CreatedAt,
	}, nil
}

// Logout invalidates user tokens
func (a *Argon2AuthProvider) Logout(ctx context.Context, userID string) error {
	// In a stateless JWT system, logout is handled client-side
	// For a more secure implementation, maintain a token blacklist
	return nil
}

// ChangePassword changes user password
func (a *Argon2AuthProvider) ChangePassword(ctx context.Context, userID string, oldPassword, newPassword string) error {
	// Validate new password
	if err := validatePassword(newPassword); err != nil {
		return err
	}

	// Get user
	dbUser, err := a.db.GetUserByID(ctx, userID)
	if err != nil {
		return errors.New("user not found")
	}

	// Verify old password
	if err := a.verifyPassword(oldPassword, dbUser.PasswordHash); err != nil {
		return errors.New("invalid old password")
	}

	// Hash new password
	newHash, err := a.hashPassword(newPassword)
	if err != nil {
		return fmt.Errorf("failed to hash password: %w", err)
	}

	// Update user
	dbUser.PasswordHash = newHash
	dbUser.UpdatedAt = time.Now()
	return a.db.UpdateUser(ctx, dbUser)
}

// ResetPassword initiates password reset
func (a *Argon2AuthProvider) ResetPassword(ctx context.Context, email string) error {
	// Implementation would send reset email
	return errors.New("not implemented")
}

// VerifyEmail verifies user email
func (a *Argon2AuthProvider) VerifyEmail(ctx context.Context, token string) error {
	// Implementation would verify email token
	return errors.New("not implemented")
}

// hashPassword generates an Argon2id hash of the password
func (a *Argon2AuthProvider) hashPassword(password string) (string, error) {
	// Generate salt
	salt := make([]byte, a.saltLength)
	if _, err := rand.Read(salt); err != nil {
		return "", err
	}

	// Generate hash
	hash := argon2.IDKey(
		[]byte(password),
		salt,
		a.argon2Time,
		a.argon2Memory,
		a.argon2Threads,
		a.keyLength,
	)

	// Encode as: $argon2id$v=19$m=65536,t=3,p=4$salt$hash
	b64Salt := base64.RawStdEncoding.EncodeToString(salt)
	b64Hash := base64.RawStdEncoding.EncodeToString(hash)

	return fmt.Sprintf(
		"$argon2id$v=%d$m=%d,t=%d,p=%d$%s$%s",
		argon2.Version,
		a.argon2Memory,
		a.argon2Time,
		a.argon2Threads,
		b64Salt,
		b64Hash,
	), nil
}

// verifyPassword verifies a password against an Argon2id hash
func (a *Argon2AuthProvider) verifyPassword(password, encodedHash string) error {
	// Parse encoded hash
	parts := strings.Split(encodedHash, "$")
	if len(parts) != 6 {
		return errors.New("invalid hash format")
	}

	var memory uint32
	var time uint32
	var threads uint8
	_, err := fmt.Sscanf(parts[3], "m=%d,t=%d,p=%d", &memory, &time, &threads)
	if err != nil {
		return err
	}

	salt, err := base64.RawStdEncoding.DecodeString(parts[4])
	if err != nil {
		return err
	}

	expectedHash, err := base64.RawStdEncoding.DecodeString(parts[5])
	if err != nil {
		return err
	}

	// Generate hash with same parameters
	hash := argon2.IDKey(
		[]byte(password),
		salt,
		time,
		memory,
		threads,
		uint32(len(expectedHash)),
	)

	// Compare hashes
	if subtle.ConstantTimeCompare(hash, expectedHash) != 1 {
		return errors.New("password mismatch")
	}

	return nil
}

// validatePassword validates password strength
func validatePassword(password string) error {
	if len(password) < 12 {
		return ErrWeakPassword
	}
	// Additional password requirements can be added here
	return nil
}
