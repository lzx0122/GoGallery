package media

import (
	"net/http"
	"strconv"

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
	result, err := h.Service.Upload(c.Request.Context(), userID, fileHeader, force)
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
