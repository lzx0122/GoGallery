CREATE UNIQUE INDEX idx_media_user_hash_active ON media (user_id, file_hash) WHERE deleted_at IS NULL;
