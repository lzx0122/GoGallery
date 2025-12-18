-- 啟用 UUID 擴充功能
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. 使用者資料表
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    google_sub VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2. 媒體資料表 (Media)
CREATE TABLE IF NOT EXISTS media (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- 檔案資訊
    original_filename VARCHAR(255),
    storage_path VARCHAR(512) NOT NULL,
    file_hash VARCHAR(64) NOT NULL,
    size_bytes BIGINT,
    width INT,
    height INT,
    duration DOUBLE PRECISION, -- 影片長度 (秒)
    mime_type VARCHAR(50),

    -- EXIF / Metadata 資訊
    taken_at TIMESTAMPTZ,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    camera_make VARCHAR(100),
    camera_model VARCHAR(100),
    exposure_time VARCHAR(20),
    aperture DOUBLE PRECISION,
    iso INTEGER,

    -- UI 優化與 AI 預留
    blur_hash VARCHAR(100),
    dominant_color VARCHAR(9),

    -- 系統資訊
    uploaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    -- 去重限制
    CONSTRAINT uq_user_hash UNIQUE (user_id, file_hash)
);

-- 索引優化
CREATE INDEX IF NOT EXISTS idx_media_taken_at ON media (user_id, taken_at DESC);
CREATE INDEX IF NOT EXISTS idx_media_type ON media (user_id, mime_type);
