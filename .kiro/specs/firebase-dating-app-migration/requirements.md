# Requirements Document

## Introduction

This document specifies the requirements for migrating the Yaaro0 dating app from a Flutter + Express.js architecture to a fully Firebase-based stack. The migration removes the Express.js backend entirely, replacing it with Firebase Auth, Cloud Firestore, Firebase Storage, Cloud Functions, and Firebase Cloud Messaging. The Flutter frontend adopts Riverpod for state management, Google Maps for location features, ZegoCloud for video/audio calling, and Geoflutterfire2 for geolocation queries.

## Glossary

- **App**: The Yaaro0 Flutter mobile application
- **Auth_Service**: The Firebase Authentication service handling user identity
- **Firestore**: Cloud Firestore NoSQL database storing all application data
- **Storage_Service**: Firebase Storage service for file uploads
- **FCM_Service**: Firebase Cloud Messaging service for push notifications
- **Cloud_Function**: Firebase Cloud Functions executing server-side logic
- **Riverpod_Provider**: A Riverpod state provider managing application state
- **Swipe_Engine**: The component responsible for swipe card deck UI and like/dislike logic
- **Match_Service**: The component responsible for detecting and creating mutual matches
- **Chat_Service**: The component managing real-time messaging between matched users
- **Calling_Service**: The ZegoCloud integration component for video and audio calls
- **Geo_Service**: The Geoflutterfire2 component handling geolocation queries
- **Map_View**: The Google Maps Flutter component displaying nearby users
- **Notification_Handler**: The component managing foreground, background, and terminated notification states
- **Profile_Setup_Flow**: The multi-step form guiding new users through profile creation
- **User_Document**: The Firestore document at users/{uid} containing a user's profile data
- **Match_Document**: The Firestore document at matches/{matchId} containing match metadata

## Requirements

### Requirement 1: Firebase Project Initialization

**User Story:** As a developer, I want the app to initialize Firebase services on startup, so that all Firebase-dependent features are available throughout the app lifecycle.

#### Acceptance Criteria

1. WHEN the App launches, THE App SHALL initialize Firebase Core, Firebase Auth, Cloud Firestore, Firebase Storage, and FCM_Service before rendering any UI, completing initialization within 10 seconds
2. IF Firebase initialization fails for any service, THEN THE App SHALL display an error screen indicating which service failed and providing a retry option, allowing a maximum of 3 retry attempts before displaying a persistent error state
3. THE App SHALL configure Firestore to use offline persistence with the default cache size for cached data access
4. IF any individual Firebase service fails to initialize while others succeed, THEN THE App SHALL treat the entire initialization as failed and not render the main UI

---

### Requirement 2: Phone OTP Authentication

**User Story:** As a user, I want to log in using my phone number and OTP, so that I can access the app without needing an email or password.

#### Acceptance Criteria

1. WHEN a user submits a phone number in E.164 format (starting with '+' followed by 7 to 15 digits), THE Auth_Service SHALL send a 6-digit one-time password via SMS to that phone number
2. IF a user submits a phone number that does not conform to E.164 format, THEN THE App SHALL display a validation error and SHALL NOT send an OTP request
3. WHEN a user submits a correct OTP within 60 seconds of issuance, THE Auth_Service SHALL authenticate the user and return a Firebase user credential
4. IF a user submits an incorrect OTP, THEN THE Auth_Service SHALL reject the authentication attempt, display an error message indicating the code is invalid, and allow the user to retry up to 3 additional attempts before locking the verification session
5. IF the OTP expires after 60 seconds, THEN THE Auth_Service SHALL invalidate the OTP and allow the user to request a new OTP, up to a maximum of 3 OTP requests per phone number within a 10-minute window
6. IF SMS delivery fails or the OTP request cannot be completed, THEN THE App SHALL display an error message indicating the SMS could not be sent and allow the user to retry
7. WHEN a phone-authenticated user has no existing User_Document, THE App SHALL create a new User_Document in Firestore with the phone number and uid

---

### Requirement 3: Google Sign-In Authentication

**User Story:** As a user, I want to sign in using my Google account, so that I can quickly access the app without creating a new password.

#### Acceptance Criteria

