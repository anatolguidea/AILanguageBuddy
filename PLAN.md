Implementation Plan - TezaApp Expansion
This plan outlines the steps to upgrade the "AI Language Buddy" into a feature-rich language learning application. The key focuses are: dynamic language selection, roleplay scenarios, Google Authentication, and replacing mock lessons with real, database-backed content.

User Review Required
IMPORTANT

Google Auth Setup: You must enable the "Google" provider in your Supabase project dashboard and configure the OAuth consent screen in Google Cloud Console. I can provide the code, but you will need to add the Client IDs and Secrets to Supabase.

IMPORTANT

Database Schema: We will need to run SQL scripts in your Supabase SQL Editor to create the tables for Lessons and Scenarios.

Proposed Changes
1. Multi-language Support
Goal: Allow users to switch between learning languages (e.g., Spanish, French, German) and have the app adapt accordingly.

Frontend (Flutter)
[NEW] lib/features/settings/presentation/providers/language_provider.dart: Global state for currently selected target language.
[NEW] lib/features/settings/domain/entities/language.dart: Model for supported languages.
[MODIFY] 
lib/features/chat/data/chat_repository.dart
: Pass the selected language in the API request body.
[NEW] lib/features/home/presentation/widgets/language_selector.dart: UI widget to switch languages.
Backend (Spring Boot)
[MODIFY] com.example.ailanguagebuddy.api.dto.ChatAskRequest: Ensure targetLanguage is properly handled.
[MODIFY] com.example.ailanguagebuddy.service.PromptBuilder: Refine system prompt to ensure strict adherence to the selected language.
2. Roleplay Scenarios
Goal: Engage users with specific personas (e.g., "Angry Boss", "Supportive Girlfriend", "Barista").

Backend (Spring Boot)
[NEW] com.example.ailanguagebuddy.domain.Scenario: Enum or Class defining personas (system prompt overrides).
[MODIFY] com.example.ailanguagebuddy.service.PromptBuilder: Add logic to inject persona instructions based on scenarioId.
[MODIFY] com.example.ailanguagebuddy.controller.ChatController: Accept scenarioId in /ask endpoint.
Frontend (Flutter)
[NEW] lib/features/scenarios/domain/entities/scenario.dart: Model for scenarios.
[NEW] lib/features/scenarios/presentation/pages/scenarios_page.dart: Grid view of available scenarios.
[MODIFY] lib/features/chat/presentation/pages/chat_page.dart: Display active scenario context in the chat UI.
3. Real Lessons (Database Integrated)
Goal: Replace hardcoded mock lessons with dynamic content stored in Supabase.

Database (Supabase)
[NEW] Table lessons (id, language_code, title, description, content_json, order_index).
[NEW] Table user_lesson_progress (user_id, lesson_id, status, completed_at).
Backend (Spring Boot)
[NEW] com.example.ailanguagebuddy.controller.LessonController: Endpoints to fetch lessons by language.
[NEW] com.example.ailanguagebuddy.service.LessonService: Logic to retrieve lessons and track progress.
[NEW] com.example.ailanguagebuddy.repository.LessonRepository: Data access.
Frontend (Flutter)
[MODIFY] 
lib/features/lessons/presentation/pages/lessons_page.dart
: Remove mockLessons, fetch from backend via LessonProvider.
[NEW] lib/features/lessons/data/datasources/lessons_remote_data_source.dart: API calls to /api/v1/lessons.
[NEW] lib/features/lessons/presentation/pages/lesson_detail_page.dart: Screen to view lesson content and mark as complete.
4. Authentication (Google)
Goal: Add one-tap sign-in.

Frontend (Flutter)
[MODIFY] 
lib/features/auth/data/auth_repository.dart
: Add signInWithGoogle() using supabase.auth.signInWithOAuth().
[MODIFY] lib/features/auth/presentation/pages/login_page.dart: Add "Sign in with Google" button.
5. Suggested Enhancements (Bonus)
Gamification: simple XP system tracked in users table. Award XP for completing lessons or chat messages.
Voice Mode: Ensure existing TTS/STT works smoothly with the new Scenarios.
Verification Plan
Automated Tests
Backend Tests: Run ./mvnw test to verify 
PromptBuilder
 correctly switches prompts for scenarios.
Frontend Tests: flutter test to verify providers and repositories.
Manual Verification
Google Auth: Click "Sign in with Google", verify redirection and successful login.
Language Switch: Change language to "Spanish", start chat, verify AI responds in Spanish.
Scenario Test: Select "Barista" scenario. Send "I want a coffee". Verify AI responds like a barista (e.g., "What size?").
Lessons: Open Lessons tab. Verify lessons load from DB. Complete a lesson. Verify status updates to "Completed".