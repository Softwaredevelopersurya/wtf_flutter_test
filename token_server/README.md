# Agora RTC & Messaging Token Server

This service provides an HTTP endpoint for minting Agora RTC dynamic access tokens for Guru (Member) and Trainer apps.

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
   Add your Agora credentials (`AGORA_APP_ID` & `AGORA_APP_CERTIFICATE`).

3. **Start the server:**
   ```bash
   npm start
   ```
   Server will start on `http://localhost:8080`.

## API Endpoints

### 1. Generate Agora RTC Auth Token
- **Endpoint**: `GET /token?userId={userId}&role={role}&channelName={channelName}&uid={uid}`
- **Example**: `http://localhost:8080/token?userId=user_member_dk&role=broadcaster&channelName=channel_wtf_01`
- **Response**:
  ```json
  {
    "token": "007eJxTYIjbl1sul/OoJFKKo/GLnno010fdH4WqL19zv78lJfLzwgYFBtM0C4M0Y+O0FMMUcxNDI7NEw0QLQ4MkQ2MzEwNDQzMLReuZWQ2BjAyfHPazMDJAIIgvwFBekhafllNaUpJaFF+SWlzCwAAAoWYjlQ==",
    "appId": "5f80f33fd1d74126a1a810b136401168",
    "userId": "user_member_dk",
    "uid": 0,
    "role": "broadcaster",
    "channelName": "wtf_flutter_test",
    "expiresIn": 86400
  }
  ```

### 2. Health Check
- **Endpoint**: `GET /health`
