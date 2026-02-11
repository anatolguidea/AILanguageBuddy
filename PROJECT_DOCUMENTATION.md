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
    - **Voice Integration**:
        - `flutter_sound` for raw PCM microphone capture and playback.
        - `web_socket_channel` for full-duplex transport with backend voice orchestrator.
        - `audio_session` for platform-appropriate voice call audio behavior.
        - `permission_handler` for microphone runtime permissions.
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
│   │   │   └── voice/        # Voice orchestration ports + use case
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

### Phase 4.1: Production Hardening & Clean Architecture Upgrade (Implemented)
- **Date**: February 11, 2026
- **Objective**: Stabilize live voice flow, harden authentication/error handling, and refactor voice orchestration for maintainability and reuse.

#### A. Backend (Spring Boot) Refactor
- Introduced clean voice orchestration primitives under `service/voice`:
    - `SpeechToTextPort`
    - `TextToSpeechPort`
    - `TutorModelPort`
    - `ProcessVoiceTurnUseCase`
    - `VoiceTurnException`
    - `ChatTutorAdapter`
- Refactored `VoiceWebSocketHandler` into a transport adapter role:
    - Handler now authenticates, buffers incoming binary audio, triggers the use case, and emits typed events.
    - Turn pipeline moved from handler internals to `ProcessVoiceTurnUseCase`:
        1. Validate audio and authenticated user
        2. STT (audio -> transcript)
        3. Tutor model (transcript -> reply text)
        4. TTS (reply text -> PCM16 audio)
- `VoiceServiceClient` now implements `SpeechToTextPort` and `TextToSpeechPort` and throws typed exceptions on failures instead of returning fallback transcript text.

#### B. WebSocket Security and Protocol Changes
- WebSocket endpoint `/ws/voice` now requires a Supabase JWT passed via query param `token`.
- User identity is derived from JWT `sub` claim (UUID), not trusted from raw query `userId`.
- On invalid/missing token:
    - backend emits structured error event
    - connection is closed with reason.
- Voice turn control was upgraded from plain-text sentinel to typed JSON control events:
    - `{"event":"start_turn"}`: resets per-session buffer and marks beginning of a new push-to-talk turn.
    - `{"event":"end_turn"}`: finalizes buffered audio and triggers the orchestration pipeline.
    - Backward compatibility is still kept for legacy `"EOS"` payloads.
- WebSocket text frames now use structured JSON event payloads:
    - `connected`
    - `processing`
    - `transcript`
    - `assistant_text`
    - `error` (with optional `code`)
- Binary frame processing was fixed to safely copy only `ByteBuffer.remaining()` bytes (instead of relying on `.array()`).

#### C. Frontend Voice Client Improvements
- `live_speech_page.dart` updated to:
    - build authenticated WS URL with `userId` + `token`.
    - send typed control events (`start_turn` / `end_turn`) instead of raw EOS strings.
    - parse structured JSON text events from backend.
    - manage recorder stream controller lifecycle safely per turn.
    - cancel previous socket subscriptions before reconnect.
    - guard recorder startup behind async audio initialization.
- Android release readiness hardening:
    - Added `android.permission.INTERNET`
    - Added `android.permission.RECORD_AUDIO`
    - File: `frontend/android/app/src/main/AndroidManifest.xml`

#### D. Python Voice Service (Chatterbox) Runtime Improvements
- Added Chatterbox warmup at startup after model load.
- Added synthesis lock (`threading.Lock`) around TTS inference to prevent concurrent resource contention.
- Wrapped generation in `torch.inference_mode()` for efficient inference.
- Added explicit audio metadata headers on `/synthesize/raw` responses:
    - `X-Audio-Sample-Rate: 24000`
    - `X-Audio-Format: pcm16le-mono`
- Expanded `/health` payload with `tts_sample_rate`.

#### E. CORS/WebSocket Configuration
- `WebSocketConfig` now uses configured CORS origins from `app.cors.allowed-origins` instead of hardcoded `"*"`.

