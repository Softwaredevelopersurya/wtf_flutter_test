# WTF Flutter Assessment: Guru App (Member) & Trainer App (Trainer)

Dual Flutter applications designed for 1-on-1 video fitness coaching and real-time member–trainer communication, powered by **100ms** ([100ms documentation](https://www.100ms.live/docs)).

---

## 1. Monorepo Project Structure

```text
wtf_flutter_test/
+-- token_server/          # Node.js 100ms Auth Token Server (Express :8080)
¦   +-- server.js          # GET /token?userId=&role=&roomId=
¦   +-- .env               # HMS_APP_ACCESS_KEY & HMS_APP_SECRET
¦   +-- package.json
+-- shared/                # Core domain layer, models, services, widgets, & design system
¦   +-- lib/
¦   ¦   +-- models/        # User, Message, CallRequest, SessionLog, RoomMeta
¦   ¦   +-- services/      # AuthService, ChatService, CallService, LogService, SyncBridge, HMSSdkService
¦   ¦   +-- widgets/       # DevPanel, VideoCallView, ChatBubble, TimeSlotPicker, PostCallSheets
¦   ¦   +-- utils/         # 8pt Spacing tokens, Colors, Typography, AppStrings, Validators, AppConfig
¦   +-- test/              # Unit tests (Serialization, Scheduler validation, Duration calculation)
+-- guru_app/              # Member Flutter Application (DK Persona, Electric Blue #1769E0)
¦   +-- lib/
¦   ¦   +-- presentation/  # Onboarding, Home, Chat, Scheduler, Sessions
¦   ¦   +-- providers/     # GuruViewModel
¦   +-- test/              # Member View Model Unit Tests
+-- trainer_app/           # Trainer Flutter Application (Aarav Persona, Netflix Red #E50914)
¦   +-- lib/
¦   ¦   +-- presentation/  # Login, Home, Members, Chat, Requests, Sessions
¦   ¦   +-- providers/     # TrainerViewModel
¦   +-- test/              # Trainer View Model Unit Tests
+-- AI_LEDGER.md           # Mandatory AI-native prompt ledger
+-- ARCHITECTURE.md        # System architecture and 100ms data flows
+-- DECISIONS.md           # Architecture Decision Records (ADRs)
+-- README.md
```

---

## 2. Quickstart Instructions

### Step 1: Start 100ms Token Server
```bash
cd token_server
npm install
npm start
```

### Step 2: Run Member App (Guru App)
```bash
cd guru_app
flutter run -d android # or -d ios / -d chrome
```

### Step 3: Run Trainer App (Trainer App)
```bash
cd trainer_app
flutter run -d android # or -d ios / -d chrome
```

---

## 3. Automated Test Suites

```bash
# Run Shared Core Domain & Validation Tests (8 passed)
cd shared
flutter test

# Run Member App Tests (3 passed)
cd ../guru_app
flutter test

# Run Trainer App Tests (3 passed)
cd ../trainer_app
flutter test
```
