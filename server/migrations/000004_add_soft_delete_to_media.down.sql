-- Remove the partial index
DROP INDEX IF EXISTS idx_media_user_hash_active;

-- Delete soft-deleted records before dropping the column to avoid constraint violations
DELETE FROM media WHERE deleted_at IS NOT NULL;

-- Restore the original unique constraint
ALTER TABLE media ADD CONSTRAINT uq_user_hash UNIQUE (user_id, file_hash);

DROP INDEX IF EXISTS idx_media_deleted_at;
ALTER TABLE media DROP COLUMN deleted_at;
