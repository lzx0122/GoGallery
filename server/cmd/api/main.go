package main

import (
	"context"
	"database/sql"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"regexp"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/stdlib"
)

// 解析 SYSTEM_CONTEXT.md 取得 Schema 區塊 SQL
func extractSchemaSQL(mdPath string) (string, error) {
	b, err := ioutil.ReadFile(mdPath)
	if err != nil {
		return "", err
	}
	content := string(b)
	re := regexp.MustCompile("``sql([\s\S]+?)```")
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
	// 連線 PostgreSQL
	db, err := sql.Open("pgx", dsn)
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
	r.Run(":8080")
}
