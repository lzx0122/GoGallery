package main

import (
	"errors"
	"log"
)

// MockGoogleAuth 用於開發環境測試，略過真實 Google 驗證
// 實作 user.GoogleAuthenticator 介面
type MockGoogleAuth struct{}

func (m *MockGoogleAuth) FetchJWKs() ([]map[string]interface{}, error) {
	log.Println("[Dev Mode] Mock FetchJWKs called")
	return []map[string]interface{}{}, nil
}

func (m *MockGoogleAuth) VerifyIDToken(token string, keys []map[string]interface{}) (string, string, error) {
	log.Printf("[Dev Mode] Mock VerifyIDToken called with token: %s", token)
	
	// 模擬特定 token 成功，其他失敗
	if token == "dev-token" {
		return "dev-google-sub-123", "dev@example.com", nil
	}
	
	return "", "", errors.New("invalid dev token")
}
