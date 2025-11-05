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

package storage

import (
	"context"
	"fmt"
	"io"
	"path/filepath"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/google/uuid"
)

// S3Provider implements file storage on AWS S3
type S3Provider struct {
	client *s3.S3
	bucket string
	region string
}

// NewS3Provider creates a new S3 storage provider
func NewS3Provider(bucket, region, accessKey, secretKey string) (*S3Provider, error) {
	sess, err := session.NewSession(&aws.Config{
		Region:      aws.String(region),
		Credentials: credentials.NewStaticCredentials(accessKey, secretKey, ""),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create AWS session: %w", err)
	}

	return &S3Provider{
		client: s3.New(sess),
		bucket: bucket,
		region: region,
	}, nil
}

// Upload stores a file in S3 and returns its URL
func (p *S3Provider) Upload(ctx context.Context, filename string, contentType string, data io.Reader) (string, error) {
	// Generate unique filename
	ext := filepath.Ext(filename)
	uniqueID := uuid.New().String()
	key := "uploads/" + uniqueID + ext

	// Upload to S3
	_, err := p.client.PutObjectWithContext(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(p.bucket),
		Key:         aws.String(key),
		Body:        aws.ReadSeekCloser(data),
		ContentType: aws.String(contentType),
	})
	if err != nil {
		return "", fmt.Errorf("failed to upload to S3: %w", err)
	}

	return p.GetURL(key), nil
}

// Delete removes a file from S3
func (p *S3Provider) Delete(ctx context.Context, url string) error {
	// Extract key from URL
	key := filepath.Base(url)

	_, err := p.client.DeleteObjectWithContext(ctx, &s3.DeleteObjectInput{
		Bucket: aws.String(p.bucket),
		Key:    aws.String("uploads/" + key),
	})
	if err != nil {
		return fmt.Errorf("failed to delete from S3: %w", err)
	}

	return nil
}

// GetURL returns the public URL for a file in S3
func (p *S3Provider) GetURL(key string) string {
	return fmt.Sprintf("https://%s.s3.%s.amazonaws.com/%s", p.bucket, p.region, key)
}
