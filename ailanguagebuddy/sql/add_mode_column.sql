-- Add mode column to chat_messages
ALTER TABLE chat_messages ADD COLUMN mode VARCHAR(50);

-- Backfill existing messages with 'general' mode
UPDATE chat_messages SET mode = 'general' WHERE mode IS NULL;
