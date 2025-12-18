package media

import (
	"time"
)

// Media 代表 media 資料表的結構
type Media struct {
	ID               string     `json:"id"`
	UserID           string     `json:"user_id"`
	OriginalFilename string     `json:"original_filename"`
	StoragePath      string     `json:"-"` // 不回傳給前端
	FileHash         string     `json:"file_hash"`
	SizeBytes        int64      `json:"size_bytes"`
	Width            int        `json:"width"`
	Height           int        `json:"height"`
	Duration         float64    `json:"duration"`
	MimeType         string     `json:"mime_type"`
	TakenAt          *time.Time `json:"taken_at"`
	Latitude         *float64   `json:"latitude"`
	Longitude        *float64   `json:"longitude"`
	CameraMake       string     `json:"camera_make"`
	CameraModel      string     `json:"camera_model"`
	ExposureTime     string     `json:"exposure_time"`
	Aperture         float64    `json:"aperture"`
	ISO              int        `json:"iso"`
	BlurHash         string     `json:"blur_hash"`
	DominantColor    string     `json:"dominant_color"`
	UploadedAt       time.Time  `json:"uploaded_at"`
}
