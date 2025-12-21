package media

import (
	"fmt"
	"net/http"
	"path/filepath"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	Service *Service
}

func NewHandler(s *Service) *Handler {
	return &Handler{Service: s}
}

// UploadHandler 處理檔案上傳
func (h *Handler) UploadHandler(c *gin.Context) {
	userID := c.MustGet("userID").(string)

	fileHeader, err := c.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing file"})
		return
	}

	force := c.Query("force") == "true"
	var takenAt *time.Time
	if ta := c.PostForm("taken_at"); ta != "" {
		// Try RFC3339 (standard)
		if t, err := time.Parse(time.RFC3339, ta); err == nil {
			takenAt = &t
		} else {
			// Try without timezone (fallback)
			if t, err := time.Parse("2006-01-02T15:04:05.999999999", ta); err == nil {
				takenAt = &t
			} else {
				fmt.Printf("Warning: failed to parse taken_at '%s': %v\n", ta, err)
			}
		}
	}

	result, err := h.Service.Upload(c.Request.Context(), userID, fileHeader, force, takenAt)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if result.Status == "conflict" {
		c.JSON(http.StatusConflict, gin.H{
			"error":       "duplicate",
			"existing_id": result.ExistingID,
		})
		return
	}

	c.JSON(http.StatusCreated, result.Media)
}

// ListHandler 取得媒體列表
func (h *Handler) ListHandler(c *gin.Context) {
	userID := c.MustGet("userID").(string)

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}
	offset := (page - 1) * limit

	list, err := h.Service.List(c.Request.Context(), userID, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, list)
}

// ListTrashHandler 取得垃圾桶列表
func (h *Handler) ListTrashHandler(c *gin.Context) {
	userID := c.MustGet("userID").(string)

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}
	offset := (page - 1) * limit

	list, err := h.Service.ListTrash(c.Request.Context(), userID, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, list)
}

// RestoreHandler 還原媒體
func (h *Handler) RestoreHandler(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	mediaID := c.Param("id")

	if mediaID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing media id"})
		return
	}

	err := h.Service.Restore(c.Request.Context(), userID, mediaID)
	if err != nil {
		if len(err.Error()) >= 15 && err.Error()[:15] == "media not found" {
			c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
			return
		}
		// Handle unique constraint violation (duplicate active file)
		// Postgres error code 23505 is unique_violation, but here we get a wrapped error string.
		// Simple check for now.
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusOK)
}

// DeleteHandler 刪除媒體 (支援 ?permanent=true)
func (h *Handler) DeleteHandler(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	mediaID := c.Param("id")
	permanent := c.Query("permanent") == "true"

	// Debug log
	fmt.Printf("Delete request: userID=%s, mediaID=%s, permanent=%v\n", userID, mediaID, permanent)

	if mediaID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing media id"})
		return
	}

	var err error
	if permanent {
		err = h.Service.DeletePermanent(c.Request.Context(), userID, mediaID)
	} else {
		err = h.Service.Delete(c.Request.Context(), userID, mediaID)
	}

	if err != nil {
		// Check for "media not found" in the error string
		if len(err.Error()) >= 15 && err.Error()[:15] == "media not found" {
			c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}

// GetFileHandler 提供檔案下載
func (h *Handler) GetFileHandler(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	mediaID := c.Param("id")

	if mediaID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing media id"})
		return
	}

	// 查詢檔案路徑
	media, err := h.Service.GetByID(c.Request.Context(), userID, mediaID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "media not found"})
		return
	}

	// 提供檔案
	filePath := filepath.Join(h.Service.UploadDir, media.StoragePath)
	c.File(filePath)
}

// CheckHashHandler 檢查 Hash 是否已存在
func (h *Handler) CheckHashHandler(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	hash := c.Param("hash")

	if hash == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing hash"})
		return
	}

	media, err := h.Service.CheckExistsByHash(c.Request.Context(), userID, hash)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if media == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		return
	}

	c.JSON(http.StatusOK, media)
}
