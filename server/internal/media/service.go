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
	Media      *Media
	Status     string // "created" or "skipped" or "conflict"
	ExistingID string
}

// Upload 處理檔案上傳
func (s *Service) Upload(ctx context.Context, userID string, fileHeader *multipart.FileHeader, force bool) (*UploadResult, error) {
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
	existingID, err := s.checkExists(ctx, userID, fileHash)
	if err != nil {
		return nil, err
	}

	if !force {
		if existingID != "" {
			return &UploadResult{Status: "conflict", ExistingID: existingID}, nil
		}
	}
	// If force is true, we proceed to create a duplicate (Keep Both)

	// 3. 儲存檔案
	// 路徑規則: uploads/uid/year/month/hash_timestamp.ext
	// 加入 timestamp 以確保檔名唯一，避免覆蓋舊檔案 (因為我們允許重複)
	now := time.Now()
	ext := filepath.Ext(fileHeader.Filename)
	uniqueSuffix := fmt.Sprintf("_%d", now.UnixNano())
	relPath := filepath.Join(userID, now.Format("2006"), now.Format("01"), fileHash+uniqueSuffix+ext)
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

	// 4. 解析 Metadata
	// 即使解析失敗，我們仍然允許上傳，只是 Metadata 會是空的
	meta, _ := extractMetadata(absPath, fileHeader.Header.Get("Content-Type"))
	if meta == nil {
		meta = &Media{}
	}

	// 5. 寫入資料庫
	media := &Media{
		UserID:           userID,
		OriginalFilename: fileHeader.Filename,
		StoragePath:      relPath,
		FileHash:         fileHash,
		SizeBytes:        fileHeader.Size,
		MimeType:         fileHeader.Header.Get("Content-Type"),

		// Metadata
		Width:        meta.Width,
		Height:       meta.Height,
		Duration:     meta.Duration,
		TakenAt:      meta.TakenAt,
		Latitude:     meta.Latitude,
		Longitude:    meta.Longitude,
		CameraMake:   meta.CameraMake,
		CameraModel:  meta.CameraModel,
		ExposureTime: meta.ExposureTime,
		Aperture:     meta.Aperture,
		ISO:          meta.ISO,
	}

	if err := s.insertMedia(ctx, media); err != nil {
		// 如果 DB 寫入失敗，應該考慮刪除已上傳的檔案 (Cleanup)
		os.Remove(absPath)
		return nil, err
	}

	return &UploadResult{Media: media, Status: "created"}, nil
}

func (s *Service) checkExists(ctx context.Context, userID, fileHash string) (string, error) {
	var id string
	query := `SELECT id FROM media WHERE user_id = $1 AND file_hash = $2 AND deleted_at IS NULL LIMIT 1`
	err := s.DB.QueryRowContext(ctx, query, userID, fileHash).Scan(&id)
	if err == sql.ErrNoRows {
		return "", nil
	}
	if err != nil {
		return "", fmt.Errorf("failed to check existence: %w", err)
	}
	return id, nil
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
		WHERE user_id = $1 AND deleted_at IS NULL
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

// GetByID 取得單一媒體（包含 storage_path）
func (s *Service) GetByID(ctx context.Context, userID string, mediaID string) (*Media, error) {
	query := `
		SELECT id, user_id, original_filename, storage_path, file_hash, size_bytes, mime_type,
		       width, height, duration, taken_at, latitude, longitude,
		       camera_make, camera_model, exposure_time, aperture, iso,
		       blur_hash, dominant_color, uploaded_at, deleted_at
		FROM media
		WHERE id = $1 AND user_id = $2
	`
	m := &Media{}
	err := s.DB.QueryRowContext(ctx, query, mediaID, userID).Scan(
		&m.ID, &m.UserID, &m.OriginalFilename, &m.StoragePath, &m.FileHash, &m.SizeBytes, &m.MimeType,
		&m.Width, &m.Height, &m.Duration, &m.TakenAt, &m.Latitude, &m.Longitude,
		&m.CameraMake, &m.CameraModel, &m.ExposureTime, &m.Aperture, &m.ISO,
		&m.BlurHash, &m.DominantColor, &m.UploadedAt, &m.DeletedAt,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("media not found")
		}
		return nil, fmt.Errorf("failed to query media: %w", err)
	}
	return m, nil
}

