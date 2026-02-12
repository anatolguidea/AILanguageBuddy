# AI Language Buddy - Project Documentation 📘

**AI Language Buddy** is a comprehensive language learning platform that combines an interactive AI tutor with structured lessons. This document provides a detailed overview of the system architecture, setup instructions, and development guidelines.

---

## 🏗️ System Architecture

The project follows a **Client-Server** architecture integrated with **Supabase** for authentication and data storage.

### 1. Frontend (Mobile App)
- **Framework**: [Flutter](https://flutter.dev) (Dart)
- **State Management**: `flutter_riverpod` for reactive state.
- **Routing**: `go_router` for deep linking and navigation.
- **UI Components**: Material 3 design system with custom widgets.
- **Key Features**:
    - **Voice Integration**: `flutter_tts` (Text-to-Speech) and `speech_to_text`.
    - **Auth**: Native Google Sign-In (`google_sign_in`) and Email/Password via Supabase.
    - **App Structure**:
        - `lib/core`: Shared widgets, constants, and utilities.
        - `lib/features`: Feature-based modular structure (Auth, Chat, Scenarios, Lessons).

### 2. Backend (logic Layer)
- **Framework**: [Spring Boot 3](https://spring.io/projects/spring-boot) (Java 21)
- **AI Integration**: [Spring AI](https://spring.io/projects/spring-ai) utilizing **Groq** (LLeMA/Mixtral models) for fast inference.
- **Security**: OAuth2 Resource Server validating Supabase JWT tokens.
- **Persistence**: JPA / Hibernate connecting to PostgreSQL.

### 3. Infrastructure (Supabase)
- **Authentication**: User management (Email, Google OAuth).
- **Database**: PostgreSQL for persistent storage (`chat_messages`, `lessons`, `user_lesson_progress`).
- **Storage**: (Optional) For user avatars or lesson assets.

---

## 📂 Project Structure

```
TezaApp/
├── frontend/                  # Flutter Mobile Application
│   ├── android/              # Android configuration
│   ├── ios/                  # iOS configuration (Runner)
│   ├── lib/
│   │   ├── features/         # Feature modules
│   │   │   ├── auth/         # Login, Register, Welcome Screen
│   │   │   ├── chat/         # Chat Interface, Providers, TTS/STT
│   │   │   ├── scenarios/    # Roleplay Scenarios
│   │   │   └── lessons/      # Lesson logic and UI
│   │   └── main.dart         # Entry point
│   ├── pubspec.yaml          # Dependencies
│   └── .env                  # Environment variables (GitIgnored)
│
├── ailanguagebuddy/           # Java Spring Boot Backend
│   ├── src/main/java/        # specific code
│   │   ├── controller/       # RestClient endpoints
│   │   ├── service/          # Business logic (AI calls)
│   │   ├── repository/       # Database access
│   │   └── model/            # JPA Entities
│   ├── src/main/resources/   # Config (application.properties)
│   ├── sql/                  # Migration scripts
│   └── run.sh                # Helper script to start backend
│
└── PROJECT_DOCUMENTATION.md   # This file
```

---

## 🛠️ Setup & Installation

### Prerequisites
- **Flutter SDK**: v3.x or later
- **Java JDK**: 21 (Required for Spring Boot 3)
- **Supabase Account**: A new project created.
- **Groq API Key**: For AI inference ([console.groq.com](https://console.groq.com)).

### 1. Database Setup (Supabase)
Run the following SQL scripts in your Supabase **SQL Editor**:
1.  **Lessons Schema**: `ailanguagebuddy/sql/lessons.sql`
2.  **Chat Modes**: `ailanguagebuddy/sql/add_mode_column.sql`

 *Note: If you don't have these files, check the repository history or ask the AI to regenerate them.*

### 2. Backend Configuration
The backend requires environment variables to run. You can export them in your terminal or creating a run configuration.

**Required Variables**:
- `GROQ_API_KEY`: Your API key from Groq.
- `DATASOURCE_URL`: JDBC URL (e.g., `jdbc:postgresql://db.projectref.supabase.co:5432/postgres?user=postgres&password=YOUR_PASSWORD`)
- `SUPABASE_URL`: `https://YOUR_PROJECT_ID.supabase.co`

### 3. Frontend Configuration
Create a file named `.env` in `frontend/` with the following content:

```properties
SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
GOOGLE_IOS_CLIENT_ID=YOUR_IOS_CLIENT_ID
GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID
```

---

## 🚀 Running the Application

### Step 1: Start the Backend
Navigate to the backend directory and run the helper script (or use Maven directly).

```bash
cd ailanguagebuddy
# Ensure env vars are set, then:
./run.sh
# OR manually:
# export GROQ_API_KEY=...
# ./mvnw spring-boot:run
```
*Server runs on port `8080` by default.*

### Step 2: Start the Frontend
In a new terminal, navigate to the frontend directory.

```bash
cd frontend
flutter pub get
flutter run
```
*Select your target device (iOS Simulator / Android Emulator).*

---

## 🔑 Authentication Details

### Google Sign-In Setup
1.  **GCP Console**: Create separate Client IDs for **iOS** and **Web**.
2.  **Supabase**: Add both Client IDs to Authentication -> Providers -> Google.
3.  **iOS Config**:
    - Add `CFBundleURLTypes` to `ios/Runner/Info.plist`.
    - Reverse Client ID: `com.googleusercontent.apps.YOUR_CLIENT_ID`
4.  **iOS Fix**: Enable **"Skip nonce check"** in Supabase Google Provider settings to prevent login errors.

---

## 📡 API Reference

### Chat Endpoints (`/api/v1/chat`)

- **POST** `/ask`
    - Request: `{"message": "Hello", "targetLanguage": "Spanish", "mode": "cafe"}`
    - Response: `{"replyText": "Hola...", "corrections": [...], "vocabulary": [...]}`
- **GET** `/history/v2`
    - Params: `?limit=50&mode=cafe`
    - Response: Paginated list of chat messages filtered by mode.

### Lesson Endpoints (`/api/v1/lessons`)

- **GET** `/`
    - Returns all lessons with `status` (LOCKED, AVAILABLE, COMPLETED).
- **POST** `/{id}/complete`
    - Marks a lesson as complete and unlocks the next one.

---

## ❓ Troubleshooting

**Q: Google Sign-In gives `Exception: com.google.GIDSignIn: -4`**
A: This usually means the URL Scheme is missing in `Info.plist`. Check that the reverse client ID is correctly added.

**Q: "Unacceptable audience" error.**
A: The backend (Supabase) received a token meant for a different client ID. Ensure your `iosClientId` and `webClientId` (serverClientId) match exactly what is in Supabase.

**Q: Chat history shows messages from other scenarios.**
A: Ensure your backend is updated with the latest `ChatController` logic that filters by `mode`. Restart the backend server.

**Q: App cannot connect to localhost (`Connection refused`).**
A: On Android emulator, use `10.0.2.2` instead of `localhost`. On iOS Simulator, `localhost` works. Configure `kBaseUrl` in `chat_provider.dart` appropriately.


### Phase 4: Real-time Voice Assistant ("The Orchestrator")
- **Goal**: Transform the system from simple HTTP interactions to a real-time, low-latency voice architecture.
- **Architecture**:
    - **Flutter (Frontend)**: Captures audio via microphone stream (Raw PCM, 16kHz, 16-bit, Mono) and sends it over WebSocket. Plays back received audio chunks.
    - **Java (Orchestrator)**: Manages WebSocket connections (`/ws/voice`). Receives audio -> Sends to Python STT -> Sends text to LLM (Groq) -> Sends LLM response to Python TTS -> Streams audio back to Flutter.
    - **Python (Voice Service)**: A lightweight FastAPI service.
        - **STT**: Uses `faster-whisper` (OpenAI Whisper model) for accurate speech-to-text. Handles both Raw PCM and WAV inputs robustly. 
        - **TTS**: Uses `chatterbox-tts` (Chatterbox-Turbo, 350M parameters) for high-quality, natural-sounding voice generation.
- **Key Technical Details**:
    - **Robustness**: The Python service includes detailed logging and error handling, auto-detecting audio formats (RIFF headers vs Raw PCM) to prevent crashes.
    - **Audio Format**: Standardized on **16kHz Sample Rate** for recording (Whisper native) and **24kHz** for playback (Chatterbox native).
    - **Security**: Hugging Face token integration for model access.
    - **Git**: Configured `.gitignore` to exclude large virtual environment files (`venv`), ensuring clean repository management.

---

## 5. Setup & Running Voice Service

To use the Real-time Voice Assistant, you must run the Python service alongside the main backend.

### 1. Setup Python Environment
Navigate to `voice-service/`:
```bash
cd voice-service
chmod +x run.sh
./run.sh
```
*The script will automatically create a virtual environment, install dependencies (`requirements.txt`), and start the FastAPI server on port 8000.*

### 2. Connect Backend
Ensure your Java Backend is running on port 8080. It will automatically connect to the Python service at `http://localhost:8000`.

### 3. Usage
- Open the App -> **Live Assistant** tab.
- Hold the microphone button to speak.
- Release to send.
- The AI will reply with both text and voice.

---

## 6. Future Roadmap
- **Gamification**: Badges, streaks, and daily goals.
- **Spaced Repetition System (SRS)**: Flashcards for vocabulary learned in chat.
- **Apple Sign-In**: Implement native Apple auth.

---

## 7. Detailed Engineering Changelog (Voice + Performance + Data Isolation)

This section documents the recent end-to-end stabilization and optimization work in detail, including architecture decisions, iterative fixes, and the final active behavior across Python, Java, Flutter, and Supabase.

### 7.1 Scope of Work
- Eliminate STT empty transcripts and language hallucinations.
- Remove audio hiss/static and playback dropouts on mobile.
- Reduce TTFB / first audible output latency in voice flow.
- Isolate `VOICE_LIVE` context from regular text chat history.
- Resolve database "invisible inserts" symptoms and improve persistence observability.
- Remove IP hardcoding issues that caused repeated WebSocket timeouts.

### 7.2 Python Voice Service (`voice-service/main.py`)

#### 7.2.1 STT backend migration and behavior
- Migrated STT loading from `faster-whisper` to `mlx-whisper` for Apple Silicon path.
- Added configurable model repo with default tiny model:
  - `STT_MODEL_REPO = mlx-community/whisper-tiny`
- Locked transcription language to English to prevent cross-language auto-detection drift:
  - `language="en"`
- Added strict RMS-based silence gate before STT to avoid noise hallucinations:
  - `SILENCE_RMS_THRESHOLD = 220`
  - If below threshold, service returns empty text without STT invocation.

#### 7.2.2 STT input handling
- Kept robust WAV/RAW PCM handling:
  - Detects RIFF WAV payload directly.
  - Wraps raw PCM as WAV (`16k`, `16-bit`, `mono`) before STT.
- Added WAV decoding helper to float32 mono@16k for MLX:
  - `_wav_bytes_to_float32(...)`.

#### 7.2.3 TTS acceleration + thermal behavior
- Forced MPS selection in current runtime profile:
  - `MODEL_DEVICE = "mps"`.
- Kept generation wrapped in:
  - `torch.inference_mode()`
  - `torch.no_grad()`
- Added startup warmup inference to reduce cold-start penalty.
- Added chunked byte streaming for TTS response:
  - `STREAM_CHUNK_BYTES = 8KB`.
- Added post-stream cache cleanup:
  - `torch.mps.empty_cache()` in stream iterator `finally` block.
  - Important: cache clear happens after synthesis stream completion, not mid-request.

#### 7.2.4 Current output contract (active)
- `/synthesize/raw` returns raw PCM bytes via:
  - `StreamingResponse(..., media_type="application/octet-stream")`.
- Audio data cast is explicit:
  - `np.int16` before `tobytes()`.

### 7.3 Java Backend (Spring Boot) — Voice Orchestration + Data Reliability

#### 7.3.1 Voice mode isolation (`VOICE_LIVE`)
- `VoiceWebSocketHandler` now constructs voice turns with mode:
  - `VOICE_LIVE`.
- This ensures all AI messages generated during voice session are stored and queried in voice channel context only.
- Effective behavior:
  - voice history = subset filtered by `(user_id, mode='VOICE_LIVE')`.

#### 7.3.2 Prompt context partitioning
- `ChatService` now builds prompt history using mode-aware query:
  - `findByUserIdAndModeOrderByCreatedAtDesc(...)`.
- Prompt injection now includes:
  - role identity (Sarah),
  - conversation history block,
  - current user input,
  - explicit LIVE VOICE instruction when mode is `VOICE_LIVE`.

#### 7.3.3 Persistence hardening for "invisible inserts"
- Added transactional boundary:
  - `@Transactional` on `ChatService.askLanguageCoach(...)`.
- Replaced deferred writes with immediate flush:
  - `repository.saveAndFlush(...)` for user and assistant rows.
- Hardened `mode` persistence:
  - null/blank fallback handling in service.
  - entity mapping set to non-null bounded string:
    - `@Column(name="mode", nullable=false, length=50)`.

#### 7.3.4 Database connection observability
- Added startup DB verification bean:
  - logs datasource host extracted from JDBC URL,
  - executes `select current_database()` and logs result.
- This is intended to catch environment mismatch (Supabase vs wrong local DB) immediately at startup.

#### 7.3.5 Network/runtime dependency on macOS
- Added Netty native DNS resolver dependency for macOS ARM:
  - `io.netty:netty-resolver-dns-native-macos`
  - classifier: `osx-aarch_64`
  - scope: `runtime`.

### 7.4 Flutter Client — Connectivity + Playback Stability

#### 7.4.1 WebSocket IP misconfiguration fix
- Removed hardcoded backend IP from chat provider.
- Unified backend base URL from config source (`defaultBackendBaseUrl`).
- WS URL builder now includes both:
  - `userId`
  - `token` (access token), matching backend voice auth expectation.

#### 7.4.2 Stream player stability settings
- Explicit stream playback settings kept:
  - `Codec.pcm16WAV`
  - `numChannels = 1`
  - `sampleRate = 24000`.
- Wrapped `startPlayerFromStream(...)` in `try-catch` with explicit error-state update on failure.

#### 7.4.3 First chunk pacing support
- Backend first-chunk pacing strategy (100ms) was added in Java voice WS to reduce startup race conditions with mobile player.
- Applied in both:
  - reactive chunk path
  - buffered chunk path.

### 7.5 Supabase / PostgreSQL Schema + Indexing

#### 7.5.1 Mode isolation support
- Added/ensured `mode` column on `chat_messages`.
- Backfilled existing null rows:
  - `mode = 'general'`.

#### 7.5.2 Query performance index
- Added composite index for scoped low-latency reads:
  - `(user_id, mode, created_at DESC)`.
- Migration:
  - `V2__chat_messages_mode_index.sql`.

### 7.6 Iterative Audio Strategy Notes (What was tried and why)
- Multiple streaming contracts were evaluated:
  - raw PCM streaming,
  - WAV header preamble + streamed PCM,
  - server-side header stripping vs client-side decoding mode.
- Final active implementation in current codebase uses:
  - Python octet-stream PCM chunks for `/synthesize/raw`,
  - Flutter stream guarded with explicit codec settings and start error handling,
  - Java WebSocket pacing for first chunk.
- Practical lesson from iteration:
  - playback hiss/drop usually comes from format mismatch (raw PCM interpreted as WAV or sample-rate mismatch),
  - startup failures often come from first-chunk timing + player init race.

### 7.7 Environment and Operational Requirements

#### 7.7.1 Required environment variables
- Backend:
  - `DATASOURCE_URL` (must point to Supabase Postgres project in use)
  - `SUPABASE_URL`
  - `GROQ_API_KEY`
- Voice service:
  - `HF_TOKEN` (if gated model access is required)
  - optional `MLX_WHISPER_MODEL`.

#### 7.7.2 Runtime validation checklist
- On backend startup logs, verify:
  - datasource host is expected Supabase host,
  - `current_database()` returns expected DB.
- In Supabase table editor, verify new rows appear with:
  - `mode='VOICE_LIVE'` for voice flows.
- On mobile client, verify:
  - WS target URL resolves to current backend host (no stale LAN IP hardcode),
  - audio stream uses 24k mono and correct codec.

### 7.8 Files Touched in This Workstream
- `voice-service/main.py`
- `ailanguagebuddy/src/main/java/com/example/ailanguagebuddy/config/VoiceWebSocketHandler.java`
- `ailanguagebuddy/src/main/java/com/example/ailanguagebuddy/service/ChatService.java`
- `ailanguagebuddy/src/main/java/com/example/ailanguagebuddy/service/PromptBuilder.java`
- `ailanguagebuddy/src/main/java/com/example/ailanguagebuddy/model/ChatMessage.java`
- `ailanguagebuddy/src/main/java/com/example/ailanguagebuddy/config/DatabaseConnectionVerifier.java`
- `ailanguagebuddy/src/main/resources/db/migration/V2__chat_messages_mode_index.sql`
- `ailanguagebuddy/pom.xml`
- `frontend/lib/core/config.dart`
- `frontend/lib/features/chat/presentation/providers/chat_provider.dart`
- `frontend/lib/features/chat/presentation/pages/live_speech_page.dart`

### 7.9 Current Known Constraints
- `MODE_DEVICE` is currently forced to `"mps"` in active voice-service profile. On non-Apple-Silicon environments this should be guarded/fallback-enabled before production deployment.
- Voice WebSocket handler currently uses query parameter parsing for `userId`; in hardened production environments, JWT subject extraction should be the primary source of identity.
- If Supabase RLS is enabled with restrictive policies for server role/user role, rows may still not appear despite successful insert SQL logs. Validate policy rules for backend connection role.
