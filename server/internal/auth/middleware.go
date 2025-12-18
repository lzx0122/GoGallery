package auth

import (
	"database/sql"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

// TokenVerifier 定義驗證 Token 的介面
type TokenVerifier interface {
	FetchJWKs() ([]map[string]interface{}, error)
	VerifyIDToken(token string, keys []map[string]interface{}) (string, string, string, string, error)
}

// AuthMiddleware 驗證 Google ID Token 並將 User ID (UUID) 注入 Context
func AuthMiddleware(db *sql.DB, verifier TokenVerifier) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "missing Authorization header"})
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid Authorization header format"})
			return
		}
		token := parts[1]

		// 1. 驗證 Token
		keys, err := verifier.FetchJWKs()
		if err != nil {
			c.AbortWithStatusJSON(http.StatusServiceUnavailable, gin.H{"error": "failed to fetch JWKs"})
			return
		}

		sub, _, _, _, err := verifier.VerifyIDToken(token, keys)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid token: " + err.Error()})
			return
		}

		// 2. 查詢 User UUID
		var userID string
		err = db.QueryRowContext(c, "SELECT id FROM users WHERE google_sub = $1", sub).Scan(&userID)
		if err == sql.ErrNoRows {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "user not found (please login first)"})
			return
		}
		if err != nil {
			c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{"error": "database error"})
			return
		}

		// 3. 設定 Context
		c.Set("userID", userID)
		c.Next()
	}
}
