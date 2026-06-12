# Implementation Plan: Firebase Dating App Migration

## Overview

This plan migrates the Yaaro0 dating app from Flutter + Express.js to a fully Firebase-based stack. Tasks are organized by migration phase: Firebase initialization, authentication, profile/storage, swipe/match/discovery, chat, notifications/calling/favorites, state management, security rules, Cloud Functions, and Express.js removal. Each task produces working, integrated code building on prior tasks.

## Tasks

- [x] 1. Firebase initialization and core infrastructure
  - [x] 1.1 Add Firebase dependencies and initialize Firebase services
    - Add `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging` to `pubspec.yaml`
    - Add `flutter_riverpod` and `riverpod_annotation` for state management
    - Create `lib/core/firebase_init.dart` implementing `FirebaseInitService` with retry logic (max 3 attempts)
    - Configure Firestore offline persistence with default cache size
    - Wrap root widget in `ProviderScope` and call `initialize()` before `runApp`
    - Display error screen if initialization fails after retries
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 17.1_

  - [x] 1.2 Create core service interfaces and data models
    - Create `lib/core/models/user_profile.dart` with `UserProfile` class matching the Firestore User_Document schema
    - Create `lib/core/models/match_document.dart` with `MatchDocument` class
    - Create `lib/core/models/chat_message.dart` with `ChatMessage` class
    - Create `lib/core/models/like_document.dart` with `LikeDocument` class
    - Create `lib/core/models/favorite_document.dart` with `FavoriteDocument` class
    - Create `lib/core/models/discovery_filters.dart` with `DiscoveryFilters` class
    - Include `toFirestore()` and `fromFirestore()` methods on each model
    - _Requirements: 6.2, 9.3, 13.2, 16.1_

  - [x]* 1.3 Write property test for deterministic paired-user ID generation
    - **Property 5: Deterministic Paired-User ID Generation**
    - **Validates: Requirements 9.2, 14.2, 14.3**
    - Test that for any two UIDs A and B, the ID function produces the same result regardless of argument order
    - Verify result equals sorted UIDs joined with underscore

- [x] 2. Authentication services
  - [x] 2.1 Implement Phone OTP authentication service
    - Create `lib/features/auth/data/firebase_auth_service.dart` implementing `FirebaseAuthService`
    - Implement `sendOtp()` with E.164 phone number validation ('+' followed by 7-15 digits)
    - Implement `verifyOtp()` with verification ID and 6-digit OTP
    - Handle retry limits (3 attempts per session) and OTP expiry (60 seconds)
    - Handle SMS delivery failure with error messaging
    - Create User_Document in Firestore for new phone-authenticated users
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_

  - [x]* 2.2 Write property test for E.164 phone number validation
    - **Property 1: E.164 Phone Number Validation**
    - **Validates: Requirements 2.2**
    - Test that validation accepts strings starting with '+' followed by 7-15 digits and rejects all others

  - [x] 2.3 Implement Google Sign-In authentication
    - Add `google_sign_in` dependency to `pubspec.yaml`
    - Implement `signInWithGoogle()` in the auth service
    - Handle cancelled flow (return to login without error)
    - Handle network errors and account conflicts
    - Create User_Document for new Google-authenticated users
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

  - [x] 2.4 Implement Email/Password authentication
    - Implement `registerWithEmail()` and `signInWithEmail()` in the auth service
    - Implement `sendPasswordResetEmail()` with generic confirmation for non-existent emails
    - Add email format validation and password length validation (8-128 chars)
    - Handle duplicate email registration errors
    - Create User_Document for new email-authenticated users
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8_

  - [x]* 2.5 Write property test for email and password validation
    - **Property 2: Email and Password Input Validation**
    - **Validates: Requirements 4.5**
    - Test that invalid email format or password outside 8-128 chars is rejected with specific field error

  - [x] 2.6 Implement auth state Riverpod provider and session routing
    - Create `lib/features/auth/providers/auth_providers.dart`
    - Implement `authStateProvider` as a `StreamProvider<User?>` using `authStateChanges()`
    - Implement routing logic: authenticated + complete profile → HomeScreen, authenticated + incomplete → Profile_Setup_Flow, unauthenticated → LoginScreen
    - Implement sign-out logic that clears session
    - Display loading indicator while auth state resolves
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [x] 3. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Profile setup and photo upload
  - [x] 4.1 Implement profile setup multi-step flow
    - Create `lib/features/profile/presentation/profile_setup_screen.dart` with a 5-step stepper
    - Step 1: Name (1-50 chars), Age (18-99), Gender selection
    - Step 2: Photos (min 1, max 6)
    - Step 3: Bio (0-500 chars)
    - Step 4: Interests (3-10 selections from 20+ preset chips)
    - Step 5: Location permission request
    - Validate each step before allowing progression
    - Persist completed step data locally for resume on re-launch
    - Save complete User_Document to Firestore on final step completion
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.9_

  - [x]* 4.2 Write property test for profile field validation
    - **Property 3: Profile Field Validation**
    - **Validates: Requirements 6.4**
    - Test that age 18-99, name 1-50 chars, bio 0-500 chars accepted; others rejected with specific field error

  - [x] 4.3 Implement photo storage service
    - Create `lib/features/profile/data/storage_service.dart` implementing `PhotoStorageService`
    - Add `image_picker` and `flutter_image_compress` dependencies
    - Implement `uploadPhoto()` with compression to 1080x1080 max, 1MB max
    - Upload to `users/{uid}/photos/{uuid}.jpg` path
    - Expose upload progress stream
    - Implement `deletePhoto()` by storage path
    - Enforce max 6 photos limit
    - Display retry option on upload failure without losing selected image
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7_

  - [x]* 4.4 Write property test for photo upload file validation
    - **Property 4: Photo Upload File Validation**
    - **Validates: Requirements 7.6**
    - Test that only JPEG/PNG/HEIC under 10MB accepted; other formats or sizes rejected

  - [x] 4.5 Implement profile Riverpod provider
    - Create `lib/features/profile/providers/profile_providers.dart`
    - Implement `userProfileProvider` as `StreamProvider.family` watching `users/{uid}` document
    - Implement `isProfileComplete()` check for required fields
    - Expose loading, data, and error states
    - _Requirements: 17.7_

