# YaaRo0 Voice & Video Call System — Documentation

## Overview

The call system uses **ZEGOCLOUD** (`zego_uikit_prebuilt_call` Flutter package) for the actual audio/video streaming, combined with **Socket.IO** for real-time call signaling and **Firebase Cloud Messaging (FCM)** for push notifications when the app is in the background.

---

## Architecture

```
┌──────────────┐       Socket.IO        ┌──────────────────┐       Socket.IO       ┌──────────────┐
│   Caller     │ ────call_invite────→    │   Backend        │ ────incoming_call───→  │   Callee     │
│   (User A)   │                         │   (Node.js)      │                        │   (User B)   │
│              │                         │                  │ ────FCM Push──────→    │              │
│  Opens Zego  │                         │                  │                        │ Shows Incoming│
│  Call Room   │                         │                  │                        │ Call Screen   │
│              │ ←──call_accepted────    │                  │ ←──call_accept────     │              │
│              │                         │                  │                        │ Opens Zego    │
│              │                         │                  │                        │ Call Room     │
└──────────────┘                         └──────────────────┘                        └──────────────┘
       │                                                                                     │
       └─────────────────── Same ZEGOCLOUD Room (callId) ───────────────────────────────────┘
```

## Credentials Required

### ZEGOCLOUD (Video/Audio)
- **ZEGO_APP_ID**: Your ZEGOCLOUD App ID (number)
- **ZEGO_APP_SIGN**: Your ZEGOCLOUD App Sign (hex string)
- Location: `mobile/.env`
- Get from: [ZEGOCLOUD Console](https://console.zegocloud.com/)

Current values in `.env`:
```
ZEGO_APP_ID=451719323
ZEGO_APP_SIGN=72d393c55831252f43353f764f7cadbc3f6db3a85bb8102a217c52dfd79bfb62
```

### Firebase (Push Notifications)
- **google-services.json**: Android FCM config → `mobile/android/app/google-services.json`
- **GoogleService-Info.plist**: iOS FCM config → `mobile/ios/Runner/GoogleService-Info.plist`
- Firebase project must have Cloud Messaging enabled
- Get from: [Firebase Console](https://console.firebase.google.com/)

### Backend (Socket.IO + FCM)
- **Socket URL**: Same as the API backend URL (Railway deployment)
- The backend uses `web-push` for push notifications (VAPID keys needed in backend `.env`)

Backend `.env` keys needed for push:
```
VAPID_PUBLIC_KEY=<your-vapid-public-key>
VAPID_PRIVATE_KEY=<your-vapid-private-key>
VAPID_SUBJECT=mailto:your@email.com
```

---

## How It Works

### Caller Side (User A starts a call)
1. User taps the phone/video icon in the chat screen
2. `startZegoCall()` is called → emits `call_invite` via the global socket
3. Immediately navigates to `ZegoCallScreen` (joins the Zego room)
4. Waits for User B to join the same room

### Callee Side (User B receives a call)
1. **If app is foreground**: Socket event `incoming_call` arrives → `CallService` shows `IncomingCallScreen`
2. **If app is background**: FCM push notification arrives with high priority → notification displayed
3. User B taps Accept → emits `call_accept` via socket → navigates to `ZegoCallScreen` (same room)
4. User B taps Decline → emits `call_reject` via socket → screen closes

### The Call Room
- Both users join the same ZEGOCLOUD room identified by `callId = "yaaro_call_{matchId}"`
- ZEGOCLOUD handles all WebRTC, TURN/STUN servers, and media streaming
- Video/audio is managed entirely by `ZegoUIKitPrebuiltCall` widget

---

## Files Modified/Created

### Backend
| File | Change |
|------|--------|
| `src/socket.ts` | Added `call_invite`, `call_accept`, `call_reject`, `call_end` socket events with push notification support |

### Mobile (Flutter)
| File | Change |
|------|--------|
| `lib/core/services/call_service.dart` | **NEW** — Global singleton that listens for incoming calls on the socket and shows the UI |
| `lib/features/chat/presentation/incoming_call_screen.dart` | **NEW** — Full-screen incoming call UI with accept/reject buttons |
| `lib/features/chat/presentation/zego_call_screen.dart` | Updated `startZegoCall()` to emit `call_invite` via socket |
| `lib/core/services/push_notification_service.dart` | Added dedicated "calls" notification channel with high priority + full-screen intent |
| `lib/main.dart` | Added global socket connection in `AppShell`, navigator key for call UI overlay |

---

## Socket Events

| Event | Direction | Description |
|-------|-----------|-------------|
| `call_invite` | Client → Server | Caller initiates a call. Server forwards to callee + sends FCM push |
| `incoming_call` | Server → Client | Callee receives call invitation in real-time |
| `call_accept` | Client → Server | Callee accepted the call |
| `call_accepted` | Server → Client | Caller notified that callee accepted |
| `call_reject` | Client → Server | Callee declined the call |
| `call_rejected` | Server → Client | Caller notified that callee declined |
| `call_end` | Client → Server | Either user ended the call |
| `call_ended` | Server → Client | Other user notified that call ended |

---

## Debugging Tips

1. **"Other user doesn't get notification"**
   - Check that the global socket is connected (look for socket connect logs)
   - Verify both users are authenticated (socket requires valid JWT token)
   - Check FCM token is registered (backend `users` table should have `fcmToken`)

2. **"Video doesn't show"**
   - Both users MUST join the same `callId` room in Zego
   - Check ZEGO_APP_ID and ZEGO_APP_SIGN are correct in `.env`
   - Ensure camera permissions are granted on both devices
   - The callee must ACCEPT the call (not just see the notification)

3. **"Call works on refresh but not real-time"**
   - The global socket must be connected — check `_AppShellState._connectGlobalSocket()`
   - Ensure the socket URL matches the backend URL

4. **Testing on two devices**
   - Log in with two different accounts on two physical devices/emulators
   - Both must have network connectivity to the backend
   - Both must have the same ZEGO_APP_ID (they share the same Zego project)

---

## Android Permissions (AndroidManifest.xml)

Ensure these permissions are declared:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
```

## iOS Permissions (Info.plist)

```xml
<key>NSCameraUsageDescription</key>
<string>YaaRo0 needs camera access for video calls</string>
<key>NSMicrophoneUsageDescription</key>
<string>YaaRo0 needs microphone access for calls</string>
```

---

## Future Improvements

- Add CallKit (iOS) / ConnectionService (Android) integration for native call UI when app is killed
- Add `zego_uikit_prebuilt_call` invitation plugin for more robust offline call handling
- Add call history/logs stored in the database
- Add missed call notifications