#### F. Validation Performed
- Java backend compile check:
    - `./mvnw -q -DskipTests compile` (success)
- Java voice WebSocket contract tests:
    - `./mvnw -q -Dtest=VoiceWebSocketHandlerTest test` (success)
    - Covered scenarios:
        - authenticated handshake emits `connected`
        - successful turn emits `processing` -> `transcript` -> `assistant_text` + binary audio
        - typed error events on use-case failures (`code` + `message`)
        - invalid token closes connection and emits `error`
        - `start_turn` resets buffered audio before `end_turn`
- Python syntax check:
    - `python3 -m py_compile voice-service/main.py` (success)
- Dart formatting:
    - `dart format frontend/lib/features/chat/presentation/pages/live_speech_page.dart frontend/lib/features/chat/data/models/voice_models.dart`

### Phase 4.2: Typed Voice Protocol Consolidation (Implemented)
- **Date**: February 11, 2026
- **Objective**: Remove stringly-typed voice protocol handling and centralize event contracts across backend and frontend.

#### A. Backend Protocol Contract Types
- Added shared protocol types in Java:
    - `service/voice/protocol/VoiceEventType.java`
    - `service/voice/protocol/VoiceEventMessage.java`
    - `service/voice/protocol/VoiceControlMessage.java`
- `VoiceWebSocketHandler` now:
    - parses control frames into `VoiceControlMessage` (instead of manual `JsonNode` string checks)
    - maps event semantics via `VoiceEventType`
    - emits typed `VoiceEventMessage` payloads.

#### B. Frontend Protocol Contract Types
- Added shared voice model file:
    - `frontend/lib/features/chat/data/models/voice_models.dart`
- Includes:
    - `VoiceEventType` enum with wire values
    - `VoiceEventMessage` parser
    - `VoiceControlMessage` serializer.
- `live_speech_page.dart` migrated to:
    - parse incoming events through `VoiceEventMessage.fromJson`
    - send `start_turn` and `end_turn` via typed control model serialization.

#### C. Resulting Design Benefits
- Single source of truth for voice event names on each side.
- Lower risk of regressions due to typos in raw string event handling.
- Easier extension for future events (`partial_transcript`, `vad_state`, `tts_chunk`).
- Cleaner, testable message parsing/serialization paths.

### Phase 4.3: WebSocket Integration Test Harness (Implemented)
- **Date**: February 11, 2026
- **Objective**: Validate wire-level voice protocol behavior with a running server and a real WebSocket client, beyond handler unit tests.

#### A. Added Integration Test
- New file:
    - `ailanguagebuddy/src/test/java/com/example/ailanguagebuddy/config/VoiceWebSocketIntegrationTest.java`
- Test boot mode:
    - `@SpringBootTest(webEnvironment = RANDOM_PORT)` with a minimal test application importing only websocket-related configuration.
- Test transport:
    - Uses JDK `java.net.http.WebSocket` client to connect to `/ws/voice` over an actual HTTP upgrade handshake.

#### B. What It Verifies End-to-End
- Successful connection emits structured `connected` event.
- Push-to-talk turn emits ordered protocol events:
    - `processing` -> `transcript` -> `assistant_text`
    - followed by binary audio payload.
- `start_turn` control event resets buffered audio so only post-reset audio is processed at `end_turn`.
- Invalid-token connection emits structured `error` event at wire level.

#### C. Test Isolation/Determinism Strategy
- Integration test provides deterministic in-memory voice ports via a `VoiceTestState` bean:
    - controlled transcript text
    - controlled assistant reply text
    - controlled reply audio bytes
- Security/Data/AI auto-config noise reduced in test context via explicit property exclusions and AI model disable flags to keep the integration focus on the websocket voice contract itself.

### Phase 4.4: Protocol Versioning (Implemented)
- **Date**: February 11, 2026
- **Objective**: Add explicit protocol version metadata to voice websocket payloads for forward-compatible contract evolution.

