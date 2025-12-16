package auth

import (
	"crypto"
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"errors"
	"io"
	"math/big"
	"net/http"
	"strings"
	"sync"
	"time"
)

// GoogleAuthService 負責 Google ID Token 驗證與 JWKs 取得
//
// 單一職責原則：只處理 Google 驗證，不處理 DB
//
// @author: Copilot (繁體中文註解)
type GoogleAuthService struct {
	JWKsURL string

	// Cache fields
	jwksCache []map[string]interface{}
	jwksExp   time.Time
	mu        sync.RWMutex
}

// FetchJWKs 取得 Google JWKs 公鑰 (含快取機制)
func (s *GoogleAuthService) FetchJWKs() ([]map[string]interface{}, error) {
	s.mu.RLock()
	if time.Now().Before(s.jwksExp) && len(s.jwksCache) > 0 {
		defer s.mu.RUnlock()
		return s.jwksCache, nil
	}
	s.mu.RUnlock()

	s.mu.Lock()
	defer s.mu.Unlock()

	// Double check
	if time.Now().Before(s.jwksExp) && len(s.jwksCache) > 0 {
		return s.jwksCache, nil
	}

	resp, err := http.Get(s.JWKsURL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	var jwks struct {
		Keys []map[string]interface{} `json:"keys"`
	}
	if err := json.Unmarshal(body, &jwks); err != nil {
		return nil, err
	}

	s.jwksCache = jwks.Keys
	// Google JWKs rotate roughly once a day, cache for 1 hour is safe
	s.jwksExp = time.Now().Add(1 * time.Hour)

	return jwks.Keys, nil
}

// VerifyIDToken 驗證 Google ID Token 並回傳 sub/email
func (s *GoogleAuthService) VerifyIDToken(token string, keys []map[string]interface{}) (string, string, error) {
	claims, err := verifyGoogleJWT(token, keys)
	if err != nil {
		return "", "", err
	}
	sub, ok1 := claims["sub"].(string)
	email, ok2 := claims["email"].(string)
	if !ok1 || !ok2 {
		return "", "", errors.New("token missing sub/email")
	}
	return sub, email, nil
}

// 驗證 JWT 簽章與解析 claims
func verifyGoogleJWT(token string, keys []map[string]interface{}) (map[string]interface{}, error) {
	parts := strings.Split(token, ".")
	if len(parts) != 3 {
		return nil, errors.New("invalid JWT format")
	}
	headerJSON, err := decodeSegment(parts[0])
	if err != nil {
		return nil, err
	}
	var header map[string]interface{}
	if err := json.Unmarshal(headerJSON, &header); err != nil {
		return nil, err
	}
	kid, _ := header["kid"].(string)
	alg, _ := header["alg"].(string)
	if alg != "RS256" {
		return nil, errors.New("only RS256 supported")
	}
	var jwk map[string]interface{}
	for _, k := range keys {
		if k["kid"] == kid {
			jwk = k
			break
		}
	}
	if jwk == nil {
		return nil, errors.New("JWK not found for kid")
	}
	n, _ := jwk["n"].(string)
	e, _ := jwk["e"].(string)
	pub, err := parseRSAPublicKey(n, e)
	if err != nil {
		return nil, err
	}
	signed := strings.Join(parts[0:2], ".")
	sig, err := decodeSegment(parts[2])
	if err != nil {
		return nil, err
	}
	h := crypto.SHA256.New()
	h.Write([]byte(signed))
	digest := h.Sum(nil)
	if err := rsa.VerifyPKCS1v15(pub, crypto.SHA256, digest, sig); err != nil {
		return nil, errors.New("invalid signature")
	}
	payloadJSON, err := decodeSegment(parts[1])
	if err != nil {
		return nil, err
	}
	var claims map[string]interface{}
	if err := json.Unmarshal(payloadJSON, &claims); err != nil {
		return nil, err
	}
	return claims, nil
}

// base64url decode helper
func decodeSegment(seg string) ([]byte, error) {
	if l := len(seg) % 4; l > 0 {
		seg += strings.Repeat("=", 4-l)
	}
	return base64.URLEncoding.DecodeString(seg)
}

// JWK n/e 轉換為 *rsa.PublicKey
func parseRSAPublicKey(nB64, eB64 string) (*rsa.PublicKey, error) {
	nBytes, err := decodeSegment(nB64)
	if err != nil {
		return nil, err
	}
	eBytes, err := decodeSegment(eB64)
	if err != nil {
		return nil, err
	}
	n := new(big.Int).SetBytes(nBytes)
	e := 0
	for _, b := range eBytes {
		e = e<<8 + int(b)
	}
	return &rsa.PublicKey{N: n, E: e}, nil
}
