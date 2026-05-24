-- Keep chat mode storage aligned with the API validation contract.
ALTER TABLE chat_messages
    ALTER COLUMN mode TYPE VARCHAR(100);