#### A. Backend Changes
- `VoiceEventMessage` now includes `v` (protocol version).
- `VoiceControlMessage` now accepts optional `v`.
- `VoiceWebSocketHandler` emits `v=1` for all server text events while keeping backward-compatible parsing for incoming control messages (version can be omitted).

#### B. Frontend Changes
- `voice_models.dart` updated:
    - `VoiceEventMessage` now parses `v` and defaults to `1` when absent.
    - `VoiceControlMessage` now serializes `v` (default `1`) together with `event`.
- `live_speech_page.dart` keeps behavior unchanged while now sending versioned control frames through typed models.

#### C. Compatibility Notes
- Existing clients without `v` remain compatible (default handling).
- New clients can branch behavior by `v` when protocol evolves (e.g., chunk metadata, partial transcripts, VAD events).

### Phase 4.5: Voice Runtime Safety Guards (Implemented)
- **Date**: February 11, 2026
- **Objective**: Improve live-speech stability and fail-safe behavior during long/invalid turns.

#### A. Server-Side Turn Size Guard
- `VoiceWebSocketHandler` now enforces a max buffered turn size:
    - `MAX_TURN_AUDIO_BYTES = 2_000_000`
- If incoming binary chunks exceed this threshold:
    - turn buffer is reset
    - structured error is emitted: `code = audio_too_large`
    - oversized turn is discarded before STT/LLM/TTS execution.

#### B. Frontend Protocol Compatibility Guard
- Flutter live speech page now validates incoming `v` protocol value.
- If server `v` is higher than supported client version:
    - client enters error state with explicit incompatibility message
    - avoids undefined behavior from unsupported future protocol changes.

#### C. Test Coverage Extension
- `VoiceWebSocketHandlerTest` now verifies:
    - `v=1` on emitted events
    - `audio_too_large` behavior when limit is exceeded.
- `VoiceWebSocketIntegrationTest` now verifies:
    - `v=1` present on wire-level event messages
    - versioned control frames (`{"v":1,"event":"start_turn|end_turn"}`) remain functional.

### Phase 4.6: Session State Machine Hardening (Implemented)
- **Date**: February 11, 2026
- **Objective**: Prevent invalid voice-turn sequencing and race-condition side effects in live speech flow.

#### A. Backend Session State Machine
- Added per-session backend state tracking:
    - `CONNECTED`
    - `LISTENING`
    - `PROCESSING`
- Transition rules enforced in `VoiceWebSocketHandler`:
    - `start_turn` -> enters `LISTENING` and resets current turn buffer.
    - Binary audio accepted only in `LISTENING` (or auto-promoted from `CONNECTED` for legacy compatibility).
    - `end_turn` valid only from `LISTENING`; otherwise emits `invalid_state`.
    - After processing completes/fails, state returns to `CONNECTED`.

#### B. Frontend State Transition Guard
- Added guarded UI status transition function in `live_speech_page.dart`.
- Prevents illegal jumps between `idle/listening/processing/speaking/error` caused by async socket and recorder callbacks arriving out of order.

#### C. Additional Test Assertions
- Unit tests now cover invalid state handling (`end_turn` while not listening) and continue validating oversized-turn safety.

### Phase 4.7: Turn Timeout + Partial Transcript Milestone (Implemented)
- **Date**: February 11, 2026
- **Objective**: Improve resilience of long-running voice sessions and introduce first streaming-style transcript feedback.

#### A. Session Housekeeping and Timeout Recovery
- Added background housekeeping in `VoiceWebSocketHandler`:
    - runs every 5 seconds
    - tracks `last activity` per websocket session.
- New protection rules:
    - **Listening timeout** (`20s`): if a turn stays in `LISTENING` with no audio activity, server resets turn and emits `turn_timeout`.
    - **Stale session timeout** (`300s`): inactive sessions are closed/cleaned up to prevent memory growth.
- New internal registries:
    - session map (`session id` -> `WebSocketSession`)
    - last-activity timestamps
    - explicit cleanup paths on disconnect and stale eviction.