- [x] 5. Swipe, match, and discovery
  - [x] 5.1 Implement geo service with Geoflutterfire2
    - Add `geoflutterfire2` and `geolocator` dependencies
    - Create `lib/features/discover/data/geo_service.dart` implementing `GeoService`
    - Implement `updateLocation()` to store GeoPoint and computed geohash in User_Document
    - Implement `queryNearbyUsers()` with radius, filters, and exclusion logic
    - Handle location permission denied state
    - Update location on app open
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7_

  - [x] 5.2 Implement swipe service
    - Create `lib/features/swipe/data/swipe_service.dart` implementing `SwipeService`
    - Implement `like()` writing to `likes/{uid}/liked/{targetUid}`
    - Implement `dislike()` writing to `likes/{uid}/disliked/{targetUid}`
    - Implement super like with `superLike: true` field
    - Implement `fetchEligibleProfiles()` using GeoService with filter application and exclusion of already-liked/disliked users
    - Handle write failures by keeping card in stack
    - _Requirements: 8.2, 8.3, 8.4, 8.6, 8.9_

  - [ ]* 5.3 Write property test for discovery query exclusion
    - **Property 6: Discovery Query Exclusion**
    - **Validates: Requirements 8.6, 10.5**
    - Test that results never contain the current user or any user in liked/disliked collections

  - [ ]* 5.4 Write property test for discovery filter application
    - **Property 7: Discovery Filter Application**
    - **Validates: Requirements 10.4, 10.6, 12.6**
    - Test that all returned profiles satisfy age range, distance, and gender filter criteria

  - [x] 5.5 Implement swipe card deck UI
    - Add `appinio_swiper` dependency
    - Create `lib/features/swipe/presentation/swipe_screen.dart` with card stack (up to 10 cards)
    - Display primary photo, name, age, bio on each card
    - Wire swipe-right to `like()`, swipe-left to `dislike()`, super-like button to `like(superLike: true)`
    - Fetch next batch when stack is empty
    - Display empty state when no eligible profiles available
    - _Requirements: 8.1, 8.5, 8.7, 8.8_

  - [x] 5.6 Implement match service and match list provider
    - Create `lib/features/matches/data/match_service.dart` implementing `MatchService`
    - Implement `watchMatches()` as a real-time stream ordered by `lastMessageAt` descending
    - Implement `getMatch()` for single match retrieval
    - Create `lib/features/matches/providers/match_providers.dart` with `matchesProvider`
    - Expose empty list when no matches exist
    - _Requirements: 9.3, 17.4_

  - [x] 5.7 Implement discovery filters UI and persistence
    - Create `lib/features/discover/presentation/filter_screen.dart`
    - Implement age range slider (18-99, defaults 18-99)
    - Implement max distance slider (1-100km, default 50)
    - Implement gender preference toggles (Male, Female, Other; at least one required)
    - Save filters to User_Document on confirm
    - Apply default values when no saved filters exist
    - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 12.6, 12.7_

  - [x] 5.8 Implement map view with user markers
    - Add `google_maps_flutter` dependency
    - Create `lib/features/discover/presentation/map_screen.dart`
    - Center map on current user's location at appropriate zoom for maxDistance
    - Render circular photo markers for nearby users (max 50)
    - Show profile preview on marker tap (name, age, photo, distance)
    - Respect same filters as discover feed
    - Handle location permission denied state
    - Refresh markers on map open/return
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.7_

