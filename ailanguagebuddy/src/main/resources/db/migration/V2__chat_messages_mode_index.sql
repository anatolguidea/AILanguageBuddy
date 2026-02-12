-- Ensure mode column exists and add composite index for low-latency scoped history lookup.
ALTER TABLE chat_messages
    ADD COLUMN IF NOT EXISTS mode VARCHAR(50);

UPDATE chat_messages
SET mode = 'general'
WHERE mode IS NULL;

CREATE INDEX IF NOT EXISTS idx_chat_messages_user_mode_created_at
    ON chat_messages (user_id, mode, created_at DESC);
