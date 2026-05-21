# Yaaro0 Mobile Feature Plan

This file tracks what is already available in the API and web app, what the current Flutter mobile app already does, and what still needs to be added so mobile has the same core functions and features as `frontend/public-site`.

## Source Applications

- API application: `/Users/jathusan/Desktop/Yaaro-backend`
- Web UI application: `/Users/jathusan/Desktop/Yaaro0/frontend/public-site`
- Mobile application: `/Users/jathusan/Desktop/Yaaro0/mobile`

## Current Backend Features Done

### Authentication and Account

- Done: email/password registration at `POST /api/auth/register`.
- Done: required registration attributes:
  - `firstName`
  - `lastName`
  - `email`
  - `password`
  - `dateOfBirth`
  - `gender`
- Done: registration validation:
  - valid email format
  - strong password with 8+ characters, uppercase letter, number, and special character
  - user must be at least 18 years old
  - gender must be `male`, `female`, `non_binary`, or `other`
- Done: email account verification at `GET /api/auth/verify-email/:token`.
- Done: login at `POST /api/auth/login`.
- Done: login blocks unverified email accounts.
- Done: access token and refresh token session support.
- Done: refresh session at `POST /api/auth/refresh`.
- Done: logout at `POST /api/auth/logout`.
- Done: forgot password at `POST /api/auth/forgot-password`.
- Done: reset password at:
  - `POST /api/auth/reset-password`
  - `POST /api/auth/reset-password/:token`
- Done: OAuth backend endpoint at `POST /api/auth/oauth/:provider` for `google` and `facebook`.
- Partial: OTP endpoints exist, but currently return ready messages only:
  - `POST /api/auth/otp/send`
  - `POST /api/auth/otp/verify`

### Discovery and Matching

- Done: discover profile cards at `GET /api/discover`.
- Done: swipe at `POST /api/swipe`.
- Done: undo swipe at `POST /api/swipe/undo`.
- Done: matches list at `GET /api/matches`.
- Done: remove match at `DELETE /api/matches/:matchId`.
- Done: view another user profile at `GET /api/users/:userId/profile`.
- Done: likes received at `GET /api/likes/received`.

### Explore

- Done: categories at `GET /api/explore/categories`.
- Done: profiles by interest at `GET /api/explore/by-interest/:hobby`.
- Done: profiles by goal at `GET /api/explore/by-goal/:goal`.
- Done: nearby profiles at `GET /api/explore/nearby`.
- Done: daily vibe prompt at `GET /api/explore/vibes/today`.
- Done: vibe response at `POST /api/explore/vibes/respond`.

### Messages

- Done: conversation messages at `GET /api/messages/:matchId`.
- Done: send text/photo/image/GIF message at `POST /api/messages/:matchId`.
- Done: send voice note at `POST /api/messages/:matchId/voice`.
- Done: delete message at `DELETE /api/messages/:messageId`.
- Done: react to message at `POST /api/messages/:messageId/react`.
- Done: mark message read at `POST /api/messages/:messageId/read`.
- Done: report message at `POST /api/messages/:messageId/report`.
- Done: socket support for live chat, presence, read receipts, sending messages, and reactions.

### Profile and Onboarding

- Done: current profile at `GET /api/profile/me`.
- Done: profile completeness at `GET /api/profile/completeness`.
- Done: profile analytics at `GET /api/profile/analytics`.
- Done: update Spotify anthem at `PUT /api/profile/anthem`.
- Done: update profile at `PUT /api/profile/me`.
- Done: profile photos:
  - `GET /api/profile/photos`
  - `POST /api/profile/photos`
  - `DELETE /api/profile/photos/:id`
  - `PUT /api/profile/photos/reorder`
- Done: preferences at `PUT /api/profile/preferences`.
- Done: location at `PUT /api/profile/location`.
- Done: onboarding complete at `PATCH /api/profile/onboarding/complete`.

### Safety and Verification

- Done: create report at `POST /api/reports`.
- Done: block user at `POST /api/users/block/:userId`.
- Done: blocked users list at `GET /api/users/blocked`.
- Done: unblock user at `DELETE /api/users/block/:userId`.
- Done: unmatch at `POST /api/users/unmatch/:matchId`.
- Done: verification status at `GET /api/verification/status`.
- Done: photo verification at `POST /api/verification/photo`.
- Done: ID verification at `POST /api/verification/id`.

