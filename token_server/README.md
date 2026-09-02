# 100ms Minimal Token Server

This service provides an HTTP endpoint for minting 100ms JWT auth tokens for Guru (Member) and Trainer apps.

## Setup & Run

1. **Install dependencies:**
   ```bash
   cd token_server
   npm install
   ```

2. **Configure Environment:**
   ```bash
   copy .env.example .env
   ```
   Add your 100ms credentials (`HMS_APP_ACCESS_KEY` & `HMS_APP_SECRET`).

3. **Start the server:**
   ```bash
   npm start
   ```
   Server will start on `http://localhost:8080`.

## API Endpoints

### 1. Generate 100ms Auth Token
- **Endpoint**: `GET /token?userId={userId}&role={role}&roomId={roomId}`
- **Example**: `http://localhost:8080/token?userId=dk_member_1&role=member&roomId=room_wtf_01`
- **Response**:
  ```json
  {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "userId": "dk_member_1",
    "role": "member",
    "roomId": "room_wtf_01",
    "expiresIn": 86400
  }
  ```

### 2. Health Check
- **Endpoint**: `GET /health`