#### B. Partial Transcript Event Groundwork
- Protocol now supports `partial_transcript` event type.
- Backend emits incremental partial transcript events for longer transcripts before sending the final `transcript`.
- Flutter live speech page now handles `partial_transcript` by updating transcript preview in realtime.

#### C. Validation Coverage
- `VoiceWebSocketHandlerTest` now verifies:
    - `partial_transcript` emission for long transcripts.
- `VoiceWebSocketIntegrationTest` now verifies:
    - wire-level partial transcript behavior through real websocket flow.

### Phase 4.8: Assistant Partial + Chunked Audio Delivery (Implemented)
- **Date**: February 11, 2026
- **Objective**: Reduce perceived response latency by streaming assistant progress signals and chunking voice audio transport.

#### A. New Voice Protocol Events
- Added protocol event types:
    - `assistant_partial`
    - `audio_end`
- Backend now emits incremental `assistant_partial` updates for longer assistant replies before final `assistant_text`.

#### B. Chunked Audio Transport
- Backend no longer sends a single large binary payload only.
- Reply audio is split into fixed-size binary chunks (`8192` bytes) and sent sequentially.
- After all chunks are sent, backend emits `audio_end`.

#### C. Frontend Playback Strategy
- Flutter voice client now:
    - buffers incoming binary chunks while waiting for `audio_end`
    - starts playback once `audio_end` arrives
    - falls back to immediate playback if chunk mode is not active (compatibility behavior).
- Error/disconnect paths clear pending chunk buffers to avoid stale audio playback.

#### D. Test Coverage Updates
- Unit and integration test suites continue passing with the new chunked transport and additional partial assistant events.

### Phase 4.9: Throttled Mid-Turn STT + Streamed Chunk Playback (Implemented)
- **Date**: February 11, 2026
- **Objective**: Move from post-turn-only transcript feedback to real in-progress transcript updates and lower playback latency by consuming audio chunks as they arrive.

#### A. Mid-Turn Partial STT (Backend)
- Added `GeneratePartialTranscriptUseCase` to isolate partial STT generation from full turn orchestration.
- During `LISTENING`, backend now attempts throttled partial STT on buffered audio snapshots:
    - minimum buffered audio: `32,000` bytes
    - minimum interval between partial attempts: `1.2s`
- Duplicate partials are suppressed per session (`last partial text` tracking) to avoid noisy UI updates.

#### B. Streaming Chunk Playback (Frontend)
- Flutter voice client now uses a chunk queue for streamed playback:
    - binary chunks are queued as they arrive after `assistant_text`
    - playback drains progressively from the queue (instead of waiting for full buffered audio)
    - `audio_end` marks stream completion and finalizes status transition to `idle` when queue is empty.
- Error/disconnect/start-turn flows clear queue and streaming flags to prevent stale or mixed-turn playback.

#### C. Regression-Safety Improvements
- Unit tests now assert presence of `audio_end` for successful turn responses.
- Integration tests now validate:
    - `audio_end` event on wire
    - presence of `assistant_partial` and `partial_transcript` in long-turn scenario.

### Phase 4.10: Dedicated Fast Partial-STT Pipeline (Implemented)
- **Date**: February 11, 2026
- **Objective**: Reduce latency/cost of mid-turn transcript updates by separating full-turn STT from partial STT behavior.

#### A. Java Voice Service Contract Split
- Added `PartialSpeechToTextPort` for partial-turn transcription.
- `GeneratePartialTranscriptUseCase` now depends on this dedicated partial port instead of full STT path.
- `VoiceServiceClient` now exposes:
    - `transcribe(...)` -> full endpoint
    - `transcribePartial(...)` -> fast partial endpoint

#### B. Python Voice Service Endpoint Split
- Added shared transcription helper to avoid duplicate decode/wrapping logic.
- Added optimized endpoint:
    - `POST /transcribe/partial`
    - uses lower beam size (`beam_size=1`) for faster response
    - supports `max_words` limiting (default `20`) to keep partial payloads compact.
- Existing `POST /transcribe` remains full-quality (`beam_size=5`) for final-turn processing.