- [x] 6. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. Real-time chat
  - [x] 7.1 Implement chat service
    - Create `lib/features/chat/data/chat_service.dart` implementing `ChatService`
    - Implement `watchMessages()` with real-time Firestore snapshot stream ordered by timestamp ascending
    - Implement `sendTextMessage()` creating message document with senderId, text, type, timestamp
    - Implement `sendImageMessage()` uploading to Storage then creating message document with imageUrl
    - Update `lastMessage` and `lastMessageAt` on Match_Document on each send
    - Validate messages (reject empty/whitespace-only, enforce 1-5000 char limit)
    - Handle send failures with retry option
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.7, 13.8_

  - [ ]* 7.2 Write property test for chat message validation
    - **Property 8: Chat Message Validation**
    - **Validates: Requirements 13.2, 13.7**
    - Test that empty/whitespace-only strings rejected, strings with 1+ non-whitespace chars and length 1-5000 accepted

  - [x] 7.3 Implement chat UI screen
    - Create `lib/features/chat/presentation/chat_screen.dart`
    - Display messages in timestamp order using `chatMessagesProvider`
    - Implement text input with send button
    - Implement image attachment flow
    - Show error indicator on failed messages with retry
    - Wire to `ChatService` methods
    - _Requirements: 13.2, 13.3, 13.4, 13.8_

  - [x] 7.4 Implement chat Riverpod providers
    - Create `lib/features/chat/providers/chat_providers.dart`
    - Implement `chatMessagesProvider` as `StreamProvider.family<List<ChatMessage>, String>` by matchId
    - Expose loading, data, and error states with retry
    - _Requirements: 17.5_

- [x] 8. Notifications, calling, and favorites
  - [x] 8.1 Implement notification service and FCM integration
    - Add `firebase_messaging` and `flutter_local_notifications` dependencies
    - Create `lib/features/notifications/data/notification_service.dart` implementing `NotificationService`
    - Implement `initialize()` to request permission, get token, save to User_Document
    - Handle token refresh and update in User_Document
    - Display foreground notifications using flutter_local_notifications
    - Implement notification tap routing: match → match detail, message → chat, super_like → profile
    - Allow app to continue without notifications if permission denied
    - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5, 15.6, 15.7_

  - [ ]* 8.2 Write property test for notification type routing
    - **Property 9: Notification Type Routing**
    - **Validates: Requirements 15.6**
    - Test that each notification type (match, message, super_like) navigates to correct screen

  - [x] 8.3 Implement calling service with ZegoCloud
    - Add `zego_uikit_prebuilt_call` dependency
    - Create `lib/features/calling/data/calling_service.dart` implementing `CallingService`
    - Implement `initialize()` with AppID and AppSign
    - Implement `startVideoCall()` and `startAudioCall()` using sorted UID callID
    - Reject call if no Match_Document exists between users
    - Handle 60-second connection timeout
    - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5_

  - [x] 8.4 Implement favorites service and UI
    - Create `lib/features/favorites/data/favorites_service.dart`
    - Implement save to `users/{uid}/favorites/{targetUid}` with targetUid, name, primaryPhotoUrl, age, savedAt
    - Implement remove from favorites
    - Create `lib/features/favorites/presentation/favorites_screen.dart`
    - Display favorited profiles ordered by savedAt descending (max 100)
    - Show saved state on profile view when already favorited
    - Handle save/remove failures with error display
    - _Requirements: 16.1, 16.2, 16.3, 16.4, 16.5_

- [x] 9. Riverpod state management completion and provider reset
  - [x] 9.1 Complete Riverpod provider migration and sign-out reset
    - Audit all remaining `setState` calls and replace with Riverpod providers
    - Ensure zero remaining `setState` calls outside local UI animation state
    - Implement sign-out logic that resets all providers: auth, profile, matches, chat, swipe, notifications
    - Verify all providers expose loading, data, and error states
    - Implement 10-second timeout error state on Firestore providers
    - _Requirements: 17.1, 17.2, 17.3, 17.5, 17.6_

  - [ ]* 9.2 Write property test for provider state reset on sign out
    - **Property 10: Provider State Reset on Sign Out**
    - **Validates: Requirements 17.6**
    - Test that all providers reset to initial unauthenticated state after sign out

