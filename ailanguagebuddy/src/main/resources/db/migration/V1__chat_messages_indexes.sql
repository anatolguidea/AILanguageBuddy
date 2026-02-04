-- Idempotent migration for existing Supabase Postgres databases.

-- Create table if it doesn't exist (helps fresh environments).
CREATE TABLE IF NOT EXISTS chat_messages (
    id BIGSERIAL PRIMARY KEY,
    content TEXT,
    role TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    user_id UUID
);

-- Ensure columns exist (safe if already present).
ALTER TABLE chat_messages
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW();

ALTER TABLE chat_messages
    ADD COLUMN IF NOT EXISTS user_id UUID;

-- Indexes for fast per-user history queries.
CREATE INDEX IF NOT EXISTS idx_chat_messages_user_created_at
    ON chat_messages (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at
    ON chat_messages (created_at DESC);

