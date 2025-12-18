package media

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"fmt"
	"io"
	"mime/multipart"
	"os"
	"path/filepath"
	"time"
)

type Service struct {
	DB        *sql.DB
	UploadDir string
}

func NewService(db *sql.DB, uploadDir string) *Service {
	return &Service{
		DB:        db,
		UploadDir: uploadDir,
	}
}

// UploadResult 包含上傳後的結果
type UploadResult struct {
	Media  *Media
	Status string // "created" or "skipped"
}

// Upload 處理檔案上傳
func (s *Service) Upload(ctx context.Context, userID string, fileHeader *multipart.FileHeader) (*UploadResult, error) {
	src, err := fileHeader.Open()
	if err != nil {
		return nil, fmt.Errorf("failed to open file: %w", err)
	}
	defer src.Close()

	// 1. 計算 Hash
	hash := sha256.New()
	if _, err := io.Copy(hash, src); err != nil {
		return nil, fmt.Errorf("failed to calculate hash: %w", err)
	}
	fileHash := hex.EncodeToString(hash.Sum(nil))

	// 重置讀取位置
	if _, err := src.Seek(0, 0); err != nil {
		return nil, fmt.Errorf("failed to seek file: %w", err)
	}

	// 2. 檢查去重 (Deduplication)
	exists, err := s.checkExists(ctx, userID, fileHash)
	if err != nil {
		return nil, err
	}
	if exists {
		return &UploadResult{Status: "skipped"}, nil
	}

	// 3. 儲存檔案
	// 路徑規則: uploads/uid/year/month/hash.ext
	now := time.Now()
	ext := filepath.Ext(fileHeader.Filename)
	relPath := filepath.Join(userID, now.Format("2006"), now.Format("01"), fileHash+ext)
	absPath := filepath.Join(s.UploadDir, relPath)

	if err := os.MkdirAll(filepath.Dir(absPath), 0755); err != nil {
		return nil, fmt.Errorf("failed to create directory: %w", err)
	}

	dst, err := os.Create(absPath)
	if err != nil {
		return nil, fmt.Errorf("failed to create file: %w", err)
	}
	defer dst.Close()

	if _, err := io.Copy(dst, src); err != nil {
		return nil, fmt.Errorf("failed to save file: %w", err)
	}

	// 4. 寫入資料庫
	// TODO: 解析 EXIF, 寬高, Duration 等 Metadata
	media := &Media{
		UserID:           userID,
		OriginalFilename: fileHeader.Filename,
		StoragePath:      relPath,
		FileHash:         fileHash,
		SizeBytes:        fileHeader.Size,
		MimeType:         fileHeader.Header.Get("Content-Type"),
		// 其他欄位暫時留空或設為預設值
	}

	if err := s.insertMedia(ctx, media); err != nil {
		// 如果 DB 寫入失敗，應該考慮刪除已上傳的檔案 (Cleanup)
		os.Remove(absPath)
		return nil, err
	}

	return &UploadResult{Media: media, Status: "created"}, nil
}

func (s *Service) checkExists(ctx context.Context, userID, fileHash string) (bool, error) {
	var count int
	query := `SELECT count(1) FROM media WHERE user_id = $1 AND file_hash = $2`
	err := s.DB.QueryRowContext(ctx, query, userID, fileHash).Scan(&count)
	if err != nil {
		return false, fmt.Errorf("failed to check existence: %w", err)
	}
	return count > 0, nil
}

func (s *Service) insertMedia(ctx context.Context, m *Media) error {
	query := `
		INSERT INTO media (
			user_id, original_filename, storage_path, file_hash, size_bytes, mime_type,
			width, height, duration, taken_at, latitude, longitude,
			camera_make, camera_model, exposure_time, aperture, iso,
			blur_hash, dominant_color
		) VALUES (
			$1, $2, $3, $4, $5, $6,
			$7, $8, $9, $10, $11, $12,
			$13, $14, $15, $16, $17,
			$18, $19
		) RETURNING id, uploaded_at
	`
	return s.DB.QueryRowContext(ctx, query,
		m.UserID, m.OriginalFilename, m.StoragePath, m.FileHash, m.SizeBytes, m.MimeType,
		m.Width, m.Height, m.Duration, m.TakenAt, m.Latitude, m.Longitude,
		m.CameraMake, m.CameraModel, m.ExposureTime, m.Aperture, m.ISO,
		m.BlurHash, m.DominantColor,
	).Scan(&m.ID, &m.UploadedAt)
}

// List 取得使用者的媒體列表
func (s *Service) List(ctx context.Context, userID string, limit, offset int) ([]*Media, error) {
	query := `
		SELECT id, user_id, original_filename, file_hash, size_bytes, mime_type,
		       width, height, duration, taken_at, latitude, longitude,
		       camera_make, camera_model, exposure_time, aperture, iso,
		       blur_hash, dominant_color, uploaded_at
		FROM media
		WHERE user_id = $1
		ORDER BY taken_at DESC NULLS LAST, uploaded_at DESC
		LIMIT $2 OFFSET $3
	`
	rows, err := s.DB.QueryContext(ctx, query, userID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to query media: %w", err)
	}
	defer rows.Close()

	list := []*Media{} // Initialize as empty slice to ensure JSON [] instead of null
	for rows.Next() {
		m := &Media{}
		err := rows.Scan(
			&m.ID, &m.UserID, &m.OriginalFilename, &m.FileHash, &m.SizeBytes, &m.MimeType,
			&m.Width, &m.Height, &m.Duration, &m.TakenAt, &m.Latitude, &m.Longitude,
			&m.CameraMake, &m.CameraModel, &m.ExposureTime, &m.Aperture, &m.ISO,
			&m.BlurHash, &m.DominantColor, &m.UploadedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan media: %w", err)
		}
		list = append(list, m)
	}
	return list, nil
}