### Notifications and Premium

- Done: notifications list and read states.
- Done: push subscription endpoints.
- Done: notification settings.
- Done: subscription, checkout, cancel, boost, passport, incognito, super-like, and top-picks endpoints.

## Current Web UI Features Done

- Done: login form with email, password, remember me, forgot password link, and social login buttons.
- Done: register form with first name, last name, email, date of birth, gender, password, and confirm password.
- Done: email verification page using token route.
- Done: forgot password and reset password pages.
- Done: auth provider with access token, refresh, logout, persisted user, and authenticated fetch.
- Done: onboarding wizard with photos, about, physical attributes, background, lifestyle, favourites, preferences, and location.
- Done: discovery, swipe, undo, explore, matches, likes, profile, and protected app routes.
- Done: messages UI with text, photo, GIF, voice notes, reactions, read receipts, delete, report, offline cache, and live socket updates.
- Done: PWA manifest and service worker support.

## Current Mobile Features Done

- Done: Flutter app scaffold in `mobile/lib/main.dart`.
- Done: API base URL uses `YAARO0_API_URL`, defaulting to `http://127.0.0.1:8000`.
- Done: landing screen with login, create account, social-style buttons, and preview mode.
- Done: login API call to `POST /api/auth/login`.
- Partial: signup API call exists for `POST /api/auth/register`.
- Done: discovery screen with profile card stack, drag gestures, pass, like, superlike, and undo.
- Done: explore screen with categories, nearby profiles, goals, interests, and vibe prompt.
- Done: matches screen with matches and likes received.
- Done: profile preview screen.
- Done: local demo fallback data when the API is unavailable.

## Mobile Gaps To Do For Feature Parity

### Priority 1: Auth Parity

- To do: update mobile signup form to include the same required attributes as web/backend:
  - `firstName`
  - `lastName`
  - `email`
  - `dateOfBirth`
  - `gender`
  - `password`
  - `confirmPassword`
- To do: add password validation message before submit:
  - 8+ characters
  - uppercase letter
  - number
  - special character
- To do: show "check your email to verify your account" after successful registration.
- To do: add verify-email mobile deep link flow for `/verify-email/:token`.
- To do: add forgot password screen.
- To do: add reset password screen and deep link support for `/reset-password/:token`.
- To do: store access token, refresh token, and user securely using secure storage.
- To do: add token refresh handling before protected API calls.
- To do: add logout API call and clear secure storage.
- To do: add Google, Facebook, and TikTok native login or deep-link web login.
- To do: decide whether mobile uses backend OAuth endpoint directly or a hosted web callback flow.

### Priority 2: Onboarding and Profile

- To do: build mobile onboarding wizard matching web steps:
  - photos
  - about you
  - physical
  - background
  - lifestyle
  - favourites
  - preferences
  - location
- To do: integrate `GET /api/profile/me`.
- To do: integrate `PUT /api/profile/me`.
- To do: integrate `GET /api/profile/completeness`.
- To do: integrate profile photo upload, delete, and reorder.
- To do: integrate location permission and `PUT /api/profile/location`.
- To do: integrate preferences update.
- To do: call onboarding complete endpoint after required fields are saved.

### Priority 3: Messaging

- To do: create mobile chat screen for a selected match.
- To do: load messages with pagination from `GET /api/messages/:matchId`.
- To do: send text messages with `POST /api/messages/:matchId`.
- To do: add socket live chat with auth token.
- To do: join/leave match rooms.
- To do: receive new messages in real time.
- To do: mark messages as read.
- To do: show read receipts.
- To do: show online/offline presence.
- To do: send image/photo messages.
- To do: send GIF messages.
- To do: record and upload voice notes.
- To do: react to messages.
- To do: delete messages.
- To do: report messages.
- To do: cache recent messages for offline viewing.

### Priority 4: Discovery, Explore, and Matches Polish

