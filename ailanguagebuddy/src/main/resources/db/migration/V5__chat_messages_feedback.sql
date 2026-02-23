-- Store per-turn correction and tips for assistant messages (language learning feedback).
ALTER TABLE chat_messages
    ADD COLUMN IF NOT EXISTS correction TEXT;

ALTER TABLE chat_messages
    ADD COLUMN IF NOT EXISTS tips TEXT;