#### C. Integration Notes
- Mid-turn partials now use a lighter STT path while final transcript quality is preserved.
- This keeps the current Java orchestrator architecture intact while preparing for future native streaming STT.

### Phase 4.11: Progressive Chunk Queue Playback (Implemented)
- **Date**: February 11, 2026
- **Objective**: Eliminate full-buffer wait before playback and consume audio chunks progressively as they arrive.

#### A. Playback Behavior Update (Flutter)
- Replaced single list accumulation strategy with explicit chunk queue + drain loop:
    - incoming binary chunks are appended to queue while stream is active
    - playback drains chunk-by-chunk in order
    - `audio_end` marks stream completion and final state transition to idle when queue is empty.

#### B. Reliability Enhancements
- Queue and stream flags are reset on:
    - new turn start
    - websocket error
    - websocket disconnect.
- This avoids stale chunk bleed between turns and improves resilience under reconnect scenarios.

### Phase 4.12: Adaptive Jitter Buffer Policy (Implemented)
- **Date**: February 11, 2026
- **Objective**: Smooth chunk playback under network jitter while preventing queue-induced latency growth.

#### A. Prebuffer Strategy
- Flutter waits for a minimal chunk/byte threshold before draining playback when stream is still active:
    - min chunks: `2`
    - min bytes: `12 KB`
- Prevents immediate underflow/stutter when first chunks arrive slowly.

#### B. Queue Watermark Protection
- Added queue watermark control to avoid runaway latency:
    - high watermark: `192 KB`
    - trim target: `128 KB`
- If queue exceeds high watermark, oldest buffered chunks are dropped until trim target is reached.

#### C. Operational Impact
- Better continuity under bursty transport conditions.
- Bounded queue memory and bounded playback lag for long responses on unstable links.

### Phase 4.13: Runtime Playback Policy + Client Telemetry (Implemented)
- **Date**: February 11, 2026
- **Objective**: Make playback buffering tunable from backend protocol and improve observability of live audio stream behavior.

#### A. Backend Protocol Extension for Runtime Playback Policy
- Extended `VoiceEventMessage` contract with optional `data` payload (`Map<String, Object>`).
- `VoiceWebSocketHandler` now emits a typed `jitter_config` event immediately after `connected`.
- Delivered playback policy fields in `data`:
    - `prebufferChunks`
    - `prebufferBytes`
    - `queueHighWatermarkBytes`
    - `queueTrimTargetBytes`
- This keeps transport protocol version stable (`v=1`) while enabling server-driven playback tuning.

#### B. Frontend Runtime Application of Jitter Policy
- Flutter `voice_models.dart` now parses optional `data` in incoming voice events and recognizes `jitter_config`.
- `live_speech_page.dart` now:
    - applies `jitter_config` values dynamically at runtime with positive-integer validation.
    - enforces safe relationship between queue limits (`trim target < high watermark`) with fallback correction.
    - uses mutable jitter thresholds instead of hardcoded compile-time constants, improving reuse and rollout safety.

#### C. Client-Side Voice Stream Telemetry
- Added lightweight playback telemetry in Flutter notifier for each assistant audio stream:
    - received chunk count
    - dropped chunk count (watermark trims)
    - peak queued bytes
    - stream duration in milliseconds
- Telemetry is logged on `audio_end` to support tuning and diagnostics without impacting protocol behavior.

#### D. State Management Correction (Critical Fix)
- Fixed `LiveSpeechNotifier` status transition guard placement:
    - `_transitionStatus(...)` is now a notifier method (class-scoped), not an orphan top-level function.
- This restores valid compilation and ensures all internal state transitions are actually guarded at runtime.

#### E. Validation Performed
- Dart formatting and parser validation:
    - `/Users/anatolguidea/Development/flutter/bin/cache/dart-sdk/bin/dart format frontend/lib/features/chat/presentation/pages/live_speech_page.dart frontend/lib/features/chat/data/models/voice_models.dart`
