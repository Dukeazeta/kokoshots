# KokoShots - AI-Powered Screenshot Manager

## Overview
An Android app that scans your device screenshots, uses AI vision to understand and categorize them, and lets you chat with an AI to find any screenshot by describing what you're looking for.

## Tech Stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter (Android-first) |
| AI Model | Google Gemini Vision API |
| Local Storage | SQLite via `sqflite` |
| Photo Access | `photo_manager` |
| Chat | Gemini multimodal chat API via REST |
| State Management | Riverpod |
| Navigation | `go_router` |

---

## Architecture

### 1. Screenshot Discovery
- **On first launch**: Batch-process all existing screenshots in the background (queued, throttled to avoid hammering the API)
- **Ongoing**: Poll the device gallery at a regular interval to detect new screenshots and process them immediately
- Use `photo_manager` to request Android media permissions and query the device's screenshot album/folder
- Wrap media scanning in a Flutter service so UI widgets can subscribe to indexing progress

### 2. AI Analysis Pipeline
For each new/unchanged screenshot:
1. Load screenshot image
2. Send to Gemini Vision API with a prompt asking for:
   - A short text description of the screenshot
   - Relevant tags (e.g., "receipt", "meme", "chat", "map", "code", "social media", "banking", etc.)
3. Parse and store the response in the local SQLite database

### 3. Data Model

**Screenshot table:**
| Field | Type | Description |
|-------|------|-------------|
| id | String (UUID) | Primary key |
| file_path | String | Path to the screenshot file |
| thumbnail_path | String | Path to cached thumbnail |
| description | Text | AI-generated short summary |
| tags | Text (JSON array) | Auto-generated tags |
| date_taken | DateTime | Original screenshot date |
| date_indexed | DateTime | When AI processed it |
| is_processed | Boolean | Whether AI analysis is complete |

### 4. Chat Interface
- Uses Gemini's multimodal chat API through Flutter HTTP calls with session memory
- Chat context: the AI has access to the indexed screenshot metadata (descriptions + tags)
- User can ask natural language queries like:
  - "Show me screenshots of receipts from last month"
  - "Find that meme with the cat"
  - "Screenshots of my bank app"
- The app interprets the AI's search intent, queries the local SQLite database, and returns matching screenshots
- Chat history persists across sessions (stored locally)

### 5. Storage
- **All data stored on-device** (SQLite)
- No cloud sync, no backend, no auth
- Privacy-first: screenshot content and metadata never leave the device (except the Gemini API calls for analysis)

---

## User Flow

### First Launch
1. User opens app
2. App requests storage/photo permissions
3. App discovers all screenshots on device
4. Background batch processing begins (with progress indicator)
5. User sees a home screen with screenshots organized by AI-generated categories

### Daily Use
1. New screenshots are detected via gallery polling and auto-indexed
2. User browses screenshots by category/tags
3. User can open chat and ask to find specific screenshots
4. AI returns matching screenshots with context

---

## Key Features (v1)

- [x] Auto-discover all device screenshots
- [x] AI-powered description generation
- [x] AI-powered auto-tagging
- [x] Background batch processing for existing screenshots
- [x] Immediate processing for new screenshots
- [x] Chat interface to search screenshots via natural language
- [x] Chat memory persists across sessions
- [x] Category-based browsing
- [x] On-device storage (SQLite)

---

## API Key Management
- Gemini API key embedded in the app
- Basic obfuscation applied (sufficient for a side project)
- Note: key can technically be extracted from APK - acceptable for now

---

## Flutter Packages

| Package | Purpose |
|---------|---------|
| `photo_manager` | Access device photos/screenshots |
| `sqflite` | Local SQLite database |
| `path_provider` | App document/cache directories |
| `dio` or `http` | Gemini API requests |
| `flutter_riverpod` | State management |
| `go_router` | Navigation |
| `uuid` | Generate unique IDs |
| `workmanager` | Background indexing jobs |
| `cached_network_image` or Flutter image APIs | Thumbnail/image rendering |

---

## Future Considerations (Post v1)
- iOS support
- Cloud sync for metadata
- OCR / extracted text search
- Embedding-based semantic search
- On-device AI model (offline mode)
- UI polish and theming
- Favorites / bookmarks