1. WHEN a user selects Google Sign-In, THE Auth_Service SHALL initiate the Google OAuth flow and return a Firebase user credential within 30 seconds of user completing Google's consent screen
2. IF the Google Sign-In flow is cancelled by the user, THEN THE Auth_Service SHALL return to the login screen without displaying an error message and without modifying authentication state
3. WHEN a Google-authenticated user has no existing User_Document, THE App SHALL create a new User_Document in Firestore with the email, display name, and uid
4. IF the Google Sign-In flow fails due to network unavailability or a Google service error, THEN THE Auth_Service SHALL display an error message indicating the sign-in could not be completed and allow the user to retry
5. IF a Google Sign-In is attempted with an email address already associated with a different authentication method, THEN THE Auth_Service SHALL display an error message indicating the account conflict and suggest the user sign in with the original method

---

### Requirement 4: Email and Password Authentication

**User Story:** As a user, I want to register and log in using email and password, so that I have a traditional login option.

#### Acceptance Criteria

1. WHEN a user submits a valid email and password for registration, THE Auth_Service SHALL create a new Firebase Auth account and return a Firebase user credential
2. IF a user attempts to register with an email that is already associated with an existing account, THEN THE Auth_Service SHALL reject the registration and display an error message indicating the email is already in use
3. WHEN a user submits correct email and password credentials, THE Auth_Service SHALL authenticate the user and return a Firebase user credential
4. IF a user submits incorrect email or password credentials during login, THEN THE Auth_Service SHALL reject the authentication attempt and display an error message indicating invalid credentials
5. IF a user submits an email that does not conform to a standard email format or a password shorter than 8 characters or longer than 128 characters, THEN THE Auth_Service SHALL reject the submission and display a validation error indicating the specific failing field
6. WHEN a user requests a password reset for a registered email address, THE Auth_Service SHALL send a password reset email to the specified address within 60 seconds
7. IF a user requests a password reset for an email address that is not registered, THEN THE Auth_Service SHALL display a generic confirmation message without revealing whether the email exists
8. WHEN an email-authenticated user has no existing User_Document, THE App SHALL create a new User_Document in Firestore with the email and uid

---

### Requirement 5: Persistent Authentication Session

**User Story:** As a user, I want to stay logged in across app restarts, so that I do not need to re-enter my credentials each time.

#### Acceptance Criteria

1. THE Riverpod_Provider SHALL expose an authentication state stream using Firebase authStateChanges() and resolve the initial authentication state within 5 seconds of app launch
2. WHILE the user is authenticated and has a complete profile (all required fields from Profile_Setup_Flow are present: name, age, gender, photos with at least one entry, interests, and location), THE App SHALL navigate to the HomeScreen
3. WHILE the user is authenticated and does not have a complete profile, THE App SHALL navigate to the Profile_Setup_Flow
4. WHILE the user is not authenticated, THE App SHALL navigate to the LoginScreen
5. WHEN the user signs out, THE Auth_Service SHALL clear the session and THE App SHALL navigate to the LoginScreen
6. WHILE the authentication state is being resolved on app launch, THE App SHALL display a loading indicator

---

### Requirement 6: User Profile Setup

**User Story:** As a new user, I want to complete my profile through a guided multi-step form, so that I can present myself to potential matches.

#### Acceptance Criteria

1. THE Profile_Setup_Flow SHALL present a stepper with five steps: Name and Age and Gender, Photos, Bio, Interests, and Location Permission
2. WHEN a user completes all five steps, THE App SHALL save the complete User_Document to Firestore with fields: uid, name, age, bio, gender, interestedIn, photos, interests, location, geohash, createdAt
3. IF a user exits the Profile_Setup_Flow before completion, THEN THE App SHALL persist completed step data locally and resume from the last incomplete step on next launch
4. THE Profile_Setup_Flow SHALL validate that age is between 18 and 99 inclusive, name is between 1 and 50 characters, and bio is between 0 and 500 characters
5. THE Profile_Setup_Flow SHALL require a minimum of one photo and a maximum of 6 photos before allowing completion of the Photos step
6. THE Profile_Setup_Flow SHALL present a grid of 20 or more preset interest chips and require the user to select between 3 and 10 interests before allowing completion of the Interests step
7. IF a user denies location permission on the Location Permission step, THEN THE Profile_Setup_Flow SHALL display a message explaining that location is required for discovery and SHALL prevent progression until permission is granted
8. IF a user submits a step with invalid or missing required fields, THEN THE Profile_Setup_Flow SHALL display a validation error indicating the specific field that needs correction and SHALL prevent progression to the next step
9. THE Profile_Setup_Flow SHALL prevent navigation to the next step until all required fields in the current step pass validation

