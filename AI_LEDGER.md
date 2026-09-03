# AI Ledger (Mandatory AI-Native Assessment Evidence)

This document contains the complete ledger of AI prompts, tools, intents, generated snippets, debugging sessions, and refactoring adaptations used during the construction of the Guru and Trainer Flutter applications.

---

## 1. Structured AI Prompts & Generations

### Entry #1: 100ms Minimal Token Server Scaffold
- **Tool**: Gemini 3.7 Flash
- **Intent**: Create an Express token server endpoint `GET /token` that generates HMAC-SHA256 signed 100ms JWT auth tokens with role mapping and secret masking.
- **Output Snippet**:
  ```javascript
  const payload = {
    access_key: HMS_APP_ACCESS_KEY,
    room_id: roomId,
    user_id: userId,
    role: role.toLowerCase(),
    type: 'app',
    version: 2,
    iat: nowSec,
    exp: nowSec + 86400,
    jti: uuidv4()
  };
  const token = jwt.sign(payload, HMS_APP_SECRET, { algorithm: 'HS256' });
  ```
- **File Reference**: `token_server/server.js`

### Entry #2: Domain Models & JSON Serialization
- **Tool**: Gemini 3.7 Flash
- **Intent**: Generate immutable Dart data models for `User`, `Message`, `CallRequest`, `SessionLog`, and `RoomMeta` with copyWith and JSON serialization.
- **Output Snippet**:
  ```dart
  class Message {
    final String id;
    final String chatId;
    final String senderId;
    final String receiverId;
    final String text;
    final DateTime createdAt;
    final MessageStatus status;
  }
  ```
- **File Reference**: `shared/lib/models/`

### Entry #3: Design System Tokens & 8pt Spacing
- **Tool**: Gemini 3.7 Flash
- **Intent**: Implement strict 8pt spacing system, Netflix Red (`#E50914`), Electric Blue (`#1769E0`), and typography constants matching PDF requirements.
- **Output Snippet**:
  ```dart
  static const Color trainerPrimary = Color(0xFFE50914);
  static const Color guruPrimary = Color(0xFF1769E0);
  static const double xs = 4.0, sm = 8.0, md = 16.0, lg = 24.0, xl = 32.0;
  ```
- **File Reference**: `shared/lib/utils/app_colors.dart`, `app_spacing.dart`, `app_typography.dart`

### Entry #4: Cross-App Sync Engine (`SyncBridge`)
- **Tool**: Gemini 3.7 Flash
- **Intent**: Architect a local-first synchronization bridge using persistent JSON file I/O and reactive Dart stream controllers for instant dual-app updates.
- **Output Snippet**:
  ```dart
  _pollingTimer = Timer.periodic(const Duration(milliseconds: 250), (_) => _checkForExternalChanges());
  ```
- **File Reference**: `shared/lib/services/sync_bridge.dart`

### Entry #5: Chat System with Typing Simulation & Status Ticks
- **Tool**: Gemini 3.7 Flash
- **Intent**: Implement `ChatService` with simulated 400–800ms typing indicators, single/double tick read status tracking, and quick replies.
- **Output Snippet**:
  ```dart
  _sync.setTypingStatus(senderId, true);
  Timer(const Duration(milliseconds: 650), () => _sync.setTypingStatus(senderId, false));
  ```
- **File Reference**: `shared/lib/services/chat_service.dart`, `shared/lib/widgets/chat_bubble.dart`

### Entry #6: Call Scheduler & Conflict Detection Logic
- **Tool**: Gemini 3.7 Flash
- **Intent**: Implement 3-day calendar slot generator and conflict validation preventing overlapping approved 30-minute blocks.
- **Output Snippet**:
  ```dart
  final hasOverlap = targetTime.isBefore(reqEnd) && targetEnd.isAfter(reqStart);
  if (hasOverlap) return SchedulerValidationResult.invalid('Slot already approved for another session.');
  ```
- **File Reference**: `shared/lib/utils/validators.dart`, `shared/lib/widgets/time_slot_picker.dart`

### Entry #7: 100ms In-Call UI & Pre-Join Device Check
- **Tool**: Gemini 3.7 Flash
- **Intent**: Create Pre-Join Device Check modal (camera preview, mic/video toggles) and 2-participant grid in-call layout with auto-reconnect resilience.
- **Output Snippet**:
  ```dart
  class ActiveVideoCallScreen extends StatefulWidget { ... }
  ```
- **File Reference**: `shared/lib/widgets/video_call_view.dart`

### Entry #8: Post-Call Feedback & Completion Sheets
- **Tool**: Gemini 3.7 Flash
- **Intent**: Generate interactive 1-5 star rating sheet for Member and trainer notes input sheet for Trainer upon session termination.
- **Output Snippet**:
  ```dart
  class MemberPostCallSheet extends StatefulWidget { ... }
  class TrainerPostCallSheet extends StatefulWidget { ... }
  ```