- Voice websocket tests:
    - `./mvnw -q -Dtest=VoiceWebSocketHandlerTest,VoiceWebSocketIntegrationTest test`
    - Updated assertions cover `jitter_config` emission and payload shape.

### Phase 4.14: Voice Runtime Metrics Integration (Implemented)
- **Date**: February 11, 2026
- **Objective**: Add production-grade metrics for live voice websocket flow to support tuning, alerting, and capacity planning.

#### A. Infrastructure Integration
- Added Spring Boot Actuator dependency in backend build:
    - `spring-boot-starter-actuator`
- Enabled web exposure for health and metrics endpoints:
    - `management.endpoints.web.exposure.include=health,metrics`
- Result: runtime metrics can be queried via `/actuator/metrics` and metric-specific paths.

#### B. VoiceWebSocketHandler Instrumentation
- Added Micrometer instrumentation in `VoiceWebSocketHandler` while preserving existing constructor compatibility for tests.
- Added counters:
    - `voice.ws.connections.opened`
    - `voice.ws.connections.auth_failures`
    - `voice.turn.started`
    - `voice.turn.completed`
    - `voice.turn.failed`
    - `voice.partial_transcript.generated`
    - `voice.audio.chunks.sent`
    - `voice.ws.errors{code=...}`
- Added distribution summaries:
    - `voice.turn.audio.input.bytes`
    - `voice.turn.audio.output.bytes`
- Added processing timer:
    - `voice.turn.processing.duration`

#### C. Behavioral Mapping of Metrics
- Connection/auth metrics are emitted during websocket handshake.
- Turn lifecycle metrics are emitted on start, completion, and failure paths.
- Audio payload size summaries are recorded per processed turn (input and generated output).
- Partial transcript generation and outgoing chunk send metrics are emitted per event/chunk.
- Structured error events increment `voice.ws.errors` tagged by error code for failure taxonomy visibility.

#### D. Operational Outcome
- Enables quantitative latency and throughput tuning of live speech.
- Supports detecting regressions in:
    - turn failure rate
    - audio payload growth
    - partial-transcript behavior
    - websocket authentication failures.

### Phase 4.15: Client WebSocket Resilience (Implemented)
- **Date**: February 11, 2026
- **Objective**: Improve live voice reliability on unstable mobile networks through controlled automatic reconnect behavior.

#### A. Auto-Reconnect Strategy (Flutter)
- Implemented guarded reconnect loop in `LiveSpeechNotifier` with:
    - exponential backoff (`1s` base, capped at `20s`)
    - reconnect-attempt tracking
    - timer-based scheduling to avoid tight retry loops.
- Reconnect triggers on websocket:
    - stream error callback
    - close callback
    - initial connection failure.

#### B. Safety Guards and Lifecycle Handling
- Added guards to prevent reconnect conflicts:
    - no reconnect while notifier is disposing/disposed
    - no duplicate reconnect timers
    - no reconnect while actively listening/processing/speaking turn state
    - manual reconnect resets retry attempts and cancels pending retries.
- Added state cleanup on socket failure/close by nulling active channel before scheduling reconnect.

#### C. UX/Behavior Outcome
- Improves user experience during transient network interruptions:
    - voice page recovers connection automatically in idle/error states
    - avoids runaway retry storms and race conditions during manual reconnect attempts.

### Phase 4.16: Voice Ops Pack (Prometheus + Grafana) (Implemented)
- **Date**: February 11, 2026
- **Objective**: Make voice metrics operationally actionable by exporting Prometheus metrics and shipping baseline dashboard/alert assets.

#### A. Backend Prometheus Export
- Added Prometheus registry dependency to backend build:
    - `io.micrometer:micrometer-registry-prometheus`
- Extended actuator endpoint exposure:
    - `management.endpoints.web.exposure.include=health,metrics,prometheus`
- Runtime endpoints now support:
    - `/actuator/metrics` (metric discovery/debug)
    - `/actuator/prometheus` (scrape endpoint).

#### B. Operational Artifacts Added
- Added new observability package under:
    - `ops/observability/`
