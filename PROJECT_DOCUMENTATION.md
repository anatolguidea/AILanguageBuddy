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

