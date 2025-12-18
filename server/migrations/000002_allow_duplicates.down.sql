-- Re-add the constraint. Note: This might fail if duplicates were introduced.
-- We might need to delete duplicates first, but for a down migration, we just try to add it back.
DELETE FROM media a USING media b
WHERE a.id < b.id AND a.user_id = b.user_id AND a.file_hash = b.file_hash;

ALTER TABLE media ADD CONSTRAINT uq_user_hash UNIQUE (user_id, file_hash);
