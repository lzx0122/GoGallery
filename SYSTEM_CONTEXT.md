# SYSTEM_CONTEXT.md

# 專案情境說明書：私有相簿儲存庫 (Go/Podman 版)

> **給 AI 助理的情境說明**:
> 本文件定義了「私有相簿儲存庫 (Self-Hosted Photo Saver)」專案的架構限制與技術規格。
> 在生成任何程式碼之前，請務必詳閱此文件。所有的輸出必須嚴格遵守以下定義的限制。

---

## 1. 專案概述 (Project Overview)

這是一個私有、自架的相片備份解決方案，旨在釋放手機儲存空間。

- **客戶端 (Client)**: Flutter App (目標平台：iOS)。
- **伺服器 (Server)**: Go (Golang) API。
- **部署 (Deployment)**: Podman (Rootless Containers / 非管理員權限容器)。

## 2. 技術堆疊限制 (Tech Stack Constraints)

- **行動端框架**: Flutter (優先考慮 iOS `Cupertino` 風格元件與 `Info.plist` 設定)。
- **後端語言**: Go (Golang)。推薦使用標準庫或輕量框架如 `Gin` 或 `Echo`。
- **資料庫**: PostgreSQL (Driver: `pgx`)。
- **身份驗證**: 僅限 Google OAuth2 (OpenID Connect)。
- **容器執行環境**: **Podman**。(必須支援 SELinux 的 Volume 掛載標籤 `:z`)。

## 3. 核心原則 (不可協商)

1.  **Podman 原生 (Podman Native)**: 基礎建設代碼 (`docker-compose.yml`) 必須與 `podman-compose` 相容。
2.  **零隱私個資 (Privacy Zero / No PII)**:
    - **絕對禁止** 建立使用者姓名、地址、電話、年齡或性別等欄位。
    - **僅允許** 儲存 `google_sub` (作為唯一 ID) 與 `email` (僅供識別顯示用)。
3.  **無狀態 (Stateless)**: 伺服器端不儲存 Session。每次請求都必須驗證 JWT/ID Token。
4.  **去重 (Deduplication)**: 檔案必須透過 SHA-256 雜湊值 (Hash) 來識別，以防止重複上傳浪費空間。

## 4. 資料庫結構 (Database Schema)

生成任何資料庫遷移 (Migration) 時，請使用以下 SQL 結構：

```sql
-- 啟用 UUID 擴充功能
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. 使用者資料表 (極簡化，無個資)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    google_sub VARCHAR(255) UNIQUE NOT NULL, -- 來自 Google 的唯一使用者識別碼
    email VARCHAR(255) NOT NULL,             -- 僅用於識別顯示，不做登入驗證
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2. 媒體資料表 (Media) - 支援照片與影片
CREATE TABLE media (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- 檔案資訊
    original_filename VARCHAR(255),
    storage_path VARCHAR(512) NOT NULL, -- 檔案路徑
    file_hash VARCHAR(64) NOT NULL,     -- SHA-256 雜湊值
    size_bytes BIGINT,
    width INT,                          -- 寬度 (px)
    height INT,                         -- 高度 (px)
    duration DOUBLE PRECISION,          -- [影片專用] 影片長度 (秒)
    mime_type VARCHAR(50),              -- e.g. image/jpeg, video/mp4

    -- EXIF / Metadata 資訊
    taken_at TIMESTAMPTZ,               -- 拍攝時間
    latitude DOUBLE PRECISION,          -- 緯度
    longitude DOUBLE PRECISION,         -- 經度
    camera_make VARCHAR(100),           -- 設備製造商
    camera_model VARCHAR(100),          -- 設備型號
    exposure_time VARCHAR(20),          -- 曝光時間
    aperture DOUBLE PRECISION,          -- 光圈值
    iso INTEGER,                        -- ISO

    -- UI 優化與 AI 預留
    blur_hash VARCHAR(100),             -- BlurHash (影片可使用縮圖生成)
    dominant_color VARCHAR(9),          -- 主色調

    -- 系統資訊
    uploaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    -- 去重限制
    CONSTRAINT uq_media_user_hash UNIQUE (user_id, file_hash)
);

-- 索引優化
CREATE INDEX IF NOT EXISTS idx_media_taken_at ON media (user_id, taken_at DESC);
CREATE INDEX IF NOT EXISTS idx_media_type ON media (user_id, mime_type);

-- Migration: 確保欄位存在 (針對已存在的資料表)
ALTER TABLE media ADD COLUMN IF NOT EXISTS width INT;
ALTER TABLE media ADD COLUMN IF NOT EXISTS height INT;
ALTER TABLE media ADD COLUMN IF NOT EXISTS duration DOUBLE PRECISION;
ALTER TABLE media ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE media ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;
ALTER TABLE media ADD COLUMN IF NOT EXISTS camera_make VARCHAR(100);
ALTER TABLE media ADD COLUMN IF NOT EXISTS camera_model VARCHAR(100);
ALTER TABLE media ADD COLUMN IF NOT EXISTS exposure_time VARCHAR(20);

-- Soft Delete Migration
ALTER TABLE media ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
CREATE INDEX IF NOT EXISTS idx_media_deleted_at ON media (deleted_at);

-- Ensure partial unique index to prevent duplicates for active records
CREATE UNIQUE INDEX IF NOT EXISTS idx_media_user_hash_active ON media (user_id, file_hash) WHERE deleted_at IS NULL;

ALTER TABLE media ADD COLUMN IF NOT EXISTS aperture DOUBLE PRECISION;
ALTER TABLE media ADD COLUMN IF NOT EXISTS iso INTEGER;
ALTER TABLE media ADD COLUMN IF NOT EXISTS blur_hash VARCHAR(100);
ALTER TABLE media ADD COLUMN IF NOT EXISTS dominant_color VARCHAR(9);
```

