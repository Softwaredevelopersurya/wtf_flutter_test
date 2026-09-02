# WTF Assessment: Guru App (Member) & Trainer App (Trainer)

Dual Flutter mobile apps designed for 1-on-1 video fitness coaching and real-time member–trainer communication, powered by **100ms** ([100ms live documentation](https://www.100ms.live/docs)).

---

## 1. Project Directory Layout

```text
wtf_flutter_test/
+-- token_server/          # Node.js 100ms Token Server (Express :8080)
¦   +-- server.js          # GET /token?userId=&role=&roomId=
¦   +-- .env               # HMS_APP_ACCESS_KEY & HMS_APP_SECRET
¦   +-- package.json
+-- guru_app/              # Self-contained Member Flutter Mobile App
¦   +-- lib/
¦   ¦   +-- main.dart
¦   ¦   +-- presentation/  # Onboarding, Home, Chat, Scheduler, Sessions
¦   ¦   +-- providers/     # GuruViewModel
¦   ¦   +-- shared/        # Models, Services, Widgets, 100ms RTC Service, Utils
¦   +-- test/              # 11 Unit tests (Domain, View Model, Scheduler constraints)
+-- trainer_app/           # Self-contained Trainer Flutter Mobile App
¦   +-- lib/
¦   ¦   +-- main.dart
¦   ¦   +-- presentation/  # Login, Home, Members, Chat, Requests, Sessions
¦   ¦   +-- providers/     # TrainerViewModel
¦   ¦   +-- shared/        # Models, Services, Widgets, 100ms RTC Service, Utils
¦   +-- test/              # 11 Unit tests (Domain, View Model, Call Approvals)
+-- AI_LEDGER.md           # Mandatory AI-native prompt ledger (15 entries)
+-- ARCHITECTURE.md        # Architecture diagrams & 100ms RTC lifecycle
+-- DECISIONS.md           # ADR #1 (State Mgmt), #2 (Storage/Sync), #3 (RTC Strategy)
+-- README.md
```

---

## 2. Quickstart Instructions

### Step 1: Start the 100ms Token Server
```bash
cd token_server
npm install
npm start
```

### Step 2: Run Guru App (Member)
```bash
cd guru_app
flutter pub get
flutter run -d android # or -d ios / -d chrome
```

### Step 3: Run Trainer App (Trainer)
```bash
cd trainer_app
flutter pub get
flutter run -d android # or -d ios / -d chrome
```

---

## 3. Automated Test Suites

Both applications are self-contained and run complete unit test suites:

```bash
# Run Guru App Tests (11 passed)
cd guru_app
flutter test

# Run Trainer App Tests (11 passed)
cd trainer_app
flutter test
```