- **File Reference**: `shared/lib/widgets/post_call_sheets.dart`

### Entry #9: Observability DevPanel with Tagged Log Stream
- **Tool**: Gemini 3.7 Flash
- **Intent**: Build floating `⋮` button and slide-over DevPanel displaying masked environment variables, build metadata, and last 20 structured logs tagged `[CHAT]`, `[RTC]`, `[SCHEDULE]`, `[AUTH]`.
- **Output Snippet**:
  ```dart
  class DevPanelModal extends StatefulWidget { ... }
  ```
- **File Reference**: `shared/lib/widgets/dev_panel.dart`

### Entry #10: Guru App (Member) Presentation & View Model
- **Tool**: Gemini 3.7 Flash
- **Intent**: Implement `GuruViewModel` and full screen flow: Onboarding (2 slides) -> DK Profile Setup -> Home (3 cards) -> Chat -> Schedule Call -> My Sessions.
- **Output Snippet**:
  ```dart
  class GuruViewModel extends ChangeNotifier { ... }
  ```
- **File Reference**: `guru_app/lib/`

### Entry #11: Trainer App Presentation & View Model
- **Tool**: Gemini 3.7 Flash
- **Intent**: Implement `TrainerViewModel` and screen flow: Seeded Login -> Home (4 tiles: Members, Chats, Requests, Sessions) -> Approve/Decline Requests -> In-Call Host Controls.
- **Output Snippet**:
  ```dart
  class TrainerViewModel extends ChangeNotifier { ... }
  ```
### Entry #12: Agora RTC SDK & In-Call Messaging Migration
- **Tool**: Gemini 3.7 Flash
- **Intent**: Replace legacy 100ms SDK with `agora_rtc_engine` across all layers (service, UI, models, token server), supporting video conference, in-call data streams, and token auth.
- **Output Snippet**:
  ```dart
  class AgoraSdkService {
    Future<void> joinChannel({required String channelName, required String token, required int uid, required String userName}) async { ... }
    Future<void> sendInCallMessage(String text) async { ... }
  }
  ```
- **File Reference**: `shared/lib/services/agora_sdk_service.dart`, `shared/lib/widgets/video_call_view.dart`, `token_server/server.js`

---

## 2. Debugging with AI Entries

### Debug Entry #1: Dart Analyzer Const Instantiation in Unit Tests
- **Error**:
  ```text
  test/shared_test.dart:121: Error: Not a constant expression: startedAt: null as dynamic ?? _dummyDate
  ```
- **Root Cause**: `DateTime` object initialized at runtime was assigned inside a `const SessionLog(...)` constructor call.
- **AI Fix**: Changed test instances to standard constructor invocations with explicit `DateTime(2026, 9, 2, 13, 0)`.

### Debug Entry #2: Named Parameter `isError` in Log Helpers
- **Error**:
  ```text
  lib/services/call_service.dart: Error: No named parameter with the name 'isError' in logSchedule.
  ```
- **Root Cause**: `logSchedule`, `logChat`, `logRtc`, and `logAuth` convenience methods in `LogService` lacked the optional `bool isError = false` parameter that `log()` accepted.
- **AI Fix**: Updated all four helper methods in `log_service.dart` to forward `{Map<String, dynamic>? meta, bool isError = false}` to the primary `log()` engine.

---

## 3. Refactor with AI Entries

### Refactor Entry #1: Unified Spacing and Component Gaps
- **Before**: Ad-hoc `SizedBox(width: 12)` and `SizedBox(height: 12)` used in multiple widget headers.
- **After**: Added standardized `AppSpacing.gapH12` and `AppSpacing.gapV12` tokens to `app_spacing.dart` preserving the 8pt baseline scale.

### Refactor Entry #2: Centralized UI Copy Strings
- **Before**: Hardcoded strings scattered across chat, scheduler, and dialog widgets.
- **After**: Consolidated all exact UI copy specified in Section 11 of the assessment into `AppStrings` (`emptyChat`, `requestSent`, `callApproved`, `callDeclined`, `joinPrompt`, `sessionEnded`).

### Refactor Entry #3: Complete 100ms to Agora RTC SDK Migration
- **Before**: `HMSSdkService`, `HMSVideoView`, `hmssdk_flutter` dependency, and 100ms JWT token server.
- **After**: `AgoraSdkService`, `AgoraVideoView`, `agora_rtc_engine: ^6.3.0`/`^6.5.x`, Agora RTC Data Streams for in-call messaging, and HMAC-SHA256 Agora RTC Access Token (v007) generator in `token_server/server.js`.