- Included artifacts:
    - `ops/observability/grafana/voice-runtime-dashboard.json`
    - `ops/observability/prometheus/voice-alert-rules.yml`
    - `ops/observability/README.md`

#### C. Dashboard Coverage
- Dashboard panels include:
    - voice turns started vs completed throughput
    - failure ratio
    - p95 processing latency
    - websocket auth-failure rate
    - average input/output audio bytes per turn
    - error-rate breakdown by structured error code.

#### D. Baseline Alerts
- Added initial rules for:
    - elevated turn failure ratio
    - high p95 turn latency
    - auth failure spikes
    - repeated `audio_too_large` errors.
- Rules are intentionally conservative and intended for post-baseline tuning.

#### E. Rollout Guidance
- Import Grafana dashboard JSON.
- Load Prometheus rule file into existing alert pipeline.
- Validate metric names and tune thresholds after baseline traffic window (24-48h).

### Phase 4.17: Long-Reply Playback Integrity Tuning (Implemented)
- **Date**: February 11, 2026
- **Objective**: Prevent truncated assistant speech on longer responses by reducing queue-drop pressure and protecting full-turn audio continuity.

#### A. Backend Runtime Jitter Policy Update
- Increased default queue policy emitted via websocket `jitter_config`:
    - `queueHighWatermarkBytes`: `2 MB`
    - `queueTrimTargetBytes`: `1.5 MB`
- This ensures normal long replies do not enter trim mode during steady playback.

#### B. Frontend Guardrails
- Updated Flutter defaults to match larger queue capacity.
- Added minimum policy floors when applying server config:
    - high watermark floor: `768 KB`
    - trim target floor: `512 KB`
- Added hard-cap safety (`8 MB`) so trim only activates aggressively in pathological cases.

#### C. Playback Outcome
- Assistant responses now preserve complete phrase playback more reliably under long-turn conditions.
- Reduces both “missing first words” and “missing ending words” caused by queue overflow trimming.

### Phase 4.18: Voice Reply Length Governance (Implemented)
- **Date**: February 11, 2026
- **Objective**: Reduce end-to-end TTS latency and playback truncation risk by constraining assistant verbosity in voice mode.

#### A. Voice-Only Reply Compaction
- Implemented in `ChatTutorAdapter` (voice pipeline adapter only):
    - max `2` sentences
    - max `220` characters
- Compaction runs only for live voice turn generation and does not alter the standard chat text pipeline behavior.

#### B. Why This Improves Runtime Quality
- Long-paragraph responses from LLM caused expensive TTS generation windows and large PCM payloads.
- Constraining voice responses keeps:
    - synthesis duration shorter
    - audio payload sizes smaller
    - client queue pressure lower
    - first-audio and end-of-audio reliability higher.

#### C. Validation
- Backend compile and targeted voice suites pass after the change:
    - `./mvnw -q -DskipTests compile`
    - `./mvnw -q -Dtest=VoiceWebSocketHandlerTest,VoiceWebSocketIntegrationTest test`

### Phase 4.19: Segmented TTS Streaming in Voice WebSocket (Implemented)
- **Date**: February 11, 2026
- **Objective**: Start delivering assistant audio earlier and reduce single-call TTS blocking by synthesizing/sending reply segments incrementally.

#### A. Use Case Split (Non-breaking)
- `ProcessVoiceTurnUseCase` now exposes:
    - `executeTextOnly(...)` -> validates/authenticates/transcribes/generates reply text (no TTS)
    - existing `execute(...)` remains available for compatibility and delegates to `executeTextOnly(...)` + TTS.

#### B. WebSocket Orchestrator Streaming Change
- `VoiceWebSocketHandler` now:
    - calls `executeTextOnly(...)` to produce transcript + assistant text
    - splits assistant reply into bounded sentence segments
    - synthesizes each segment via `TextToSpeechPort`
    - immediately sends chunked binary audio per synthesized segment
    - emits `audio_end` after all segments.
- Segment policy:
    - max segment chars: `180`
    - max segments: `8`