---

### Requirement 7: Photo Upload

**User Story:** As a user, I want to upload photos to my profile, so that other users can see what I look like.

#### Acceptance Criteria

1. WHEN a user selects a photo from the device gallery or camera, THE App SHALL compress the image to a maximum resolution of 1080x1080 pixels and a maximum file size of 1 MB before upload
2. WHEN a compressed photo is ready, THE Storage_Service SHALL upload the file to the path users/{uid}/photos/{uuid}.jpg
3. WHEN the upload completes, THE App SHALL retrieve the download URL and append it to the photos array in the User_Document
4. IF a photo upload fails, THEN THE App SHALL display an error message indicating the upload did not succeed and present a retry option without discarding the selected image
5. IF a user attempts to upload a photo when 6 photos already exist in their profile, THEN THE App SHALL prevent the upload and display a message indicating the maximum photo limit has been reached
6. THE App SHALL accept images in JPEG, PNG, or HEIC format, and reject any file that exceeds 10 MB before compression with an error message indicating the file is too large
7. WHILE a photo upload is in progress, THE App SHALL display a progress indicator for that photo

---

### Requirement 8: Swipe Card Deck

**User Story:** As a user, I want to browse potential matches by swiping through a card deck, so that I can express interest or pass on profiles.

#### Acceptance Criteria

1. THE Swipe_Engine SHALL display up to 10 user profile cards in a stack using appinio_swiper, where each card displays the user's primary photo, name, age, and bio from their User_Document
2. WHEN a user swipes right on a profile card, THE Swipe_Engine SHALL create a like document at likes/{uid}/liked/{targetUid} in Firestore within 3 seconds
3. WHEN a user swipes left on a profile card, THE Swipe_Engine SHALL create a dislike document at likes/{uid}/disliked/{targetUid} in Firestore within 3 seconds
4. WHEN a user taps the super like button on a profile card, THE Swipe_Engine SHALL create a like document with a superLike field set to true at likes/{uid}/liked/{targetUid} in Firestore
5. WHEN a super like document is created, THE FCM_Service SHALL send a push notification to the target user within 10 seconds
6. THE Swipe_Engine SHALL query nearby users using Geo_Service filters, excluding those already present in the current user's liked and disliked collections
7. WHEN the card stack is empty, THE App SHALL fetch the next batch of up to 10 eligible profiles and display them in the stack
8. IF no eligible profiles are available when the card stack is empty, THEN THE App SHALL display an empty state message indicating no more profiles are available at this time
9. IF a like or dislike document write fails, THEN THE Swipe_Engine SHALL display an error indication to the user and keep the current card in the stack without advancing to the next card

---

### Requirement 9: Match Detection and Creation

**User Story:** As a user, I want to be matched with people who also liked me, so that I can start a conversation with mutual interests.

#### Acceptance Criteria

1. WHEN a user likes or super-likes another user, THE Cloud_Function SHALL check whether a reciprocal like or super-like document exists from the target user in likes/{targetUid}/liked/{currentUid}
2. WHEN a mutual like is detected, THE Cloud_Function SHALL create a Match_Document at matches/{matchId} where matchId is the two UIDs sorted alphabetically and joined with an underscore, and SHALL use the deterministic matchId to prevent duplicate Match_Documents from concurrent like operations
3. THE Match_Document SHALL contain fields: users (array of both UIDs), createdAt (server timestamp), lastMessage (initially null), lastMessageAt (initially null), and unreadCount (map of each uid to 0)
4. WHEN a match is created, THE Cloud_Function SHALL send a push notification to both users via FCM_Service indicating the match
5. IF a push notification cannot be delivered because the target user has no valid FCM token, THEN THE Cloud_Function SHALL skip notification delivery for that user without blocking match creation
6. WHEN a super like is received, THE Cloud_Function SHALL send a notification to the target user via FCM_Service within 30 seconds of the like document being written, regardless of match status

---

### Requirement 10: Nearby Users and Geolocation

