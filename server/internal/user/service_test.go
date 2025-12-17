package user

import (
	"context"
	"errors"
	"testing"

	"github.com/DATA-DOG/go-sqlmock"
)

// MockGoogleAuth implements GoogleAuthenticator
type MockGoogleAuth struct {
	FetchJWKsFunc     func() ([]map[string]interface{}, error)
	VerifyIDTokenFunc func(token string, keys []map[string]interface{}) (string, string, string, string, error)
}

func (m *MockGoogleAuth) FetchJWKs() ([]map[string]interface{}, error) {
	return m.FetchJWKsFunc()
}

func (m *MockGoogleAuth) VerifyIDToken(token string, keys []map[string]interface{}) (string, string, string, string, error) {
	return m.VerifyIDTokenFunc(token, keys)
}

func TestUpsertByGoogle(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("an error '%s' was not expected when opening a stub database connection", err)
	}
	defer db.Close()

	mockAuth := &MockGoogleAuth{
		FetchJWKsFunc: func() ([]map[string]interface{}, error) {
			return []map[string]interface{}{{"kid": "1"}}, nil
		},
		VerifyIDTokenFunc: func(token string, keys []map[string]interface{}) (string, string, string, string, error) {
			if token == "valid_token" {
				return "google_123", "test@example.com", "Test User", "http://avatar.com", nil
			}
			return "", "", "", "", errors.New("invalid token")
		},
	}

	s := &Service{
		DB:         db,
		GoogleAuth: mockAuth,
	}

	// Test Success
	// Note: sqlmock uses regex for query matching
	mock.ExpectExec("INSERT INTO users").
		WithArgs("google_123", "test@example.com").
		WillReturnResult(sqlmock.NewResult(1, 1))

	sub, email, name, picture, err := s.UpsertByGoogle(context.Background(), "valid_token")
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
	if sub != "google_123" || email != "test@example.com" || name != "Test User" || picture != "http://avatar.com" {
		t.Errorf("unexpected result: %s, %s, %s, %s", sub, email, name, picture)
	}

	// Test Auth Failure
	_, _, _, _, err = s.UpsertByGoogle(context.Background(), "invalid_token")
	if err == nil {
		t.Error("expected error, got nil")
	}

	// Ensure all expectations were met
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("there were unfulfilled expectations: %s", err)
	}
}
