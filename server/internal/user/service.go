package user

import (
	"context"
	"database/sql"
)

// GoogleAuthenticator 定義 Google 驗證介面 (Dependency Inversion)
type GoogleAuthenticator interface {
	FetchJWKs() ([]map[string]interface{}, error)
	VerifyIDToken(token string, keys []map[string]interface{}) (string, string, error)
}

// UserService 負責 upsert 使用者
// 單一職責原則：只處理 user 資料表
//
// @author: Copilot (繁體中文註解)
type Service struct {
	DB         *sql.DB
	GoogleAuth GoogleAuthenticator
}

// UpsertByGoogle 驗證 Google Token 並 upsert 使用者
//
// 1. 取得 Google JWKs 公鑰
// 2. 驗證 Token 並取得 sub/email
// 3. upsert 使用者資料（google_sub 唯一）
//
// 回傳: sub, email, error
func (s *Service) UpsertByGoogle(ctx context.Context, token string) (string, string, error) {
	// 取得 Google JWKs 公鑰
	keys, err := s.GoogleAuth.FetchJWKs()
	if err != nil {
		// 取得 JWKs 失敗
		return "", "", err
	}

	// 驗證 Token 並取得 sub/email
	sub, email, err := s.GoogleAuth.VerifyIDToken(token, keys)
	if err != nil {
		// Token 驗證失敗
		return "", "", err
	}

	// upsert 使用者資料
	// 使用原生 SQL，避免 SQL Injection
	// ON CONFLICT (google_sub) DO UPDATE SET email=EXCLUDED.email
	query := `INSERT INTO users (google_sub, email) VALUES ($1, $2)
			  ON CONFLICT (google_sub) DO UPDATE SET email=EXCLUDED.email`
	_, err = s.DB.ExecContext(ctx, query, sub, email)
	if err != nil {
		// upsert 失敗
		return "", "", err
	}

	return sub, email, nil
}
