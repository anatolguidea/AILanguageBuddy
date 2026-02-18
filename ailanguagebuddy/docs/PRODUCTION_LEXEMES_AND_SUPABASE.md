# Production Lexemes & Supabase

Vocabulary (lexemes) and lesson–theme linking are now stored in the database so you can change content without redeploying code.

## What runs automatically

When you start the backend:

1. **Flyway** applies migrations in order.  
   - **V4** creates the `lexemes` table and adds `theme_key` to `lessons`.  
   - No manual step in Supabase is required for the schema.

2. **Seeders** (if needed):
   - **SpanishLessonSeeder**: If Spanish lessons count ≠ 30, it replaces all Spanish lessons with the canonical 30 and sets each lesson’s `theme_key` (e.g. `greetings`, `numbers`, `food`).
   - **LexemeSeeder**: If there are no Spanish lexemes, it inserts the initial vocabulary per theme.

So for a **new** or **empty** DB: start the app once; Flyway creates tables and the seeders fill Spanish lessons + lexemes.

## What you need to do in Supabase

**Nothing** for normal operation. The app uses your existing `DATASOURCE_URL` (Supabase Postgres); Flyway runs against it and creates/updates schema.

Optional:

- **Inspect data**: In Supabase → Table Editor you’ll see:
  - **`lessons`** – column `theme_key` (e.g. `greetings`, `food`).
  - **`lexemes`** – rows per (language_code, theme_key) with `english_word`, `target_word`, `correct_order`, `emoji`, etc.
- **Edit content**: Change or add rows in `lexemes` (fix typos, new words, new themes). No code deploy needed.
- **Add another language**: Insert into `lexemes` with a different `language_code` and appropriate `theme_key` values; add lessons (with `theme_key` set) for that language. Backend already loads by `(language_code, theme_key)`.

## Schema (for reference)

- **lexemes**: `id`, `language_code`, `theme_key`, `english_word`, `english_phrase`, `target_word`, `target_phrase`, `correct_order` (JSONB array), `emoji`, `sort_order`, `created_at`, `updated_at`.
- **lessons**: existing columns + `theme_key` (VARCHAR 50, nullable).

If you ever run SQL by hand (e.g. in Supabase SQL Editor), use the same column names and types as in the Flyway migration `V4__lexemes_and_lesson_theme.sql`.

## Flow

- When a user opens a lesson, the API returns lesson metadata and (when content is generated) challenges.
- Challenge generation uses `lesson.themeKey` and `lesson.languageCode`: it loads lexemes from DB with `findByLanguageCodeAndThemeKeyOrderBySortOrderAsc`.
- If no lexemes are found for that (language, theme), the backend falls back to in-memory Spanish/by-order logic so existing behavior is preserved.

## Adding or editing vocabulary

1. In Supabase, open **Table Editor** → **lexemes**.
2. Add a row (or edit one): set `language_code`, `theme_key`, `english_word`, `target_word`, `correct_order` (e.g. `["Hola", "¿cómo", "estás?"]`), `emoji`, `sort_order`.
3. Save. The next time that lesson is loaded, the new/updated lexeme is used.

No backend redeploy required.
