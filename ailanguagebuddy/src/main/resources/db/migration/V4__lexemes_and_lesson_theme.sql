-- Production: vocabulary (lexemes) in DB so content can be updated without code deploy.
-- Also link lessons to a theme so we load the right words per lesson.

-- Lexemes: one row per word/phrase per (language, theme).
CREATE TABLE IF NOT EXISTS lexemes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    language_code VARCHAR(10) NOT NULL,
    theme_key VARCHAR(50) NOT NULL,
    english_word VARCHAR(255) NOT NULL,
    english_phrase VARCHAR(500),
    target_word VARCHAR(255) NOT NULL,
    target_phrase VARCHAR(500),
    correct_order JSONB NOT NULL,
    emoji VARCHAR(20),
    sort_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_lexemes_language_theme
    ON lexemes (language_code, theme_key);

-- Link lessons to a theme (e.g. greetings, numbers, food). Nullable for backward compatibility.
ALTER TABLE lessons
    ADD COLUMN IF NOT EXISTS theme_key VARCHAR(50);
