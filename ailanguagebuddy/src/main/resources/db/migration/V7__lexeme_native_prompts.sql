-- Add a JSONB column on lexemes to store native-language prompts/questions
-- keyed by app/native locale (e.g. 'ro', 'en', etc.).

ALTER TABLE lexemes
    ADD COLUMN IF NOT EXISTS native_prompts JSONB;

CREATE INDEX IF NOT EXISTS idx_lexemes_native_prompts_gin
    ON lexemes
    USING GIN (native_prompts);

