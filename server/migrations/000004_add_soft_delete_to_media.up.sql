ALTER TABLE media ADD COLUMN deleted_at TIMESTAMPTZ;
CREATE INDEX idx_media_deleted_at ON media (deleted_at);

-- Drop the old unique constraint
ALTER TABLE media DROP CONSTRAINT IF EXISTS uq_user_hash;

-- Create a partial unique index that only enforces uniqueness for non-deleted records
CREATE UNIQUE INDEX idx_media_user_hash_active ON media (user_id, file_hash) WHERE deleted_at IS NULL;
