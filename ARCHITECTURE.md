# System Architecture & Technical Specifications

## 1. High-Level Architecture Overview

```
                      +-----------------------------+
                      |     100ms Video Engine      |
                      |  (RTC Rooms & Media Tracks) |
                      +--------------+--------------+
                                     ^
                                     | 100ms JWT Auth Token
                      +--------------+--------------+
                      |     100ms Token Server      |
                      |   (Node.js Express :8080)   |
                      +--------------+--------------+
                                     ^
                                     | HTTP GET /token
             +-----------------------+-----------------------+
             |                                               |
+------------+------------+                     +------------+------------+
|        Guru App         |                     |       Trainer App       |
|    (Member - DK)        |                     | (Trainer - Aarav)       |
|  Theme: Blue (#1769E0)  |                     |  Theme: Red (#E50914)   |
+------------+------------+                     +------------+------------+
             |                                               |
             +-----------------------+-----------------------+
                                     |
                                     v
                      +-----------------------------+
                      |    Shared Package (shared)  |
                      |  - Domain Models            |
                      |  - AuthService, ChatService |
                      |  - CallService, LogService  |
                      |  - SyncBridge (Local IPC)   |
                      |  - UI Design System & Dev   |
                      +-----------------------------+
                                     |
                                     v
                      +-----------------------------+
                      |   Local Storage Engine      |
                      |   (wtf_local_state.json)    |
                      +-----------------------------+
```

---

## 2. Monorepo Structure

```text
wtf_flutter_test/
├── README.md               # Quickstart, 1-command build, manual test script
├── AI_LEDGER.md            # Mandatory AI-native evidence ledger (≥10 entries)
├── ARCHITECTURE.md         # Detailed architectural documentation
├── DECISIONS.md            # ADRs (#1 State Mgmt, #2 Storage, #3 RTC Strategy)
├── .env.example            # Environment variables template
├── token_server/           # Minimal 100ms Token Server
│   ├── package.json
│   ├── server.js           # GET /token?userId=&role=&roomId=
│   └── README.md
├── shared/                 # Core domain, services, UI components & utilities
│   ├── lib/
│   │   ├── models/         # User, Message, CallRequest, SessionLog, RoomMeta
│   │   ├── services/       # AuthService, ChatService, CallService, LogService, SyncBridge
│   │   ├── widgets/        # DevPanel, VideoCallView, ChatBubble, TimeSlotPicker, PostCallSheets
│   │   └── utils/          # AppColors, AppSpacing (8pt), AppTypography, AppStrings, Validators
│   └── test/               # Unit tests (Serialization, Scheduler validation, Duration calculation)
├── guru_app/               # Member Flutter Application
│   ├── lib/
│   │   ├── main.dart
│   │   ├── providers/      # GuruViewModel
│   │   └── presentation/   # OnboardingScreen, GuruHomeScreen, GuruChatScreen, ScheduleCallScreen, GuruSessionsScreen
│   └── test/
└── trainer_app/            # Trainer Flutter Application
    ├── lib/
    │   ├── main.dart
    │   ├── providers/      # TrainerViewModel
    │   └── presentation/   # TrainerLoginScreen, TrainerHomeScreen, TrainerMembersScreen, TrainerChatScreen, TrainerRequestsScreen, TrainerSessionsScreen
    └── test/
```

---

## 3. Real-Time Data Flow & Inter-App Sync Engine

When an action occurs in either app:
1. **Mutation**: A ViewModel invokes a Service method (e.g., `chatService.sendMessage(...)` or `callService.requestCall(...)`).
2. **Local Persistence**: `SyncBridge` atomically updates its in-memory state and persists the payload to `wtf_local_state.json`.
3. **Reactive Broadcast**: A Dart `StreamController.broadcast()` emits the new state to all local UI subscribers.
4. **Peer Synchronization**: The other running Flutter app's `SyncBridge` polling loop detects file timestamp changes within **≤ 250ms**, loads the delta, and updates its active ViewModels reactively.

---

## 4. 100ms Video Call Lifecycle State Machine

```
 [Member: Schedule Call]
          │
          ▼
 [Status: Pending Approval]
          │
          ├──────────────────────────┐
          ▼ (Trainer Approves)       ▼ (Trainer Declines)
 [Status: Approved]             [Status: Declined]
 [RoomMeta Created]             [Reason Modal Displayed]
 [Chat System Message]          [Chat Status Updated]
          │
          ▼
 [Pre-Join Device Check]
 (Camera & Mic Preview)
          │
          ▼
 [Token Server Auth]
 (GET /token?userId=&role=&roomId=)
          │
          ▼
 [Active In-Call Video Conference]
 (2-Participant Grid, Mute/Video/Flip Controls, Reconnect Resilience)
          │
          ▼
 [Call Ended]
 (Auto-writes SessionLog with calculated duration)
          │
          ├──────────────────────────┐
          ▼                          ▼
 [Member Post-Call Sheet]    [Trainer Post-Call Sheet]
 (1–5 Star Rating + Note)    (Trainer Notes + Mark Complete)
          │                          │
          └───────────┬──────────────┘
                      ▼
            [Updated Session Logs]
```

---

## 5. Observability & Developer Experience (DX)

- **Floating DevPanel Button (`⋮`)**: Positioned unobtrusively on all screens for rapid inspection during testing and review.
- **Masked Secrets**: Live credentials and JWT tokens are masked in both terminal outputs and DevPanel (`dev_***_key`).
- **Structured Log Tags**:
  - `[AUTH]`: Session loading, onboarding state, user authentication.
  - `[CHAT]`: Message transmission, status tick transitions (`sent` -> `read`), simulated typing indicators.
  - `[SCHEDULE]`: Slot booking, validation checks, approve/decline actions.
  - `[RTC]`: Token acquisition, room join/leave events, device toggles, connection recovery.
- **Copy Error Action**: One-tap copy action on error states for effortless debugging.
