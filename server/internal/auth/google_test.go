package auth

import (
	"crypto/rand"
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"math/big"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

func TestFetchJWKs(t *testing.T) {
	// Mock JWKs response
	mockJWKs := map[string]interface{}{
		"keys": []map[string]interface{}{
			{"kid": "123", "n": "abc", "e": "def"},
		},
	}
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(mockJWKs)
	}))
	defer server.Close()

	s := &GoogleAuthService{JWKsURL: server.URL}
	keys, err := s.FetchJWKs()
	if err != nil {
		t.Fatalf("FetchJWKs failed: %v", err)
	}
	if len(keys) != 1 {
		t.Errorf("expected 1 key, got %d", len(keys))
	}
	if keys[0]["kid"] != "123" {
		t.Errorf("expected kid 123, got %v", keys[0]["kid"])
	}

	// Test Caching
	// Stop server to prove cache is working
	server.Close()
	keys2, err := s.FetchJWKs()
	if err != nil {
		t.Fatalf("FetchJWKs cache failed: %v", err)
	}
	if len(keys2) != 1 {
		t.Errorf("expected 1 key from cache, got %d", len(keys2))
	}
}

func TestVerifyIDToken(t *testing.T) {
	// Generate RSA Key
	privateKey, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatal(err)
	}
	publicKey := &privateKey.PublicKey

	// Create JWK from Public Key
	n := base64.URLEncoding.EncodeToString(publicKey.N.Bytes())
	eBytes := big.NewInt(int64(publicKey.E)).Bytes()
	e := base64.URLEncoding.EncodeToString(eBytes)

	jwk := map[string]interface{}{
		"kid": "test-key",
		"n":   n,
		"e":   e,
		"alg": "RS256",
	}
	keys := []map[string]interface{}{jwk}

	// Create Token
	token := jwt.NewWithClaims(jwt.SigningMethodRS256, jwt.MapClaims{
		"sub":   "1234567890",
		"email": "test@example.com",
		"exp":   time.Now().Add(time.Hour).Unix(),
	})
	token.Header["kid"] = "test-key"
	tokenString, err := token.SignedString(privateKey)
	if err != nil {
		t.Fatal(err)
	}

	s := &GoogleAuthService{}
	sub, email, _, _, err := s.VerifyIDToken(tokenString, keys)
	if err != nil {
		t.Fatalf("VerifyIDToken failed: %v", err)
	}
	if sub != "1234567890" {
		t.Errorf("expected sub 1234567890, got %s", sub)
	}
	if email != "test@example.com" {
		t.Errorf("expected email test@example.com, got %s", email)
	}
}