// ListTrash 取得垃圾桶中的媒體列表
func (s *Service) ListTrash(ctx context.Context, userID string, limit, offset int) ([]*Media, error) {
	query := `
		SELECT id, user_id, original_filename, file_hash, size_bytes, mime_type,
		       width, height, duration, taken_at, latitude, longitude,
		       camera_make, camera_model, exposure_time, aperture, iso,
		       blur_hash, dominant_color, uploaded_at, deleted_at
		FROM media
		WHERE user_id = $1 AND deleted_at IS NOT NULL
		ORDER BY deleted_at DESC
		LIMIT $2 OFFSET $3
	`
	rows, err := s.DB.QueryContext(ctx, query, userID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to query trash media: %w", err)
	}
	defer rows.Close()

	list := []*Media{}
	for rows.Next() {
		m := &Media{}
		err := rows.Scan(
			&m.ID, &m.UserID, &m.OriginalFilename, &m.FileHash, &m.SizeBytes, &m.MimeType,
			&m.Width, &m.Height, &m.Duration, &m.TakenAt, &m.Latitude, &m.Longitude,
			&m.CameraMake, &m.CameraModel, &m.ExposureTime, &m.Aperture, &m.ISO,
			&m.BlurHash, &m.DominantColor, &m.UploadedAt, &m.DeletedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan media: %w", err)
		}
		list = append(list, m)
	}
	return list, nil
}

// Restore 還原媒體
func (s *Service) Restore(ctx context.Context, userID string, mediaID string) error {
	// 1. 確認媒體存在於垃圾桶
	var id string
	query := `SELECT id FROM media WHERE id = $1 AND user_id = $2 AND deleted_at IS NOT NULL`
	err := s.DB.QueryRowContext(ctx, query, mediaID, userID).Scan(&id)
	if err != nil {
		if err == sql.ErrNoRows {
			return fmt.Errorf("media not found in trash (id: %s)", mediaID)
		}
		return fmt.Errorf("failed to query media: %w", err)
	}

	// 2. 執行還原 (設定 deleted_at = NULL)
	// 注意：如果還原時發現 active 狀態下已有相同 hash 的檔案，可能會違反 partial unique index
	// 因此需要先檢查是否有衝突
	// 但因為我們在 soft delete 時保留了 file_hash，且 unique index 是 WHERE deleted_at IS NULL
	// 所以如果現在有一個 active 的相同 hash 檔案，還原會失敗 (Postgres 會報錯)
	// 我們可以讓它報錯，或者先檢查

	updateQuery := `UPDATE media SET deleted_at = NULL WHERE id = $1 AND user_id = $2`
	_, err = s.DB.ExecContext(ctx, updateQuery, mediaID, userID)
	if err != nil {
		return fmt.Errorf("failed to restore media: %w", err)
	}

	return nil
}

// DeletePermanent 永久刪除媒體
func (s *Service) DeletePermanent(ctx context.Context, userID string, mediaID string) error {
	// 1. 查詢檔案路徑 (不論是否軟刪除都可以查)
	var storagePath string
	query := `SELECT storage_path FROM media WHERE id = $1 AND user_id = $2`
	err := s.DB.QueryRowContext(ctx, query, mediaID, userID).Scan(&storagePath)
	if err != nil {
		if err == sql.ErrNoRows {
			return fmt.Errorf("media not found (id: %s)", mediaID)
		}
		return fmt.Errorf("failed to query media: %w", err)
	}

	// 2. 刪除資料庫記錄
	deleteQuery := `DELETE FROM media WHERE id = $1 AND user_id = $2`
	_, err = s.DB.ExecContext(ctx, deleteQuery, mediaID, userID)
	if err != nil {
		return fmt.Errorf("failed to delete media record: %w", err)
	}

	// 3. 刪除實體檔案
	absPath := filepath.Join(s.UploadDir, storagePath)
	if err := os.Remove(absPath); err != nil {
		fmt.Printf("failed to delete file %s: %v\n", absPath, err)
	}

	return nil
}

// Delete 刪除媒體 (軟刪除)
func (s *Service) Delete(ctx context.Context, userID string, mediaID string) error {
	// 1. 確認媒體存在且未被刪除
	var id string
	query := `SELECT id FROM media WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL`
	err := s.DB.QueryRowContext(ctx, query, mediaID, userID).Scan(&id)
	if err != nil {
		if err == sql.ErrNoRows {
			return fmt.Errorf("media not found or permission denied (id: %s, user: %s)", mediaID, userID)
		}
		return fmt.Errorf("failed to query media: %w", err)
	}

	// 2. 執行軟刪除 (設定 deleted_at)
	updateQuery := `UPDATE media SET deleted_at = NOW() WHERE id = $1 AND user_id = $2`
	_, err = s.DB.ExecContext(ctx, updateQuery, mediaID, userID)
	if err != nil {
		return fmt.Errorf("failed to soft delete media record: %w", err)
	}

	// 注意：軟刪除不刪除實體檔案
	return nil
}