- To do: require login before protected swipes and match actions.
- To do: show empty, loading, error, and retry states for every API request.
- To do: add match detail/profile screen.
- To do: add unmatch and block actions from match/profile views.
- To do: add likes received premium/permission states if required by backend rules.
- To do: add top picks, boost, passport, incognito, and super-like premium entry points.

### Priority 5: Safety, Verification, Notifications

- To do: add verification status screen.
- To do: add photo verification upload.
- To do: add ID verification upload if mobile product requires it.
- To do: add report user flow.
- To do: add block/unblock list.
- To do: add notification settings screen.
- To do: add mobile push notification registration.
- To do: handle notification tap into messages, matches, verification, and profile screens.

## Important Mobile Fixes Needed

- Fix: mobile signup currently sends only `firstName`, `lastName`, `email`, and `password`; backend requires `dateOfBirth` and `gender`, so mobile registration will fail until those fields are added.
- Fix: mobile login stores only the access token in memory; users will be logged out when the app restarts.
- Fix: mobile does not currently use refresh tokens, so sessions can expire without recovery.
- Fix: mobile matches screen lists matches but does not yet open a real chat conversation.
- Fix: mobile social buttons currently open the auth sheet instead of performing real Google/TikTok/Facebook login.
- Fix: mobile profile screen is a preview, not the full editable profile/onboarding experience.

## Suggested Build Order

1. Finish mobile auth parity:
   registration attributes, verification messaging, secure token storage, refresh, logout, forgot/reset password.
2. Add protected routing behavior:
   if logged out, show auth; if logged in but onboarding incomplete, show onboarding; otherwise show app tabs.
3. Build mobile onboarding/profile edit using the existing web field model.
4. Build full mobile messaging:
   REST history first, then socket live updates, then media/voice/reactions/reporting.
5. Add safety and verification screens.
6. Add notifications and premium features.
7. Run end-to-end checks against the backend for register, verify, login, profile, discover, match, message, and logout.

## Mobile API Checklist

### Auth

- `POST /api/auth/register`
- `GET /api/auth/verify-email/:token`
- `POST /api/auth/login`
- `POST /api/auth/logout`
- `POST /api/auth/refresh`
- `POST /api/auth/forgot-password`
- `POST /api/auth/reset-password`
- `POST /api/auth/reset-password/:token`
- `POST /api/auth/oauth/:provider`

### App

- `GET /api/discover`
- `POST /api/swipe`
- `POST /api/swipe/undo`
- `GET /api/explore/categories`
- `GET /api/explore/by-interest/:hobby`
- `GET /api/explore/by-goal/:goal`
- `GET /api/explore/nearby`
- `GET /api/explore/vibes/today`
- `POST /api/explore/vibes/respond`
- `GET /api/matches`
- `DELETE /api/matches/:matchId`
- `GET /api/likes/received`
- `GET /api/users/:userId/profile`

### Messages

- `GET /api/messages/:matchId`
- `POST /api/messages/:matchId`
- `POST /api/messages/:matchId/voice`
- `DELETE /api/messages/:messageId`
- `POST /api/messages/:messageId/react`
- `POST /api/messages/:messageId/read`
- `POST /api/messages/:messageId/report`

### Profile, Safety, Notifications, Premium

- `GET /api/profile/me`
- `PUT /api/profile/me`
- `GET /api/profile/completeness`
- `GET /api/profile/photos`
- `POST /api/profile/photos`
- `DELETE /api/profile/photos/:id`
- `PUT /api/profile/photos/reorder`
- `PUT /api/profile/preferences`
- `PUT /api/profile/location`
- `PATCH /api/profile/onboarding/complete`
- `GET /api/verification/status`
- `POST /api/verification/photo`
- `POST /api/verification/id`
- `POST /api/reports`
- `POST /api/users/block/:userId`
- `GET /api/users/blocked`
- `DELETE /api/users/block/:userId`
- `POST /api/users/unmatch/:matchId`
- `GET /api/notifications`
- `PATCH /api/notifications/read`
- `PATCH /api/notifications/:id/read`
- `POST /api/push/subscribe`
- `DELETE /api/push/subscribe`
- `GET /api/settings/notifications`
- `PATCH /api/settings/notifications`