## 5. API 邏輯規範 (API Logic Specifications)

### A. 身份驗證 (Google Sign-In)

- **客戶端**: 將 ID Token 放入 Header 發送：`Authorization: Bearer <TOKEN>`。
- **伺服器端**:
  1.  使用 Google 的公鑰 (Public Keys) 驗證 Token 簽章。
  2.  解析出 `sub` (Subject ID)。
  3.  **自動註冊/登入邏輯 (Upsert Logic)**: 如果 DB 中已存在該 `sub` -> 視為登入。如果不存在 -> 建立新使用者 (插入 `sub` + `email`)。

### B. 上傳流程 (含去重機制)

1.  **預檢查 (Pre-check)**: 客戶端先發送檔案的 Hash (SHA-256)。
    - _若該使用者的 Hash 已存在_: 回傳 `200 OK` (Body: `{"status": "skipped", "reason": "exists"}`)。
    - _若為新檔案_: 回傳 `201 Proceed`，允許上傳。
2.  **上傳 (Upload)**: 客戶端發送二進位檔案 (Binary)。
    - 伺服器驗證檔案內容的 Hash 是否匹配。
    - 伺服器將檔案存入 Volume (`/app/uploads/uid/year/month/`)。
    - 伺服器生成縮圖 (Thumbnail) (選用，但在手機瀏覽時強烈建議)。
    - 伺服器將記錄寫入 `photos` 資料表。

## 6. 基礎建設 (Podman Compose)

請使用以下範本作為 `docker-compose.yml`，特別注意 `:z` 標籤：

```yaml
version: '3.8'

services:
  app-server:
    build: .
    container_name: photo_backend
    restart: unless-stopped
    ports:
      - '8080:8080'
    environment:
      - DB_DSN=host=postgres user=photouser password=secret dbname=photodb sslmode=disable
      - GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}
      - UPLOAD_DIR=/app/uploads
    volumes:
      - ./uploads:/app/uploads:z # ':z' 對於 Podman/SELinux 是至關重要的
    depends_on:
      - postgres

  postgres:
    image: postgres:15-alpine
    container_name: photo_db
    restart: unless-stopped
    environment:
      POSTGRES_USER: photouser
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: photodb
    volumes:
      - pgdata:/var/lib/postgresql/data:z # ':z' 對於 Podman/SELinux 是至關重要的

volumes:
  pgdata:
```

---

## 7. 給 AI 的開發指令 (AI Task Instructions)

當你協助開發此專案時，請務必：

1.  **檔案路徑**: 始終假設環境為 **Linux/Podman** (使用 forward slash `/`)。
2.  **Go 語言**: 盡可能使用 Go 標準庫，但允許使用 `Gin` (Web Framework) 和 `pgx` (DB Driver)。
3.  **Flutter**: 假設開發目標為 **iOS**，需考慮 iOS 對背景任務的嚴格限制。
4.  **安全性**: **絕對不要** 生成要求設定或儲存使用者密碼的程式碼。
