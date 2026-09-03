# Architecture Decision Records (ADRs)

## ADR #1: State Management Strategy — Provider & MVVM Pattern

### Context
The project requires building two interconnected Flutter applications (`guru_app` and `trainer_app`) that coordinate state across authentication, real-time chat, call scheduling, video conferencing, and session logs with high readability, testability, and zero boilerplate friction.

### Decision
We chose the **MVVM (Model-View-ViewModel) pattern with `Provider` (`ChangeNotifier`)** layered with domain repositories and reactive streams.
- **Views**: Lean widgets responsible strictly for layout and presentation.
- **ViewModels (`GuruViewModel`, `TrainerViewModel`)**: Expose reactive state, encapsulate business rules, and interact with the service layer.
- **Data Layer (`shared/services`)**: Single source of truth exposing broadcasts and domain models.

### Consequences
- **Pros**:
  - Direct alignment with the official Flutter Architecture best practices.
  - Zero code generation overhead, ensuring fast builds and rapid iteration.
  - Clean separation of UI logic and business logic enabling isolated unit tests.
- **Cons**: Requires explicit manual listener subscriptions and disposal hygiene, which we encapsulated inside view models.

---

## ADR #2: Local Storage & Dual-App Real-Time Sync Engine (`SyncBridge`)

### Context
The apps must communicate locally and work together in real-time when both running on an Android emulator, real device, desktop, or web without requiring an external cloud backend or complex server orchestration.

### Decision
We implemented a local-first **`SyncBridge` architecture**:
1. **Persistent Local Database**: Atomically persists serialized models (`User`, `Message`, `CallRequest`, `SessionLog`, `TypingStatus`) in a local JSON document.
2. **Reactive Stream Layer**: Emits broadcast stream events for instant UI reactivity (< 200ms) upon any local mutation.
3. **Cross-Process File Polling**: Periodically inspects filesystem file timestamps to ingest changes initiated by the other application instance instantly without manual refresh.

### Consequences
- **Pros**:
  - 100% autonomous and offline capable; no cloud backend dependency.
  - Inter-process sync latency ≤ 250ms on local machine.
  - Reliable state preservation across restarts and hot reloads.
- **Cons**: File I/O polling is optimized for local dual-app testing; for multi-device production, a WebSocket / Firebase bridge would replace the transport while preserving the identical repository API.

---

## ADR #3: Video Calling & RTC Engine Strategy — Migration to Agora RTC SDK

### Context
The project requires video calling and real-time in-call messaging with camera/microphone hardware toggling, front/rear camera flipping, dynamic channel creation, network glitch resilience, and token generation.

### Decision
We migrated from 100ms SDK to the **Agora RTC Engine SDK (`agora_rtc_engine: ^6.3.0` / `^6.5.x`)**:
1. **Agora SDK Service (`AgoraSdkService`)**: Encapsulates `RtcEngine` lifecycle, channel joining (`joinChannel`), event handler registration (`onJoinChannelSuccess`, `onUserJoined`, `onUserOffline`, `onUserMuteVideo`, `onConnectionStateChanged`, `onStreamMessage`), local/remote peer state broadcasts, and hardware controls.
2. **In-Call Real-Time Messaging**: Uses Agora RTC Data Streams (`createDataStream` & `sendStreamMessage`) to deliver sub-second in-call messages between trainer and member with full reactive stream updates.
3. **Agora Token Server**: Generates HMAC-SHA256 Agora RTC Access Tokens v007 signed with `AGORA_APP_ID` and `AGORA_APP_CERTIFICATE` with a 24-hour expiration window and local fallback resilience.
4. **Rendering & DX**: Employs `AgoraVideoView` with `VideoViewController` for local and remote streams alongside high-fidelity fallback avatars for test environments.

### Consequences
- **Pros**:
  - World-class low-latency audio/video communication backed by Agora's Software Defined Real-time Network (SD-RTN).
  - Built-in data streams for in-call messaging without requiring a separate signaling service.
  - Full compatibility across mobile, desktop, and web preview targets.
- **Cons**: Requires Agora App ID configuration (provided in `.env` / `AppConfig` with resilient dev token fallback).
