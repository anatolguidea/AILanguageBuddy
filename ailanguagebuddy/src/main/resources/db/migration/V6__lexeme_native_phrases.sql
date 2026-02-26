-- Add a JSONB column on lexemes to store native-language phrases/sentences
-- keyed by app/native locale (e.g. 'ro', 'en', etc.).

ALTER TABLE lexemes
    ADD COLUMN IF NOT EXISTS native_phrases JSONB;

-- Optional GIN index for future querying/filtering by native phrase content.
CREATE INDEX IF NOT EXISTS idx_lexemes_native_phrases_gin
    ON lexemes
    USING GIN (native_phrases);

