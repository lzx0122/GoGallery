-- Re-add the constraint if we roll back.
-- Ensure no duplicates exist before adding constraint
DELETE FROM media a USING media b
WHERE a.id < b.id AND a.user_id = b.user_id AND a.file_hash = b.file_hash;

ALTER TABLE media ADD CONSTRAINT uq_user_hash UNIQUE (user_id, file_hash);
