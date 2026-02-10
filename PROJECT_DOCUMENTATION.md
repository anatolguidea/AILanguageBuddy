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


mplementation Plan - Phase 4: Real-time Voice Assistant ("The Orchestrator")
Goal
Transform the system from HTTP Request/Response to a Real-time Streaming Architecture to support low-latency voice conversations.

Architecture: The Orchestrator Model
Component	Tech Stack	Role
Frontend	Flutter	Capture microphone stream, play audio stream, UI.
Orchestrator	Java Spring Boot	Manage WebSockets, route audio to/from Voice Engine, route text to/from LLM.
Voice Engine	Python (FastAPI) + Chatterbox	New Service. Exposes STT/TTS via HTTP/WebSocket to the Java Orchestrator.
Brain	Spring AI + Groq	Existing integration for intelligence.
Note on Voice Engine: Since Chatterbox is a Python library, we cannot run it inside the Java process. We will create a lightweight Python service (using FastAPI) that wraps Chatterbox and communicates with the Java Orchestrator.

Step-by-Step Implementation
1. Chatterbox Service (Python)
Setup: Create voice-service directory.
Dependencies: fastapi, uvicorn, chatterbox-tts, torch, torchaudio.
Endpoints:
POST /transcribe: Accepts audio bytes, returns text (STT).
POST /synthesize: Accepts text, returns audio bytes (TTS).
Model: Use Chatterbox-Turbo (350M) for low latency.
2. Java Orchestrator (Spring Boot)
Dependencies: Add spring-boot-starter-websocket.
WebSocket Handler: Create /ws/voice endpoint.
On Message (Binary): Receive audio chunk from Flutter -> Send to Python STT -> Get Text.
Processing: Send Text to Groq (LLM) -> Get Response.
On Response: Send Text to Python TTS -> Get Audio -> Send to Flutter via WebSocket.
Client: WebClient or HttpClient to talk to the Python service.
3. Frontend (Flutter)
Dependencies: web_socket_channel, flutter_sound (or record/audioplayers for streams).
New Screen: LiveSpeechPage (Modern, minimal UI with "Listening" state visualization).
Audio Logic:
Stream microphone data to WebSocket.
Buffer and play received audio data.
Navigation: Add "Live" tab to MainScaffold.
4. Refactor Existing Chat
Disable Auto-TTS: In 
ChatNotifier
, remove 
speak(aiReply)
.
Manual Play: Add IconButton (Speaker) to ChatBubble. On tap, trigger TTS for that specific message.
Task Breakdown
 Setup Python Voice Service: Install Chatterbox, build FastAPI wrapper.
 Update Java Backend: Configure WebSocket, implement Orchestrator logic.
 Refactor Existing Chat: Remove auto-TTS, add play button.
 Implement Frontend Audio: Build LiveSpeechPage and WebSocket integration.
