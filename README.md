# WTF Flutter Assessment — Guru App & Trainer App (100ms + Chat)

A production-ready pair of coordinated Flutter applications (**Guru App** for Members and **Trainer App** for Trainers) built with local-first real-time synchronization, 100ms RTC video calling, intelligent call scheduling, interactive session logs, and an in-app DevPanel for observability.

---

## Quickstart: Build & Run

### 1. One-Command Setup & Test
Run the following commands to install dependencies and verify all unit tests across the monorepo:

```bash
# 1. Run Shared Unit Tests
cd shared
flutter test

# 2. Run Guru App (Member) Tests
cd ../guru_app
flutter test

# 3. Run Trainer App Tests
cd ../trainer_app
flutter test
```

### 2. Start 100ms Token Server
```bash
cd token_server
npm install
npm start
```
*The token server will listen on `http://localhost:8080` and serve `GET /token?userId=&role=&roomId=`.*

### 3. Launch the Flutter Applications

#### Launch Guru App (Member — DK Persona):
```bash
cd guru_app
flutter run -d chrome # or -d android / -d windows
```

#### Launch Trainer App (Trainer — Aarav Persona):
```bash
cd trainer_app
flutter run -d chrome # or -d android / -d windows
```

---

## 9-Step Reviewer Manual Test Script

Follow these 9 steps to test the full end-to-end integration:

| Step | Action | Expected Result |
|---|---|---|
| **1** | Launch **Trainer App** | Seeded login prefilled as **Aarav (Lead Trainer)**. Tap *Access Trainer Dashboard* to land on 4-tile Home screen. |
| **2** | Launch **Guru App** | Complete 2-step onboarding. Screen prefilled with **DK** persona and auto-assigned to **Aarav**. Lands on 3-card Home screen. |
| **3** | DK sends `"Hi Coach 👍"` | Trainer App displays unread badge on Chat tile. Trainer opens chat, sees Blue bubble on left, replies with `"See you on call at 6!"`. Single/double ticks update and typing indicator animates. |
| **4** | DK schedules a call | In Guru App, tap *Schedule Call*, pick today 6:00 PM, enter note: `"Macros review"`, tap *Request Call*. Toast confirms: `"Call requested. Waiting for trainer approval."` |
| **5** | Trainer approves request | In Trainer App, open *Requests* tab. See DK's note `"Macros review"`. Tap **Approve**. Guru App receives chat system message: `"Call approved for 6:00 PM"` and an **Upcoming Video Session** banner appears on Home. |
| **6** | Join Video Call | Tap **Join Call Now** on either app. Pre-join Device Check modal opens with camera/mic preview and role mapping (`trainer` / `member`). Tap *Join Video Call Now*. |
| **7** | Active 100ms In-Call UI | 2-participant video grid loads with name labels and live duration timer. Test Mute/Unmute, Video On/Off, Flip Camera, and tap glitch icon to verify auto-reconnect resilience. |
| **8** | End Call & Feedback | Tap **End Call / Leave Call**. Call ends and auto-writes `SessionLog`. Member rates **5★** with note; Trainer enters session notes and taps **Mark as Complete**. |
| **9** | Open Sessions List | Open *My Sessions* in Guru App and *Sessions* in Trainer App. Latest completed session appears at the top showing calculated duration (e.g. `12m 45s`), 5★ rating, and detailed coach/member notes. |

---

## Architecture & Code Highlights

- **Shared Core Module (`shared/`)**: Single source of truth containing immutable models (`User`, `Message`, `CallRequest`, `SessionLog`, `RoomMeta`), 8pt design tokens, validators, and formatters.
- **Local-First Sync Engine (`SyncBridge`)**: Real-time cross-process sync loop ensuring instantaneous updates (< 250ms) between apps without requiring remote cloud servers.
- **Observability DevPanel (`⋮`)**: Tap the floating button in either app to inspect masked environment variables, runtime metadata, and the last 20 structured logs tagged `[CHAT]`, `[RTC]`, `[SCHEDULE]`, `[AUTH]`.
- **100ms RTC Video Integration**: Strict role separation (`trainer` as host vs `member` as participant), pre-join device check, grid video layout, and connection recovery.

---

## Assessment Deliverables Checklist

- [x] **Monorepo Structure**: `token_server/`, `shared/`, `guru_app/`, `trainer_app/`
- [x] **ADR Document**: `DECISIONS.md` (ADR #1 State Mgmt, ADR #2 Storage & Sync, ADR #3 RTC Strategy)
- [x] **System Architecture**: `ARCHITECTURE.md` (Diagrams, data flow, 100ms lifecycle)
- [x] **AI Ledger**: `AI_LEDGER.md` (≥10 structured entries + debugging & refactoring records)
- [x] **Quality Gates**: All automated unit tests passing in `shared/`, `guru_app/`, `trainer_app/` with 0 warnings.
- [x] **UI & Design**: 8pt spacing, Netflix Red (`#E50914`), Electric Blue (`#1769E0`), exact UI strings matching specification Section 11.
