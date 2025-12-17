package main

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"regexp"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	_ "github.com/jackc/pgx/v5/stdlib"

	auth "gogallery/internal/auth"
	user "gogallery/internal/user"
)

// 解析 SYSTEM_CONTEXT.md 取得 Schema 區塊 SQL
func extractSchemaSQL(mdPath string) (string, error) {
	// 嘗試讀取檔案，如果失敗則嘗試上一層目錄
	b, err := os.ReadFile(mdPath)
	if err != nil {
		// Try parent directory
		b, err = os.ReadFile("../" + mdPath)
		if err != nil {
			return "", err
		}
	}
	content := string(b)
	re := regexp.MustCompile("```sql([\\s\\S]+?)```")
	matches := re.FindAllStringSubmatch(content, -1)
	if len(matches) == 0 {
		return "", fmt.Errorf("找不到 SQL 區塊")
	}
	// 只取第一個 SQL 區塊
	return strings.TrimSpace(matches[0][1]), nil
}

func autoMigrate(db *sql.DB, sqlText string) error {
	stmts := strings.Split(sqlText, ";")
	for _, stmt := range stmts {
		stmt = strings.TrimSpace(stmt)
		if stmt == "" {
			continue
		}
		_, err := db.Exec(stmt)
		if err != nil && !strings.Contains(err.Error(), "already exists") {
			return fmt.Errorf("migration failed: %w", err)
		}
	}
	return nil
}

func main() {
	dsn := os.Getenv("DB_DSN")
	if dsn == "" {
		log.Fatal("DB_DSN 環境變數未設定")
	}

	// 連線 PostgreSQL，重試機制
	var db *sql.DB
	var err error
	maxRetries := 10
	for i := 1; i <= maxRetries; i++ {
		db, err = sql.Open("pgx", dsn)
		if err == nil {
			err = db.Ping()
			if err == nil {
				break
			}
		}
		log.Printf("資料庫連線失敗（第 %d/%d 次）：%v，2 秒後重試...", i, maxRetries, err)
		db.Close()
		time.Sleep(2 * time.Second)
	}
	if err != nil {
		log.Fatalf("連線資料庫失敗: %v", err)
	}
	defer db.Close()

	// Migration
	sqlText, err := extractSchemaSQL("SYSTEM_CONTEXT.md")
	if err != nil {
		log.Fatalf("讀取 Schema 失敗: %v", err)
	}
	if err := autoMigrate(db, sqlText); err != nil {
		log.Fatalf("自動 migration 失敗: %v", err)
	}

	// 啟動 Gin
	r := gin.Default()
	r.GET("/ping", func(c *gin.Context) {
		err := db.PingContext(context.Background())
		if err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"db": "unavailable", "error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"db": "ok"})
	})

	// Google OAuth2 驗證與 upsert 使用者 (controller)
	var googleAuth user.GoogleAuthenticator
	if os.Getenv("APP_ENV") == "dev" {
		log.Println("⚠️ 啟動開發模式 (Dev Mode)：使用 Mock Google Auth")
		googleAuth = &MockGoogleAuth{}
	} else {
		googleAuth = &auth.GoogleAuthService{JWKsURL: "https://www.googleapis.com/oauth2/v3/certs"}
	}

	userService := &user.Service{DB: db, GoogleAuth: googleAuth}
	r.POST("/auth/google", func(c *gin.Context) {
		token := ""
		if h := c.GetHeader("Authorization"); strings.HasPrefix(h, "Bearer ") {
			token = strings.TrimPrefix(h, "Bearer ")
		}
		if token == "" {
			c.JSON(400, gin.H{"error": "missing Authorization Bearer token"})
			return
		}
		sub, email, name, picture, err := userService.UpsertByGoogle(c, token)
		if err != nil {
			c.JSON(401, gin.H{"error": err.Error()})
			return
		}
		c.JSON(200, gin.H{"sub": sub, "email": email, "name": name, "picture": picture})
	})
	r.Run(":8080")
}