**User Story:** As a user, I want to discover nearby users based on my location, so that I can find potential matches in my area.

#### Acceptance Criteria

1. WHEN the user grants location permission, THE Geo_Service SHALL store the current GeoPoint and computed geohash in the User_Document
2. WHEN the App is opened and location permission has been granted, THE Geo_Service SHALL update the stored GeoPoint and geohash in the User_Document with the device's current location
3. IF the user denies or revokes location permission, THEN THE Geo_Service SHALL not perform geo queries and THE App SHALL display a message indicating that location permission is required to discover nearby users
4. THE Geo_Service SHALL query users within the maximum distance radius stored in the current user's filter preferences (maxDistance field in the User_Document, measured in kilometers) using Geoflutterfire2 geo queries
5. THE Geo_Service SHALL exclude the current user's own profile and any users already present in the current user's liked or disliked collections from query results
6. THE Geo_Service SHALL filter query results by the current user's saved ageMin, ageMax, and interestedIn preferences
7. THE Geo_Service SHALL return a maximum of 50 user profiles per query batch

---

### Requirement 11: Map View with User Markers

**User Story:** As a user, I want to see nearby users on a map, so that I can visually understand who is around me.

#### Acceptance Criteria

1. THE Map_View SHALL display a Google Map centered on the current user's location at a default zoom level that fits the user's configured maximum distance radius
2. THE Map_View SHALL render custom circular photo markers (using the user's primary photo) for up to 50 nearby users returned by the Geo_Service
3. WHEN a user taps a marker on the Map_View, THE App SHALL display a profile preview card showing the user's name, age, primary photo, and distance from the current user
4. THE Map_View SHALL respect the same distance and preference filters (age range, maximum distance, and gender preference) applied in the discover feed
5. IF location permission is denied or the current user's location is unavailable, THEN THE Map_View SHALL display a message indicating that location access is required and provide a prompt to enable location permissions
6. IF the Geo_Service returns zero nearby users within the configured filters, THEN THE Map_View SHALL display an empty-state message indicating no users are nearby
7. WHEN the Map_View is opened or returned to, THE Map_View SHALL refresh the marker data from the Geo_Service

---

### Requirement 12: Discovery Filters

**User Story:** As a user, I want to filter potential matches by age, distance, and gender, so that I see only relevant profiles.

#### Acceptance Criteria

1. THE App SHALL provide an age range slider with minimum 18 and maximum 99, with default values of ageMin 18 and ageMax 99
2. THE App SHALL provide a maximum distance slider measured in kilometers with a minimum value of 1 and a maximum value of 100, with a default value of 50
3. THE App SHALL provide a gender preference toggle allowing selection of one or more genders from the set: Male, Female, Other
4. WHEN the user saves filter preferences, THE App SHALL store ageMin, ageMax, maxDistance, and interestedIn in the User_Document
5. IF the user attempts to save filter preferences with no gender selected in interestedIn, THEN THE App SHALL display a validation error and prevent saving
6. THE Swipe_Engine and Geo_Service SHALL apply saved filter preferences to all profile queries, returning only profiles where the target user's age is within the configured ageMin and ageMax range, the target user's distance is within maxDistance kilometers, and the target user's gender matches a value in the interestedIn list
7. IF no saved filter preferences exist in the User_Document, THEN THE Swipe_Engine and Geo_Service SHALL apply default values of ageMin 18, ageMax 99, maxDistance 50 kilometers, and interestedIn containing all genders

---

### Requirement 13: Real-Time Chat

**User Story:** As a matched user, I want to send and receive messages in real time, so that I can communicate with my matches.

#### Acceptance Criteria

1. THE Chat_Service SHALL store messages in the Firestore collection matches/{matchId}/messages/{messageId}
2. WHEN a user sends a text message of 1 to 5000 characters, THE Chat_Service SHALL create a message document with fields: senderId, text, type, timestamp
3. WHEN a user sends an image message of up to 10 MB in size, THE Chat_Service SHALL upload the image to Storage_Service and create a message document with the image URL and type set to image
4. THE Chat_Service SHALL display messages using a Firestore snapshot stream ordered by timestamp ascending, rendering new messages within 2 seconds of document creation
5. WHEN a message is sent, THE Chat_Service SHALL update the lastMessage and lastMessageAt fields on the Match_Document
6. WHEN a message is sent, IF the recipient does not have the conversation screen open for that match, THEN THE Cloud_Function SHALL send a push notification to the recipient
7. IF a user submits a message containing only whitespace or an empty string, THEN THE Chat_Service SHALL reject the message and not create a message document
8. IF a text message send or image upload fails, THEN THE Chat_Service SHALL display an error indicator on the failed message and provide a retry option without losing the message content

---

### Requirement 14: Video and Audio Calling

**User Story:** As a matched user, I want to make video and audio calls, so that I can have live conversations with my matches.

#### Acceptance Criteria

1. THE Calling_Service SHALL initialize ZegoCloud using the configured AppID and AppSign at application startup before any call can be initiated
2. WHEN a user initiates a video call, THE Calling_Service SHALL generate a callID composed of both participant UIDs sorted alphabetically and joined with an underscore, and start a one-on-one video call session using zego_uikit_prebuilt_call with the caller's UID and display name passed as user identification
3. WHEN a user initiates an audio call, THE Calling_Service SHALL generate a callID composed of both participant UIDs sorted alphabetically and joined with an underscore, and start a one-on-one audio-only call session with the caller's UID and display name passed as user identification
4. IF a user attempts to initiate a call with another user and no Match_Document exists between them, THEN THE Calling_Service SHALL reject the call attempt and display an error message indicating that calls are only available between matched users
5. IF a call fails to connect within 60 seconds or the ZegoCloud service is unreachable, THEN THE Calling_Service SHALL terminate the call attempt and display an error message indicating the call could not be completed

---

### Requirement 15: Push Notifications

**User Story:** As a user, I want to receive push notifications for matches, messages, and super likes, so that I stay informed about important activity.

#### Acceptance Criteria

1. WHEN the App launches and the user grants notification permission, THE Notification_Handler SHALL save the FCM token to the fcmToken field of the User_Document
2. IF the user denies notification permission, THEN THE Notification_Handler SHALL allow the App to continue without push notifications and SHALL NOT store an FCM token
3. WHEN the FCM token refreshes, THE Notification_Handler SHALL update the fcmToken field in the User_Document within 5 seconds of receiving the new token
4. WHILE the App is in the foreground, THE Notification_Handler SHALL display notifications using flutter_local_notifications with the notification title and body visible to the user
5. WHILE the App is in the background or terminated, THE Notification_Handler SHALL rely on FCM to display notifications in the system tray
6. WHEN a user taps a notification of type "match", THE App SHALL navigate to the match detail screen for that match; WHEN a user taps a notification of type "message", THE App SHALL navigate to the chat screen for that conversation; WHEN a user taps a notification of type "super_like", THE App SHALL navigate to the profile screen of the user who sent the super like
7. THE Notification_Handler SHALL support three notification types: "match" (triggered when a mutual match occurs), "message" (triggered when a new chat message is received), and "super_like" (triggered when a super like is received from another user), each containing a title, body, and a payload with the relevant document ID

---

### Requirement 16: Favorites

**User Story:** As a user, I want to save profiles to a favorites list, so that I can revisit them later.

#### Acceptance Criteria

1. WHEN a user saves a profile to favorites, THE App SHALL create a document in the Firestore collection users/{uid}/favorites/{targetUid} containing fields: targetUid, name, primaryPhotoUrl, age, and savedAt timestamp
2. WHEN a user removes a profile from favorites, THE App SHALL delete the corresponding document from the favorites collection
3. THE App SHALL display a list of all favorited profiles with name, primary photo, and age, ordered by savedAt timestamp descending, limited to a maximum of 100 favorited profiles per user
4. IF a favorite save or remove operation fails, THEN THE App SHALL display an error message and retain the previous favorites state
5. WHILE viewing a profile that is already in the user's favorites, THE App SHALL display the favorite action in its saved state to indicate the profile is already favorited

---

### Requirement 17: Riverpod State Management

**User Story:** As a developer, I want all state management handled by Riverpod, so that the codebase has a consistent and testable state architecture.

#### Acceptance Criteria

1. THE App SHALL wrap the root widget in a ProviderScope and use Riverpod providers for authentication state, user profile state, swipe state, match list state, chat state, and notification state
2. THE App SHALL replace all existing setState and imperative state management code with equivalent Riverpod providers, resulting in zero remaining setState calls outside of local UI animation state
3. THE Riverpod_Provider for authentication SHALL expose the current Firebase user object, a boolean loading flag, and an error state containing a human-readable error message, updating within 2 seconds of any authStateChanges() emission
4. THE Riverpod_Provider for matches SHALL expose a real-time stream of Match_Documents for the current user, ordered by lastMessageAt descending, and SHALL emit an empty list when no matches exist
5. IF a Riverpod_Provider encounters a Firestore connection error or timeout exceeding 10 seconds, THEN THE App SHALL expose an error state on that provider and display a user-visible error indication with a retry action
6. WHEN the user signs out, THE App SHALL reset all Riverpod providers to their initial unauthenticated state, clearing cached user profile, matches, chat, and swipe data from memory
7. THE Riverpod_Provider for user profile SHALL expose the current User_Document fields, a loading flag, and an error state, and SHALL stay synchronized with the Firestore users/{uid} document via a real-time snapshot listener

---

### Requirement 18: Express.js Backend Removal

**User Story:** As a developer, I want all Express.js backend code removed, so that the app relies entirely on Firebase services.

#### Acceptance Criteria

1. THE App SHALL not contain any Express.js dependency in its package.json, and SHALL not make HTTP requests to any non-Firebase backend endpoint for any feature
2. THE App SHALL use Firestore security rules to enforce data access control for user documents, match documents, like/dislike documents, and chat messages as defined in Requirement 19
3. THE App SHALL use Cloud_Functions for server-side logic that requires trusted execution, specifically: match detection, push notification dispatch, super like notification, and unread count updates
4. WHEN a like document is created in Firestore, THE Cloud_Function SHALL trigger via a Firestore onCreate event to perform match detection and, if a match is found, create the Match_Document and dispatch push notifications to both users
5. WHEN a super like document is created in Firestore, THE Cloud_Function SHALL trigger via a Firestore onCreate event and send an immediate push notification to the target user via FCM_Service regardless of match status

---

### Requirement 19: Firestore Security Rules

**User Story:** As a developer, I want Firestore security rules that protect user data, so that users can only access and modify data they are authorized to.

#### Acceptance Criteria

1. THE Firestore security rules SHALL allow authenticated users to read all fields of their own User_Document and to update their own User_Document, but SHALL NOT allow users to modify the uid or createdAt fields
2. THE Firestore security rules SHALL allow authenticated users to read only the following fields from other users' User_Documents: uid, name, age, bio, gender, photos, interests, and location — and SHALL deny access to fcmToken, email, phone number, and internal metadata fields
3. THE Firestore security rules SHALL allow only participants listed in the Match_Document users array to read messages in that match's messages subcollection, and SHALL allow participants to create new messages only where the senderId field matches the authenticated user's uid
4. THE Firestore security rules SHALL allow only authenticated users to create like and dislike documents under their own uid path (likes/{uid}/liked/{targetUid} and likes/{uid}/disliked/{targetUid}), and SHALL deny updates and deletes to those documents
5. THE Firestore security rules SHALL deny all client read and write operations on Match_Documents except that authenticated users listed in the Match_Document users array SHALL be allowed to read the Match_Document
6. IF an unauthenticated request attempts any read or write operation, THEN THE Firestore security rules SHALL deny the request

---

### Requirement 20: Offline Support and Data Caching

**User Story:** As a user, I want the app to work with limited connectivity, so that I can browse cached profiles and read previous messages offline.

#### Acceptance Criteria

1. WHILE the device has no network connection, THE App SHALL display cached Firestore data for profiles, matches, and messages that were loaded during a prior online session, and SHALL display an offline indicator visible on all screens
2. WHILE the device has no network connection, THE App SHALL disable actions that require server-side processing (initiating calls, uploading photos) and SHALL display a message indicating that the action requires a network connection
3. WHEN the device regains network connection, THE App SHALL synchronize all pending queued writes to Firestore within 30 seconds of connectivity restoration
4. IF a write operation fails due to network unavailability, THEN THE App SHALL queue the operation locally, persist the queue across app restarts, and retry each queued operation a maximum of 5 times upon reconnection
5. IF a queued write operation fails after 5 retry attempts, THEN THE App SHALL discard the operation and display an error message indicating that the action could not be completed
