package media

import (
	"bytes"
	"encoding/json"
	"fmt"
	"image"
	_ "image/jpeg" // Register decoders
	_ "image/png"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"github.com/rwcarlsen/goexif/exif"
	"github.com/rwcarlsen/goexif/mknote"
)

func init() {
	// 註冊 Nikon/Canon 等廠商筆記解析
	exif.RegisterParsers(mknote.All...)
}

// extractMetadata 根據檔案類型提取 Metadata
func extractMetadata(filePath string, mimeType string) (*Media, error) {
	m := &Media{}

	if strings.HasPrefix(mimeType, "image/") {
		if err := extractImageMetadata(filePath, m); err != nil {
			// 圖片解析失敗不應阻擋上傳，記錄錯誤即可
			fmt.Printf("Failed to extract image metadata: %v\n", err)
		}
	} else if strings.HasPrefix(mimeType, "video/") {
		if err := extractVideoMetadata(filePath, m); err != nil {
			fmt.Printf("Failed to extract video metadata: %v\n", err)
		}
	}

	return m, nil
}

// extractImageMetadata 解析圖片資訊 (寬高, EXIF)
func extractImageMetadata(filePath string, m *Media) error {
	f, err := os.Open(filePath)
	if err != nil {
		return err
	}
	defer f.Close()

	// 1. 解析寬高 (使用標準庫)
	// image.DecodeConfig 只讀取檔頭，速度快
	cfg, _, err := image.DecodeConfig(f)
	if err == nil {
		m.Width = cfg.Width
		m.Height = cfg.Height
	}

	// 2. 解析 EXIF
	// 重新定位到檔案開頭
	if _, err := f.Seek(0, 0); err != nil {
		return err
	}

	x, err := exif.Decode(f)
	if err != nil {
		// 許多圖片可能沒有 EXIF，這不是嚴重錯誤
		return nil
	}

	// 拍攝時間
	if tm, err := x.DateTime(); err == nil {
		m.TakenAt = &tm
	}

	// GPS
	if lat, long, err := x.LatLong(); err == nil {
		m.Latitude = &lat
		m.Longitude = &long
	}

	// 相機資訊
	if camMake, err := x.Get(exif.Make); err == nil {
		m.CameraMake, _ = camMake.StringVal()
	}
	if camModel, err := x.Get(exif.Model); err == nil {
		m.CameraModel, _ = camModel.StringVal()
	}

	// 曝光參數
	if fnum, err := x.Get(exif.FNumber); err == nil {
		num, den, _ := fnum.Rat2(0)
		if den != 0 {
			m.Aperture = float64(num) / float64(den)
		}
	}
	if iso, err := x.Get(exif.ISOSpeedRatings); err == nil {
		val, _ := iso.Int(0)
		m.ISO = val
	}
	if exp, err := x.Get(exif.ExposureTime); err == nil {
		num, den, _ := exp.Rat2(0)
		if den != 0 {
			// 儲存為 "1/100" 格式字串
			m.ExposureTime = fmt.Sprintf("%d/%d", num, den)
		}
	}

	return nil
}

// extractVideoMetadata 使用 ffprobe 解析影片資訊
func extractVideoMetadata(filePath string, m *Media) error {
	// 使用 ffprobe 獲取 JSON 格式的 metadata
	// -v quiet: 不輸出 log
	// -print_format json: 輸出 JSON
	// -show_format: 顯示容器資訊 (Duration, Tags)
	// -show_streams: 顯示串流資訊 (Width, Height)
	cmd := exec.Command("ffprobe",
		"-v", "quiet",
		"-print_format", "json",
		"-show_format",
		"-show_streams",
		filePath,
	)

	var out bytes.Buffer
	cmd.Stdout = &out
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("ffprobe execution failed: %w", err)
	}

	// 解析 JSON
	var data struct {
		Streams []struct {
			Width  int    `json:"width"`
			Height int    `json:"height"`
			Codec  string `json:"codec_type"`
		} `json:"streams"`
		Format struct {
			Duration string `json:"duration"`
			Tags     struct {
				CreationTime string `json:"creation_time"`
				Make         string `json:"com.apple.quicktime.make"`  // 常見 tag
				Model        string `json:"com.apple.quicktime.model"` // 常見 tag
				Location     string `json:"location"`                  // ISO 6709 格式
				LocationKey  string `json:"com.apple.quicktime.location.ISO6709"`
			} `json:"tags"`
		} `json:"format"`
	}

	if err := json.Unmarshal(out.Bytes(), &data); err != nil {
		return err
	}

	// 填入資訊
	// 1. 寬高 (找第一個 video stream)
	for _, s := range data.Streams {
		if s.Codec == "video" {
			m.Width = s.Width
			m.Height = s.Height
			break
		}
	}

	// 2. Duration (ffprobe 回傳的是字串秒數)
	if d, err := strconv.ParseFloat(data.Format.Duration, 64); err == nil {
		m.Duration = d
	}

	// 3. 拍攝時間
	if data.Format.Tags.CreationTime != "" {
		// 嘗試解析標準格式
		if t, err := time.Parse(time.RFC3339, data.Format.Tags.CreationTime); err == nil {
			m.TakenAt = &t
		}
	}

	// 4. 設備資訊 (部分容器支援)
	if data.Format.Tags.Make != "" {
		m.CameraMake = data.Format.Tags.Make
	}
	if data.Format.Tags.Model != "" {
		m.CameraModel = data.Format.Tags.Model
	}

	// 5. GPS (解析 ISO 6709 字串，如 "+27.5916+086.5640+8850/")
	loc := data.Format.Tags.Location
	if loc == "" {
		loc = data.Format.Tags.LocationKey
	}
	if loc != "" {
		// 簡易解析 ISO 6709 (僅支援基本格式)
		// 實際專案建議使用正規表達式或專門 library
		var lat, long float64
		// 這裡做一個簡單的嘗試，若格式複雜則略過
		// 範例: +25.0330+121.5654/
		if n, err := fmt.Sscanf(loc, "%f%f", &lat, &long); n == 2 && err == nil {
			m.Latitude = &lat
			m.Longitude = &long
		}
	}

	return nil
}
