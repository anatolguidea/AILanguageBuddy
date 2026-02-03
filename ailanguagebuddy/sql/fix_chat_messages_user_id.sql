-- Run this in Supabase Dashboard → SQL Editor.
-- Fixes: "bad SQL grammar" / "operator does not exist: uuid = character varying"
-- by making chat_messages.user_id type UUID (to match the Spring Boot entity).

-- If user_id is currently text/varchar, convert to UUID (fails if you have invalid non-UUID strings):
ALTER TABLE public.chat_messages
  ALTER COLUMN user_id TYPE uuid USING user_id::uuid;

-- If the column does not exist yet, use this instead (and comment out the line above):
-- ALTER TABLE public.chat_messages ADD COLUMN user_id uuid;