- [x] 10. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 11. Firestore security rules, Cloud Functions, and offline support
  - [x] 11.1 Write and deploy Firestore security rules
    - Create `firestore.rules` file at project root
    - Implement user document rules: authenticated read, owner write, immutable uid/createdAt
    - Implement like/dislike rules: owner create only, no update/delete
    - Implement match rules: participant read only, no client write
    - Implement message rules: participant read, participant create with senderId == auth.uid
    - Implement favorites rules: owner read/write
    - Deny all unauthenticated requests
    - _Requirements: 19.1, 19.2, 19.3, 19.4, 19.5, 19.6_

  - [ ]* 11.2 Write property test for security rule — immutable system fields
    - **Property 11: Security Rule — Immutable System Fields**
    - **Validates: Requirements 19.1**
    - Test that updates modifying uid or createdAt are denied even by document owner

  - [ ]* 11.3 Write property test for security rule — message sender identity
    - **Property 12: Security Rule — Message Sender Identity**
    - **Validates: Requirements 19.3**
    - Test that message creation with senderId != auth.uid is denied

  - [ ]* 11.4 Write property test for security rule — unauthenticated access denial
    - **Property 13: Security Rule — Unauthenticated Access Denial**
    - **Validates: Requirements 19.6**
    - Test that any request without valid auth token is denied

  - [x] 11.5 Implement Cloud Functions for match detection and notifications
    - Create `functions/` directory with TypeScript Cloud Functions project
    - Implement `onLikeCreated` trigger: check reciprocal like, create Match_Document with deterministic ID, send FCM to both users
    - Implement `onSuperLikeCreated` trigger: send FCM notification to target user within 30s
    - Implement `onNewMessage` trigger: send FCM to recipient if not in chat, update lastMessage/lastMessageAt on Match_Document
    - Handle missing FCM token gracefully (skip notification, don't block match creation)
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 18.3, 18.4, 18.5_

  - [x] 11.6 Implement offline support and data caching
    - Add connectivity check and offline indicator widget displayed on all screens
    - Disable server-required actions (calls, photo uploads) when offline with user messaging
    - Leverage Firestore offline persistence for cached reads of profiles, matches, messages
    - Implement write queue with local persistence across app restarts
    - Retry queued writes on reconnection (max 5 retries per operation)
    - Discard operation and show error after 5 failed retries
    - Sync pending writes within 30 seconds of reconnection
    - _Requirements: 20.1, 20.2, 20.3, 20.4, 20.5_

- [x] 12. Express.js backend removal and final integration
  - [x] 12.1 Remove Express.js dependencies and API client code
    - Delete `lib/core/api_client.dart` and all HTTP-based service calls
    - Remove `socket_io_client` dependency and all socket-based real-time code
    - Remove `secure_storage` auth token management (Firebase handles session internally)
    - Remove any remaining references to the Express.js backend URLs
    - Verify no non-Firebase HTTP requests remain in the codebase
    - _Requirements: 18.1_

  - [x] 12.2 Wire all screens to Firebase services and verify end-to-end flows
    - Connect login screen to Firebase Auth service (phone, Google, email)
    - Connect profile setup to ProfileService and StorageService
    - Connect home screen to swipe, matches, favorites providers
    - Connect chat screen to ChatService and chat providers
    - Connect calling buttons to CallingService with match validation
    - Connect notification taps to correct screen navigation
    - Verify all navigation flows work with Riverpod state
    - _Requirements: 18.1, 18.2, 18.3_

- [x] 13. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties from the design document
- Unit tests validate specific examples and edge cases
- Cloud Functions are written in TypeScript (matching the design document)
- The Flutter app uses Dart throughout
- Firestore security rules testing requires the Firebase Emulator Suite

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2"] },
    { "id": 2, "tasks": ["1.3", "2.1"] },
    { "id": 3, "tasks": ["2.2", "2.3", "2.4"] },
    { "id": 4, "tasks": ["2.5", "2.6"] },
    { "id": 5, "tasks": ["4.1", "4.3"] },
    { "id": 6, "tasks": ["4.2", "4.4", "4.5"] },
    { "id": 7, "tasks": ["5.1", "5.6"] },
    { "id": 8, "tasks": ["5.2", "5.7"] },
    { "id": 9, "tasks": ["5.3", "5.4", "5.5", "5.8"] },
    { "id": 10, "tasks": ["7.1"] },
    { "id": 11, "tasks": ["7.2", "7.3", "7.4"] },
    { "id": 12, "tasks": ["8.1", "8.3", "8.4"] },
    { "id": 13, "tasks": ["8.2", "9.1"] },
    { "id": 14, "tasks": ["9.2", "11.1", "11.5"] },
    { "id": 15, "tasks": ["11.2", "11.3", "11.4", "11.6"] },
    { "id": 16, "tasks": ["12.1"] },
    { "id": 17, "tasks": ["12.2"] }
  ]
}
```