#### C. Runtime/Observability Impact
- Lower time-to-first-audio for medium/long replies.
- More resilient handling of long replies vs one monolithic TTS synthesis call.
- Existing metrics and websocket protocol remain compatible.

#### D. Test/Build Validation
- Updated unit tests to new handler dependency graph (`TextToSpeechPort`) and `executeTextOnly` flow.
- Targeted verification successful:
    - `./mvnw -q -DskipTests compile`
    - `./mvnw -q -Dtest=VoiceWebSocketHandlerTest,VoiceWebSocketIntegrationTest test`

### Phase 4.20: Live Voice UI Modernization (Implemented)
- **Date**: February 11, 2026
- **Objective**: Upgrade the live speech screen to a modern, model-style voice interaction UI with better visual clarity and state feedback.

#### A. Visual Redesign
- Replaced the old minimal center-ring UI with:
    - gradient atmospheric background
    - glass-style speech bubble card (status + transcript/error text)
    - modern central voice orb with adaptive color states.

#### B. Animated Wave System
- Added concentric animated wave rings around the orb using a custom painter and animation controller.
- Waves activate for active voice states (`listening`, `processing`, `speaking`) and pause in idle/error.
- Ring color adapts to state for immediate visual context.

#### C. UX Improvements
- Preserved long-press push-to-talk interaction semantics.
- Added stronger state language:
    - top speech bubble content for transcript/status/error context
    - clear title/hint messaging under orb
    - reconnect action grouped in a dedicated modern control container.

#### D. Responsiveness/Compatibility
- Layout uses width constraints for mobile and larger screens.
- No voice transport/protocol behavior was changed in this phase; only presentation layer updates were made.

### Phase 4.21: Multilingual Interactive Lessons Engine (Implemented)
- **Date**: February 11, 2026
- **Objective**: Replace static text-only lessons with reusable, progressive, exercise-based lessons for all supported app languages.

#### A. Clean Architecture Refactor for Lesson Content
- Added typed lesson content entities in Flutter domain layer:
    - `LessonContent`
    - `ArrangeWordsExercise`
- Added a mapper in data layer:
    - `LessonContentMapper.fromMap(...)`
    - Parses backend `content` payload into typed domain objects.
- Upgraded `Lesson` entity:
    - added `languageCode`
    - improved status parser so backend `started` is treated as `available`.

#### B. Curriculum Expansion for All Supported Languages
- Added `LocalLessonsCatalog` with progressive lesson packs for:
    - `en`, `es`, `fr`, `de`, `it`, `pt`, `ru`, `ja`, `zh`
- Each language now includes a 4-step progression:
    1. greetings basics
    2. self-introduction
    3. daily-routine longer sentences
    4. opinion + reason construction
- Each lesson includes structured arrange-words exercises with:
    - prompt
    - hint
    - word bank
    - expected solution order

#### C. Repository Merge Strategy (Backend + Local Reuse)
- `LessonsRepository` now merges sources instead of depending on backend-only content:
    - local curriculum is always available (guaranteed UX coverage)
    - backend lesson statuses (when present) are reused by `orderIndex`
    - local in-memory completion is used for locally generated lessons.
- Unlocking remains sequential (`locked` -> `available` -> `completed`) and is calculated consistently across merged data.

#### D. Lesson Detail Experience Upgrade
- Replaced text-only lesson detail rendering with an interactive exercise flow:
    - drag-and-drop words into sentence slots
    - tap-to-place for quick mobile interaction
    - tap slot to return word to bank
    - per-exercise validation with explicit feedback
    - next exercise unlock after correct answer
    - lesson completion enabled only after required exercises are solved.
- Completion call behavior:
    - backend lessons call `/api/v1/lessons/{id}/complete`
    - local-generated lessons update local completion tracking safely.

#### E. Validation
- Formatting and static analysis completed for updated lessons module.
- Command run:
    - `/Users/anatolguidea/Development/flutter/bin/cache/dart-sdk/bin/dart analyze frontend/lib/features/lessons`
- Result:
    - `No issues found!`

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
