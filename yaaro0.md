# 💘 Yaaro0 Web App — Sprint-by-Sprint Build Plan
> Full feature parity with Yaaro0 (web version) · Landing page already done · Tech stack already selected
> Each sprint = ~2 weeks · Each sprint section contains exact prompt instructions to use with your AI coding tool

---

## 📋 Project Context

- **Landing page:** ✅ Done
- **Tech stack:** Already selected (assumed React + Node/Express + PostgreSQL + Socket.IO)
- **Goal:** Build full Yaaro0 feature parity as a web app, sprint by sprint
- **Total sprints:** 12

---

## 🗺️ Sprint Overview

| Sprint | Focus | Key Deliverable |
|---|---|---|
| 1 | Auth & User System | Register, Login, JWT, Email verify |
| 2 | Onboarding Wizard | Profile setup, photos, interests |
| 3 | Discovery Engine | Swipe UI, like/pass logic, queue |
| 4 | Matching System | Mutual match detection, match list |
| 5 | Real-time Messaging | Socket.IO chat, GIFs, reactions |
| 6 | Explore & Interests | Interest-based discovery, categories |
| 7 | Premium System | Free/Plus/Gold/Platinum tiers, Boost, Super Like |
| 8 | Safety & Moderation | Report, block, photo verification |
| 9 | Notifications | Push, in-app, email notifications |
| 10 | Profile Enhancement | Spotify anthem, MBTI, Vibes, badges |
| 11 | Admin Portal | Dashboard, user mgmt, moderation |
| 12 | Polish & Performance | Animations, PWA, SEO, accessibility |

---

---

# SPRINT 1 — Authentication & User System

**Goal:** Users can register, verify email, log in, log out, and reset password. JWT auth is in place across the full stack.

---

## What to Build

### Backend
- `POST /api/auth/register` — create user, send verification email
- `GET  /api/auth/verify-email/:token` — activate account
- `POST /api/auth/login` — return access token + refresh token
- `POST /api/auth/logout` — invalidate refresh token
- `POST /api/auth/forgot-password` — send reset email
- `POST /api/auth/reset-password` — update password via token
- `POST /api/auth/refresh` — issue new access token
- `POST /api/auth/oauth/google` — Google OAuth login
- `POST /api/auth/oauth/facebook` — Facebook OAuth login

### Database Tables
```sql
users (
  id UUID PRIMARY KEY,
  email VARCHAR UNIQUE NOT NULL,
  password_hash VARCHAR,
  first_name VARCHAR NOT NULL,
  last_name VARCHAR NOT NULL,
  date_of_birth DATE NOT NULL,
  gender VARCHAR NOT NULL,
  email_verified BOOLEAN DEFAULT false,
  email_verify_token VARCHAR,
  reset_password_token VARCHAR,
  reset_token_expires TIMESTAMP,
  oauth_provider VARCHAR,  -- 'google' | 'facebook' | null
  oauth_id VARCHAR,
  status VARCHAR DEFAULT 'active',  -- active | suspended | banned | deleted
  onboarding_completed BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  last_active_at TIMESTAMP
)

refresh_tokens (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  token VARCHAR UNIQUE NOT NULL,
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
)
```

### Frontend Pages
- `/register` — Registration form
- `/login` — Login form
- `/verify-email/:token` — Verification handler page
- `/forgot-password` — Email input form
- `/reset-password/:token` — New password form
- Auth context/provider wrapping the entire app
- Protected route HOC (redirect to `/login` if not authed)

---

## Validation Rules

- Email: valid format, unique
- Password: min 8 chars, 1 uppercase, 1 number, 1 special character
- Date of birth: must be 18 years or older
- Gender: required field
- Email verify token: expires in 24 hours
- Reset password token: expires in 15 minutes

---

## 🤖 Prompt to Use

```
I am building a Yaaro0 web app (React frontend + Node.js/Express backend + PostgreSQL).
The landing page is already done.

Build Sprint 1: Authentication & User System.

BACKEND tasks:
1. Set up Express server with middleware (cors, helmet, express-json)
2. Connect to PostgreSQL using pg or Drizzle ORM
3. Create the `users` and `refresh_tokens` tables (migration file)
4. Implement these endpoints with full validation:
   - POST /api/auth/register (bcrypt password, send verification email via nodemailer)
   - GET  /api/auth/verify-email/:token
   - POST /api/auth/login (return JWT access token 15min + refresh token 30d stored in httpOnly cookie)
   - POST /api/auth/logout
   - POST /api/auth/refresh
   - POST /api/auth/forgot-password (send reset link, expires 15min)
   - POST /api/auth/reset-password/:token
5. Google OAuth via passport.js
6. Age check: reject if user is under 18

FRONTEND tasks:
1. Register page: fields for first name, last name, email, password, confirm password, date of birth, gender (select). Validate inline.
2. Login page: email + password + "remember me" + forgot password link
3. Email verification landing page (/verify-email/:token)
4. Forgot password page + reset password page
5. Auth context (React Context API) storing user state, access token, login/logout functions
6. Axios interceptor to auto-refresh token on 401
7. Protected route wrapper that redirects unauthenticated users to /login

After login/register, redirect to /onboarding if onboarding_completed is false, otherwise to /app/discover.

Use Tailwind CSS for styling. Match the Yaaro0 brand colors: primary pink #FD267A, gradient from #FF6036 to #FD267A.
```

---

---

# SPRINT 2 — Onboarding Wizard & Profile Setup

**Goal:** New users complete a multi-step profile wizard. All profile data saved. Profile viewable and editable.

---

## What to Build

### Wizard Steps

| Step | Name | Fields |
|---|---|---|
| 1 | Photos | Upload 2–9 photos, drag to reorder, first = main |
| 2 | About You | Display name, pronouns, sexual orientation, headline (60 chars), bio (500 chars) |
| 3 | Physical | Height (cm/ft toggle), body type, ethnicity, hair colour, eye colour |
| 4 | Background | Education, job title, company, industry, religion, nationality, languages |
| 5 | Lifestyle | Smoking, drinking, exercise, diet, sleep schedule, living situation, children, pets |
| 6 | Favourites | Favourite pet, colour, food, music, movie genre, hobbies (multi-select, max 10), love language, relationship goal |
| 7 | Preferences | Who to show me (gender), age range (slider), max distance (slider), global mode toggle |
| 8 | Location | Request browser location OR type city manually |

### Database Tables
```sql
user_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  display_name VARCHAR,
  pronouns VARCHAR,
  sexual_orientation VARCHAR[],
  headline VARCHAR(60),
  bio VARCHAR(500),
  height_cm INTEGER,
  body_type VARCHAR,
  ethnicity VARCHAR[],
  hair_colour VARCHAR,
  eye_colour VARCHAR,
  education VARCHAR,
  job_title VARCHAR,
  company VARCHAR,
  industry VARCHAR,
  religion VARCHAR,
  nationality VARCHAR,
  languages VARCHAR[],
  smoking VARCHAR,
  drinking VARCHAR,
  exercise VARCHAR,
  diet VARCHAR,
  sleep_schedule VARCHAR,
  living_situation VARCHAR,
  has_children VARCHAR,
  wants_children VARCHAR,
  has_pets VARCHAR[],
  wants_pets VARCHAR,
  fav_pet VARCHAR,
  fav_colour VARCHAR,
  fav_food VARCHAR[],
  fav_music VARCHAR[],
  fav_movie_genre VARCHAR[],
  love_language VARCHAR,
  relationship_goal VARCHAR,
  star_sign VARCHAR,  -- auto-calculated from DOB
  mbti VARCHAR,
  spotify_anthem_id VARCHAR,
  spotify_anthem_name VARCHAR
)

user_hobbies (
  user_id UUID REFERENCES users(id),
  hobby VARCHAR,
  PRIMARY KEY (user_id, hobby)
)

user_photos (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  url VARCHAR NOT NULL,
  order_index INTEGER,
  is_primary BOOLEAN DEFAULT false,
  status VARCHAR DEFAULT 'pending',  -- pending | approved | rejected
  created_at TIMESTAMP DEFAULT NOW()
)

user_locations (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  latitude DECIMAL,
  longitude DECIMAL,
  city VARCHAR,
  country VARCHAR,
  updated_at TIMESTAMP DEFAULT NOW()
)

user_preferences (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  show_gender VARCHAR DEFAULT 'everyone',
  min_age INTEGER DEFAULT 18,
  max_age INTEGER DEFAULT 45,
  max_distance_km INTEGER DEFAULT 50,
  global_mode BOOLEAN DEFAULT false,
  show_verified_only BOOLEAN DEFAULT false,
  show_photos_only BOOLEAN DEFAULT true
)
```

### Backend Endpoints
- `PUT  /api/profile/me` — update profile fields
- `GET  /api/profile/me` — get own profile
- `POST /api/profile/photos` — upload photo (multer + S3/Cloudinary)
- `DELETE /api/profile/photos/:id`
- `PUT  /api/profile/photos/reorder` — update order_index
- `PUT  /api/profile/preferences`
- `PUT  /api/profile/location`
- `PATCH /api/onboarding/complete` — mark onboarding done

---

## 🤖 Prompt to Use

```
Continue building the Yaaro0. Sprint 2: Onboarding Wizard & Profile Setup.

BACKEND tasks:
1. Create tables: user_profiles, user_hobbies, user_photos, user_locations, user_preferences (migration)
2. Photo upload endpoint: POST /api/profile/photos using multer, upload to Cloudinary (or S3), save URL to DB
3. PUT /api/profile/me — accepts partial updates, validates each field
4. GET /api/profile/me — return full profile joined across all tables
5. PUT /api/profile/photos/reorder — accept array of {id, order_index}
6. PUT /api/profile/preferences
7. PATCH /api/onboarding/complete — set onboarding_completed = true on users table

FRONTEND tasks:
1. Build an 8-step wizard at /onboarding. Show progress bar at top (step X of 8).
2. Save progress to backend on each "Next" click so the user can resume if they close the browser.
3. Step 1 — Photo upload: drag-and-drop grid (2x4 + 1 = 9 slots). First slot is always main photo. Drag to reorder.
4. Step 2 — About You: display name (pre-filled), pronouns (select), sexual orientation (multi-select pills), headline (60 char counter), bio (500 char counter)
5. Step 3 — Physical: height with cm/ft toggle, body type radio, ethnicity multi-select, hair colour, eye colour
6. Step 4 — Background: education dropdown, job title + company text fields, industry dropdown, religion dropdown, nationality searchable select, languages multi-select
7. Step 5 — Lifestyle: all fields as pill-based selectors (smoking, drinking, exercise, diet, sleep, living situation, children, pets)
8. Step 6 — Favourites: pill selectors for fav pet, fav colour, fav food (multi), fav music (multi), fav movie genre (multi), hobbies multi-select grid (max 10, show count), love language, relationship goal
9. Step 7 — Preferences: gender toggle buttons, age range dual slider (18–70+), distance slider (1km–160km+), global mode toggle
10. Step 8 — Location: "Use my location" button (navigator.geolocation) OR city search autocomplete (Google Places API or free alternative)

Also build: /app/profile/edit — same form as wizard but editable any time, sections collapsible.

Style with Tailwind. Pill selectors should be interactive chips with pink active state.
```

---

---

# SPRINT 3 — Discovery Engine (Swipe Screen)

**Goal:** The core swipe experience. Cards shown, users can like/pass/super like. Algorithm filters by preferences.

---

## What to Build

### Discovery Algorithm Logic
1. Filter by `user_preferences` (gender, age, distance/global mode)
2. Exclude already-swiped users
3. Exclude blocked users
4. Boost verified profiles slightly
5. Rank by: shared hobbies + shared favourites + same relationship goal = compatibility score
6. Return paginated batches of 20 cards

### Swipe Card Data
Each card shows:
- Main photo (full height)
- Name + Age
- Distance (km away)
- Headline
- Top 3 shared interests (icons)
- Match % (compatibility score)
- Expand chevron → show full profile modal

### Swipe Actions

| Action | Keyboard | Button | Result |
|---|---|---|---|
| Pass | ← Arrow | ✕ (grey) | Record PASS swipe |
| Like | → Arrow | ❤️ (pink) | Record LIKE swipe; check for match |
| Super Like | ↑ Arrow | ⭐ (blue) | Record SUPERLIKE; limited per day |
| Undo | U key | ↩️ | Reverse last swipe (Plus+ only) |

### Database Tables
```sql
swipes (
  id UUID PRIMARY KEY,
  swiper_id UUID REFERENCES users(id),
  swiped_id UUID REFERENCES users(id),
  action VARCHAR NOT NULL,  -- 'like' | 'pass' | 'superlike'
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(swiper_id, swiped_id)
)

matches (
  id UUID PRIMARY KEY,
  user1_id UUID REFERENCES users(id),
  user2_id UUID REFERENCES users(id),
  matched_at TIMESTAMP DEFAULT NOW(),
  status VARCHAR DEFAULT 'active',  -- active | unmatched
  UNIQUE(user1_id, user2_id)
)
```

### Backend Endpoints
- `GET  /api/discover` — returns candidate cards (filtered + ranked)
- `POST /api/swipe` — `{ target_user_id, action }` → saves swipe, checks match
- `POST /api/swipe/undo` — reverse last swipe (check tier)

### Swipe Limits (Free tier)
- 50 likes per 12-hour rolling window
- 1 Super Like per day
- Undo: not available on free tier

---

## 🤖 Prompt to Use

```
Continue the Yaaro0. Sprint 3: Discovery Engine (Swipe Screen).

BACKEND tasks:
1. Create tables: swipes, matches
2. GET /api/discover:
   - Filter candidates by the current user's preferences (gender, age range, max distance using Haversine formula on lat/lng)
   - Exclude users already swiped by current user
   - Exclude blocked users
   - Exclude current user's own profile
   - Only return users with onboarding_completed = true
   - Calculate a compatibility score (0-100) based on matching: relationship_goal (25pts), love_language (15pts), hobbies overlap (20pts), fav_music overlap (10pts), fav_food overlap (10pts), lifestyle fields smoking/drinking (10pts), fav_movie_genre (10pts)
   - Return 20 candidates per call, sorted by score DESC
   - Each card includes: id, display_name, age, main photo URL, distance_km, headline, top 3 shared hobbies, compatibility score
3. POST /api/swipe — save swipe. If action='like' or 'superlike', check if target already liked current user → if yes, create a match record + return { matched: true, matchId }
4. Enforce free-tier swipe limits: 50 likes per 12h window. Track in Redis or a swipe_limits table. Return 429 with { limitReached: true, resetAt: timestamp } when limit hit.
5. POST /api/swipe/undo — delete the last swipe record (only if user has Plus tier or above)

FRONTEND tasks:
1. Build /app/discover — full-screen swipe card stack
2. Stack shows top 3 cards (z-indexed). Only top card is interactive.
3. Implement swipe gesture using react-spring or framer-motion:
   - Drag card left → shows ✕ red overlay → on release past threshold: fire PASS
   - Drag card right → shows ❤️ green overlay → on release past threshold: fire LIKE
   - Drag card up → shows ⭐ blue overlay → fire SUPERLIKE
4. Action buttons below card: ✕ (pass), ⭐ (super like), ❤️ (like), ↩️ (undo)
5. Card info overlay at bottom: name, age, distance, headline, shared interests pills
6. Tap card → expand to full profile modal (all photos scrollable, full bio, all profile details)
7. When cards run out: "You've seen everyone nearby. Try expanding your distance!" with refresh button
8. "It's a Match!" modal popup when a match occurs: shows both profile photos, animated confetti, "Send Message" and "Keep Swiping" buttons
9. Show swipe limit warning when < 5 likes remaining. Show upgrade prompt when 0 reached.
10. Keyboard shortcut support: ← pass, → like, ↑ superlike, U undo

Style: full-screen layout, card with rounded corners and subtle shadow, smooth spring-physics drag animation.
```

---

---

# SPRINT 4 — Matches List & Profile Viewing

**Goal:** Users can see all their mutual matches, view match profiles, unmatch, and see who Super Liked them.

---

## What to Build

### Matches Screen
- Grid of match cards (photo + name)
- Badge showing unread message count
- Timestamp of match
- "New Match!" highlight on matches < 24h old
- Search bar to filter matches by name
- "Likes You" section (Gold/Platinum only — blurred for free users)

### Profile View Modal
- Full photo carousel (swipe between photos)
- All profile sections displayed
- Shared interests highlighted
- Compatibility % prominently shown
- Report / Block buttons
- Unmatch button (from match view)

### Backend Endpoints
- `GET  /api/matches` — list all active matches with last message preview
- `DELETE /api/matches/:matchId` — unmatch
- `GET  /api/users/:userId/profile` — view another user's profile
- `GET  /api/likes/received` — who liked me (Gold+ returns full list; free returns count + blurred)

---

## 🤖 Prompt to Use

```
Continue the Yaaro0. Sprint 4: Matches & Profile Viewing.

BACKEND tasks:
1. GET /api/matches — return all matches for current user where status='active'. Include: matched user's display_name, main photo, age, last_active_at, last message preview + timestamp, unread message count (will be 0 for now, updated in Sprint 5), matched_at
2. DELETE /api/matches/:matchId — set status='unmatched', soft-delete or archive messages
3. GET /api/users/:userId/profile — return full public profile (photos, bio, hobbies, lifestyle, background). Do NOT return email, location coords (only city name), or blocked users
4. GET /api/likes/received — if user tier is 'gold' or 'platinum': return full list of users who liked current user (from swipes table where swiped_id=currentUser and action IN ('like','superlike') and no match yet). If 'free' or 'plus': return { count: N, blurred: true }

FRONTEND tasks:
1. /app/matches page:
   - Top section: "New Matches" horizontal scroll row (matches < 24h old, shown as large circles)
   - Below: "Messages" list (matches with conversation history — for now just show all matches)
   - Each row: photo, name, age, last message preview or "Say hello 👋", timestamp, unread badge
   - Search bar at top to filter by name
   - Tap a match → go to /app/messages/:matchId (Sprint 5 builds this)
2. "Likes You" section (visible on matches page):
   - Gold/Platinum: show grid of users who liked you with "Like Back" button per card
   - Free: show blurred grid with count "X people liked you" + "Upgrade to See" button
3. Full profile view modal (used when tapping card in discover or from matches):
   - Photo carousel at top (swipe between photos, dots indicator)
   - Name, age, distance, verification badge if verified
   - Compatibility % in a coloured ring
   - Shared hobbies section (highlighted green)
   - All profile sections: About, Basics, Lifestyle, Interests
   - Bottom action bar: Report | Block | (if in discover: ❤️ Like) | (if matched: 💬 Message)
4. Unmatch flow: long press or ⋮ menu on match → "Unmatch" → confirmation dialog → remove from list

Style consistent with Sprint 3. Match list should feel like Yaaro0's current UI: photo circle + text row layout.
```

---

---

# SPRINT 5 — Real-time Messaging

**Goal:** Full chat system between matches using Socket.IO. Text, photos, GIFs, emoji reactions, voice notes.

---

## What to Build

### Chat Features
- Real-time message delivery (Socket.IO)
- Text messages
- Photo sharing (upload image in chat)
- GIF search (Giphy API integration)
- Emoji reactions on messages
- Voice messages (record in browser, upload audio)
- Read receipts (Delivered / Seen)
- Typing indicator ("Alex is typing...")
- Message deletion (delete for me / delete for both)
- Report a message
- Infinite scroll (load older messages on scroll up)

### Database Tables
```sql
messages (
  id UUID PRIMARY KEY,
  match_id UUID REFERENCES matches(id),
  sender_id UUID REFERENCES users(id),
  content TEXT,
  message_type VARCHAR DEFAULT 'text',  -- text | photo | gif | voice | system
  media_url VARCHAR,
  gif_url VARCHAR,
  voice_duration_seconds INTEGER,
  is_deleted_sender BOOLEAN DEFAULT false,
  is_deleted_receiver BOOLEAN DEFAULT false,
  reactions JSONB DEFAULT '{}',  -- { userId: emoji }
  sent_at TIMESTAMP DEFAULT NOW(),
  read_at TIMESTAMP
)
```

### Backend Endpoints
- `GET  /api/messages/:matchId?cursor=&limit=30` — paginated message history
- `POST /api/messages/:matchId` — send text/photo/gif message
- `DELETE /api/messages/:messageId` — soft delete
- `POST /api/messages/:messageId/react` — add emoji reaction

### Socket.IO Events
```
Client → Server:
  join_room (matchId)
  send_message (matchId, content, type)
  typing_start (matchId)
  typing_stop (matchId)
  mark_read (matchId, messageId)
  react_message (messageId, emoji)

Server → Client:
  new_message (message object)
  user_typing (userId, matchId)
  user_stopped_typing (userId, matchId)
  message_read (messageId, readAt)
  message_reaction (messageId, userId, emoji)
```

---

## 🤖 Prompt to Use

```
Continue the Yaaro0. Sprint 5: Real-time Messaging.

BACKEND tasks:
1. Create messages table (migration)
2. Socket.IO server setup alongside Express:
   - Authenticate socket connections using JWT (pass token in handshake auth)
   - join_room: user joins room named after matchId (validate they are part of that match)
   - send_message: save to DB, emit new_message to both users in the room
   - typing_start / typing_stop: emit to the other user in the room (don't save to DB)
   - mark_read: update read_at on message, emit message_read back
   - react_message: update reactions JSONB field, emit message_reaction
3. REST: GET /api/messages/:matchId?cursor=&limit=30 (cursor-based pagination, newest first)
4. REST: POST /api/messages/:matchId — accepts { content, type, media_url, gif_url }
5. REST: DELETE /api/messages/:messageId — set is_deleted_sender or is_deleted_receiver based on who deletes
6. Giphy API integration: GET /api/giphy/search?q= — proxy to Giphy API (keep API key server-side)
7. Voice message upload: POST /api/messages/:matchId/voice — multer upload audio/webm to S3/Cloudinary, save URL

FRONTEND tasks:
1. /app/messages/:matchId — full chat screen:
   - Header: match's photo (circle), name, "active X mins ago" or green dot if online, back arrow, ⋮ menu
   - Message list: infinite scroll (load 30 more on scroll to top). My messages right-aligned (pink bubble), theirs left-aligned (grey bubble)
   - Typing indicator: "..." animated bubble when partner is typing
   - Read receipt: "Seen" timestamp under last read message
   - Long-press message → reaction picker (emoji bar) + "Delete" option
   - Bottom input bar:
     - Text input (expandable)
     - 📷 photo button (file input → upload → send as photo message)
     - GIF button → open Giphy search modal
     - 🎤 voice button (hold to record using MediaRecorder API, release to send)
     - Send button
2. Giphy modal: search input, grid of GIFs, tap to send
3. Match info: tapping header photo → opens their profile modal (from Sprint 4)
4. Unmatch: ⋮ menu → "Unmatch" → confirm dialog
5. Report: ⋮ menu → "Report" → reason select → submit (Sprint 8 handles backend)
6. Online status: track via Socket.IO presence. Store active sockets in Redis. Show green dot if online.
7. Update unread badge in matches list when new message arrives and chat is not open.

Use Socket.IO client. Reconnect automatically on disconnect. Handle optimistic message sending (show message immediately, confirm on server ack).
```

---

---

# SPRINT 6 — Explore Tab & Interest-Based Discovery

**Goal:** Explore tab with interest-based browsing, categories, Vibes, and Hot Takes (speed dating).

---

## What to Build

### Explore Sections
- **By Interest:** Browse people who share a specific hobby/interest
- **By Relationship Goal:** Filter by "Long-term", "Casual", "Friends", etc.
- **Vibes:** Timed event where users answer prompts — if both answers align, they're shown to each other
- **Hot Takes:** Speed dating — matched with someone for a 30-second text chat, then choose to like or pass
- **Nearby:** Users within very short distance (e.g. 2km)

### Backend Endpoints
- `GET /api/explore/categories` — list of interest categories
- `GET /api/explore/by-interest/:hobby` — users with that hobby
- `GET /api/explore/by-goal/:goal` — users with that relationship goal
- `GET /api/explore/nearby` — users within 2km

---

## 🤖 Prompt to Use

```
Continue the Yaaro0. Sprint 6: Explore Tab.

BACKEND tasks:
1. GET /api/explore/categories — return list of hobbies with user counts
2. GET /api/explore/by-interest/:hobby — return users who have that hobby, filtered by user's preferences (age, gender, distance), exclude already-swiped, sorted by compatibility score
3. GET /api/explore/by-goal/:goal — same but filter by relationship_goal field
4. GET /api/explore/nearby — users within 2km using Haversine, exclude already-swiped

FRONTEND tasks:
1. /app/explore — grid layout with category tiles (emoji icon + label + "X people" count)
   Categories: Fitness 🏋️, Foodies 🍕, Travel ✈️, Gamers 🎮, Music 🎵, Outdoors 🌲, Creatives 🎨, Bookworms 📚, etc.
2. Tap a category → /app/explore/:category — shows user cards in a scrollable grid (not swipe, but tap card → like/pass)
3. Each card in grid: photo, name, age, 1-2 shared tags highlighted
4. Relationship Goal filter at top (chips): Long-term / Casual / Friends / Not sure
5. "Vibes" section:
   - Shows a fun question (e.g. "Would you rather: travel or stay home?") with two answer buttons
   - After answering, briefly show users who answered the same (as swipeable cards)
   - Store vibe responses in a vibes table (user_id, question_id, answer, timestamp)
   - Questions refresh every 24 hours
6. "Hot Takes" section (optional — can stub with "Coming Soon" if time limited):
   - 30-second timed chat with a random user
   - Both users see a countdown timer
   - At end: ❤️ Like or ✕ Pass
7. Keep a bottom navigation bar across all /app/* pages: Discover 🔥 | Explore 🌍 | Matches 💬 | Profile 👤

Style: card grid with rounded corners, category tiles with gradient backgrounds.
```

---

---

# SPRINT 7 — Premium Tiers, Boost & Super Like

**Goal:** Implement Free / Plus / Gold / Platinum tiers with all feature gates, Boost, Super Like with message, Passport, and payment integration.

---

## Tier Feature Matrix

| Feature | Free | Plus | Gold | Platinum |
|---|---|---|---|---|
| Daily likes | 50 | Unlimited | Unlimited | Unlimited |
| Super Likes / day | 1 | 1 | 3/week | 3/week |
| Rewind last swipe | ❌ | ✅ | ✅ | ✅ |
| Passport (change location) | ❌ | ✅ | ✅ | ✅ |
| Incognito mode | ❌ | ✅ | ✅ | ✅ |
| No ads | ❌ | ✅ | ✅ | ✅ |
| Boost (1/month) | ❌ | ✅ | ✅ | ✅ |
| See who liked you | ❌ | ❌ | ✅ | ✅ |
| Top Picks (daily) | ❌ | ❌ | ✅ | ✅ |
| Priority likes | ❌ | ❌ | ❌ | ✅ |
| Message before match | ❌ | ❌ | ❌ | ✅ |

### Database Tables
```sql
subscriptions (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  tier VARCHAR NOT NULL,  -- 'free' | 'plus' | 'gold' | 'platinum'
  started_at TIMESTAMP,
  expires_at TIMESTAMP,
  stripe_subscription_id VARCHAR,
  status VARCHAR  -- 'active' | 'cancelled' | 'expired'
)

boosts (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  started_at TIMESTAMP,
  ends_at TIMESTAMP,  -- started_at + 30 minutes
  views_gained INTEGER DEFAULT 0
)

super_likes (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  target_user_id UUID REFERENCES users(id),
  message VARCHAR(140),  -- Platinum only
  sent_at TIMESTAMP DEFAULT NOW()
)
```

---

## 🤖 Prompt to Use

```
Continue the Yaaro0. Sprint 7: Premium Tiers, Boost & Payments.

BACKEND tasks:
1. Create subscriptions, boosts tables
2. Middleware: getUserTier(userId) — check active subscription, return tier string
3. Integrate Stripe:
   - POST /api/payments/create-checkout — create Stripe Checkout session for selected tier
   - POST /api/payments/webhook — handle stripe events: checkout.session.completed → activate subscription, customer.subscription.deleted → expire
   - GET  /api/payments/subscription — return current subscription details
   - POST /api/payments/cancel — cancel at period end
4. Feature gates (middleware checks):
   - Swipe limit: reject 51st like per 12h for free users
   - Rewind: reject if tier = 'free'
   - Passport: reject location change if tier = 'free'
   - Incognito: reject if tier = 'free'
   - See who liked you: return blurred if tier not 'gold'/'platinum'
5. POST /api/boost/start — set boost active for 30 minutes. Modify discover algorithm: if a user has active boost, include them at top of every candidate list until boost expires.
6. Boost count: Plus/Gold/Platinum get 1 free boost/month. Track in boosts table.
7. Top Picks: GET /api/top-picks — for Gold+ users, return 10 algorithmically curated profiles per day. Refresh at midnight. Cache in Redis.
8. Passport: POST /api/profile/location/passport — update user_locations temporarily. Add flag passport_active. Revert when passport mode turned off.
9. Incognito: when incognito=true in user_preferences, exclude this user from all /discover and /explore results EXCEPT for people this user has already liked.
10. Message before matching (Platinum): POST /api/super-like — save super_like record with optional 140-char message. Target user sees the message in their "Likes You" section.

FRONTEND tasks:
1. /app/premium — pricing page with tier comparison table. Highlight recommended tier. "Get Gold" / "Get Platinum" CTA buttons → redirect to Stripe Checkout
2. Upgrade prompts: show contextual modal when free user hits a gate (e.g. tries to rewind: "Rewind is a Plus feature — Upgrade to undo your last swipe")
3. Boost button in discover screen (⚡ icon). Tap → confirm start boost → show 30-min countdown timer on screen while active. Show "X views" counter that increments.
4. Passport modal: map + city search. Set virtual location. Show "Passport Active" banner in header.
5. Incognito toggle in settings.
6. Super Like with message (Platinum): when using Super Like, show input (140 chars) for optional pre-match message.
7. Subscription management page: current plan, renewal date, cancel button, upgrade/downgrade options.
```

---

---

# SPRINT 8 — Safety, Verification & Moderation

**Goal:** Photo verification, user reporting, blocking, content safety, and age verification.

---

## What to Build

- **Photo Verification:** Selfie match check (pose-matching or manual review)
- **Report User:** Multi-reason report form, submitted to admin queue
- **Block User:** Mutual hide from all discovery and search
- **ID Age Verification:** Upload ID for 18+ confirmation (manual or Persona/Stripe Identity)
- **Profanity filter:** Block offensive bios and messages
- **Safety Center:** In-app safety tips, emergency resources

### Database Tables
```sql
reports (
  id UUID PRIMARY KEY,
  reporter_id UUID REFERENCES users(id),
  reported_user_id UUID REFERENCES users(id),
  reason VARCHAR NOT NULL,
  description TEXT,
  screenshot_url VARCHAR,
  status VARCHAR DEFAULT 'pending',
  reviewed_at TIMESTAMP,
  reviewer_id UUID,
  action_taken VARCHAR,
  created_at TIMESTAMP DEFAULT NOW()
)

blocked_users (
  blocker_id UUID REFERENCES users(id),
  blocked_id UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (blocker_id, blocked_id)
)

verifications (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  photo_verified BOOLEAN DEFAULT false,
  id_verified BOOLEAN DEFAULT false,
  photo_verified_at TIMESTAMP,
  id_verified_at TIMESTAMP,
  verification_selfie_url VARCHAR
)
```

---

## 🤖 Prompt to Use

```
Continue the Yaaro0. Sprint 8: Safety, Verification & Moderation.

BACKEND tasks:
1. Create reports, blocked_users, verifications tables
2. POST /api/reports — save report. Notify admin via email. Return success.
3. POST /api/users/block/:userId — add to blocked_users. Also unmatch if matched. Hide from each other permanently.
4. GET /api/users/blocked — list blocked users
5. DELETE /api/users/block/:userId — unblock
6. Modify all discovery queries (GET /api/discover, /api/explore/*) to exclude mutually blocked users
7. Photo verification flow:
   - POST /api/verification/photo — upload selfie. Store as verification_selfie_url.
   - Admin reviews via admin portal (Sprint 11). Admin can approve/reject.
   - On approve: set photo_verified=true, add verified badge to profile
8. Profanity filter middleware: run bio, headline, and chat messages through a word-filter library (e.g. 'bad-words' npm). Reject with 422 if triggered.
9. POST /api/users/unmatch/:matchId — already built, but also trigger from report flow option "Unmatch & Report"

FRONTEND tasks:
1. Report flow:
   - Available from: swipe card ⋮ menu, profile view, chat ⋮ menu
   - Step 1: reason select (Harassment / Fake Profile / Spam / Inappropriate Photos / Underage / Scam / Other)
   - Step 2: optional description textarea + optional screenshot upload
   - Submit → "Thanks for letting us know" confirmation
   - Option: also block this person
2. Block flow: available from profile view and chat. Confirm dialog: "Block [Name]? They won't be able to see your profile or message you." → block + optionally unmatch
3. Blocked users list in settings → tap to unblock
4. Photo verification:
   - /app/settings/verify — show selfie instructions + camera/upload button
   - After submit: show "Pending Review" state
   - Once verified: green checkmark badge appears on profile
5. Safety Center page (/app/safety):
   - Safe dating tips
   - How to report
   - Emergency resources section
   - Link to block/report guide
6. Age gate: if user somehow bypasses DOB check, they see a hard block screen
```

---

---

# SPRINT 9 — Notifications System

**Goal:** In-app notifications, push notifications (Web Push API), and email notifications.

---

## Notification Types

| Event | In-App | Push | Email |
|---|---|---|---|
| New match | ✅ | ✅ | ✅ |
| New message | ✅ | ✅ | ✅ (if not opened in 5min) |
| Someone liked you (Gold+) | ✅ | ✅ | ❌ |
| Super Like received | ✅ | ✅ | ✅ |
| Profile view (Platinum) | ✅ | ❌ | ❌ |
| Boost ended | ✅ | ✅ | ❌ |
| Match expiry warning | ✅ | ✅ | ✅ |
| Verification approved | ✅ | ✅ | ✅ |
| Subscription renewal | ❌ | ❌ | ✅ |
| Inactivity (7 days) | ❌ | ❌ | ✅ |

---

## 🤖 Prompt to Use

```
Continue the Yaaro0. Sprint 9: Notifications.

BACKEND tasks:
1. Create notifications table: (id, user_id, type, title, body, data JSONB, read BOOLEAN, created_at)
2. Create a NotificationService that:
   - saveNotification(userId, type, title, body, data) — saves to DB
   - sendPush(userId, title, body) — sends Web Push using 'web-push' npm package
   - sendEmail(userId, templateId, data) — sends via SendGrid
3. Hook notifications into existing events:
   - New match: notify both users
   - New message: notify recipient if not in chat room (check Socket.IO room presence)
   - Super Like received: notify target user
   - Boost ended: notify user (schedule with setTimeout or a job queue like bull/bullmq)
   - Verification approved: notify user
4. GET /api/notifications — return last 50 notifications for current user, unread first
5. PATCH /api/notifications/read — mark all as read
6. PATCH /api/notifications/:id/read — mark single as read
7. Web Push: store push subscriptions table (user_id, endpoint, keys). Endpoint: POST /api/push/subscribe

FRONTEND tasks:
1. Notification bell icon in header with red unread count badge
2. Notifications dropdown/panel: list of notifications with icon, title, body, timestamp, unread highlight
3. Click notification → navigate to relevant page (match → /app/matches, message → /app/messages/:matchId)
4. "Mark all read" button
5. Push notification permission prompt: show after user's first match with friendly dialog ("Enable notifications to never miss a match!")
6. Register service worker for Web Push API
7. Notification preferences in settings (/app/settings/notifications):
   - Toggle each notification type on/off (stored in user_preferences)
   - Email notification toggles
8. Email templates (HTML): New Match, New Message (digest), Super Like, Weekly Recap ("You have X new likes this week!")
```

---

---

# SPRINT 10 — Profile Enhancements

**Goal:** Spotify anthem, MBTI quiz, Vibes answers, badges, profile completeness score, profile analytics.

---

## What to Build

- **Spotify Anthem:** Search Spotify tracks, add to profile. Plays 30-sec preview when someone views profile
- **MBTI personality type:** Built-in quiz OR manual select
- **Interest badges:** Auto-generated based on hobbies (e.g. "🎮 Gamer", "✈️ Traveller")
- **Profile completeness meter:** % complete with prompts to fill gaps
- **Profile analytics (Platinum):** Views this week, likes received, match rate %
- **Double Date feature:** Match with another couple/pair for group activities

---

## 🤖 Prompt to Use

```
Continue the Yaaro0. Sprint 10: Profile Enhancements.

BACKEND tasks:
1. Spotify anthem:
   - GET /api/spotify/search?q= — proxy to Spotify search API (client credentials flow). Return track name, artist, 30s preview_url, album art URL.
   - PUT /api/profile/anthem — save spotify_anthem_id, spotify_anthem_name, spotify_preview_url to user_profiles
2. MBTI quiz: create a quiz_questions table with 20 Y/N questions and their MBTI scoring key. GET /api/mbti/questions. POST /api/mbti/submit → calculate + save result to user_profiles.mbti
3. Profile completeness: GET /api/profile/completeness — calculate % filled (weight each section). Return { score: 72, missing: ['job_title', 'hobbies'] }
4. Profile analytics (Platinum only): GET /api/profile/analytics — return { profile_views_7d, likes_received_7d, match_rate_percent }. Track profile views in a profile_views table (viewer_id, viewed_id, viewed_at).
5. Add star_sign auto-calculation in profile GET (derive from DOB stored in users table)

FRONTEND tasks:
1. Anthem section in profile edit:
   - Search input with debounced Spotify search
   - Track results list (album art, name, artist)
   - Tap → set as anthem, show preview play button
   - On another user's profile card: auto-play 30s preview audio (muted by default, tap 🎵 to unmute)
2. MBTI section: "Take the quiz" button → 20 questions (binary choice) → result screen with type description + add to profile
3. Profile completeness bar at top of /app/profile: "Your profile is 72% complete. Add your job title to attract more matches →"
4. Interest badges: auto-render emoji+label chips from hobbies array. Show max 5 on card, rest visible in full profile.
5. Profile analytics card (Platinum users only) in /app/profile:
   - "You appeared in X searches this week"
   - "X people liked your profile"
   - "Your match rate: X%"
   - Simple bar chart for last 7 days views
6. Verified badge (✓ blue checkmark) shown on cards and in chat header for photo-verified users
```

---

---

# SPRINT 11 — Admin Portal

**Goal:** Full admin dashboard with user management, report queue, content moderation, and app settings.

---

## What to Build

The admin portal lives at `/admin` — a completely separate section with its own auth.

### Admin Roles
- **Super Admin** — full access
- **Moderator** — users, reports, content
- **Support** — view only + respond to tickets
- **Analyst** — read-only stats

### Sections
1. Dashboard — KPIs + charts
2. User Management — list, search, filter, view, suspend, ban, delete
3. Reports Queue — review, action, dismiss
4. Photo Moderation — approve/reject pending photos
5. Analytics — match rate, message volume, retention charts
6. Subscriptions — revenue, active subs, refunds
7. Notifications — send broadcast push/email
8. App Settings — limits, feature flags, maintenance mode
9. Audit Log — all admin actions

---

## 🤖 Prompt to Use

```
Continue the Yaaro0. Sprint 11: Admin Portal.

BACKEND tasks:
1. Create admins table: (id, email, password_hash, role, is_active, created_at)
2. Separate admin JWT middleware (different secret, role-based access per route)
3. POST /admin/api/auth/login — admin login
4. GET  /admin/api/dashboard — return: total users, active_7d, active_30d, new_today, new_week, total_matches, messages_today, pending_reports, verified_users, premium_users, revenue_month. Also return daily_signups array (last 30 days) for chart.
5. GET  /admin/api/users?page=&limit=&status=&gender=&verified=&premium=&search= — paginated user list with filters
6. GET  /admin/api/users/:id — full user detail (all profile data, photos, activity, subscriptions, reports)
7. PATCH /admin/api/users/:id/status — set status (active/suspended/banned/deleted). Suspended: include suspend_until timestamp.
8. GET  /admin/api/reports?status=pending — reports queue
9. PATCH /admin/api/reports/:id — update status + action_taken. If action=ban: also update user status.
10. GET  /admin/api/photos/pending — photos awaiting moderation
11. PATCH /admin/api/photos/:id — approve or reject photo
12. GET  /admin/api/settings — return app settings from a key-value settings table
13. PUT  /admin/api/settings — update settings (max_daily_swipes_free, superlike_daily_free, boost_duration_minutes, etc.)
14. POST /admin/api/broadcast — send push notification to all users (or filtered segment by tier/country)
15. GET  /admin/api/audit-log — paginated log of all admin actions (auto-log every mutating admin action with admin_id, action, target, ip)

FRONTEND tasks (separate React app or sub-router at /admin):
1. Admin login page (simple, no Yaaro0 branding)
2. Sidebar navigation: Dashboard / Users / Reports / Photos / Analytics / Revenue / Broadcast / Settings / Audit Log
3. Dashboard: KPI card grid + recharts line chart (signups) + pie chart (gender) + bar chart (daily active users)
4. Users table: sortable columns, filter bar, status colour badge, action buttons (View / Suspend / Ban / Delete)
5. User detail drawer/page: tabbed (Profile | Photos | Activity | Reports | Subscription)
6. Reports queue: table with priority ordering, "Review" button opens detail panel, action buttons (Warn / Suspend 3d / Suspend 7d / Ban / Dismiss)
7. Photo moderation: grid of pending photos, approve ✓ or reject ✗ per photo, batch actions
8. Settings form: grouped input fields with save button per group, confirmation before save
9. Broadcast form: message input, audience filter (all / free / premium / by country), preview count, send button
10. Audit log table: admin name, action description, target, timestamp, IP address
```

---

---

# SPRINT 12 — Polish, PWA & Performance

**Goal:** Animations, progressive web app, SEO, accessibility, error states, loading skeletons, performance optimisation.

---

## What to Build

- Swipe card physics fine-tuning (spring animation)
- Page transition animations
- Loading skeleton screens for every async view
- Empty state illustrations for no matches, no messages, etc.
- PWA manifest + service worker (installable on desktop/mobile)
- Offline support (show cached matches/messages)
- SEO meta tags for public pages (landing, about)
- Accessibility audit (WCAG 2.1 AA): keyboard nav, screen reader labels, colour contrast
- Error boundary components
- API error handling UX (toast notifications)
- Performance: lazy load images, code splitting, virtual scroll for long match lists
- Analytics integration (Mixpanel or PostHog): track swipes, matches, messages, upgrades

---

## 🤖 Prompt to Use

```
Continue the Yaaro0. Sprint 12: Polish, PWA & Performance.

TASKS:
1. PWA setup:
   - Create manifest.json (name, icons, theme_color #FD267A, background_color, display: standalone)
   - Service worker (Workbox): cache-first for static assets, network-first for API calls, offline fallback page
   - Install prompt for desktop and mobile

2. Loading states:
   - Create SkeletonCard component (animated shimmer) for discover stack
   - Create SkeletonList component for matches list
   - Add Suspense boundaries around all lazy-loaded routes

3. Animations (framer-motion):
   - Page transitions: slide-in from right on navigate forward, slide-back on back
   - Match modal: scale + confetti burst animation
   - Swipe card: tilt physics during drag (rotate by drag velocity), fly off screen on confirm
   - Notification badge: bounce-in when new notification arrives
   - Bottom nav: active tab indicator slide

4. Empty states:
   - No more cards: illustrated empty state "You've seen everyone nearby. Try expanding your distance!" with illustration + action button
   - No matches yet: "Start swiping to find your match ❤️"
   - No messages: "Say hello to your matches!"
   - All caught up on notifications

5. Error handling:
   - Global error boundary component (catches React errors, shows friendly screen)
   - Axios error interceptor → toast notification for network errors
   - 429 (rate limit) → special "Likes used up" screen, not generic error
   - 401 → auto-redirect to login

6. Performance:
   - Lazy load all route components with React.lazy()
   - Image lazy loading with IntersectionObserver (or loading="lazy")
   - Virtual scroll on matches list if > 50 items (react-window)
   - Debounce all search inputs
   - Memoize expensive selectors

7. Accessibility:
   - All buttons have aria-label
   - All images have alt text
   - Focus trap in modals
   - Keyboard navigation: Tab through cards, Enter to like, Esc to close modals
   - Colour contrast check: ensure all text meets WCAG AA 4.5:1 ratio against pink/gradient backgrounds

8. Analytics:
   - Integrate PostHog (or Mixpanel)
   - Track events: sign_up, onboarding_completed, swipe (with action property), match_created, message_sent, upgrade_clicked, subscription_started

9. SEO (public pages):
   - OpenGraph meta tags on landing page
   - Twitter card meta
   - robots.txt
   - Canonical URLs

10. Final QA checklist:
    - Test all auth flows (register, verify, login, reset)
    - Test swipe limit enforcement per tier
    - Test all premium gates
    - Test real-time chat (open two browser windows)
    - Test report + block flow end-to-end
    - Test admin moderation actions affect user-facing app
    - Lighthouse audit: target > 90 performance, 100 accessibility
```

---

---

## 📦 Final Project Structure

```
/
├── client/                   (React app)
│   ├── src/
│   │   ├── pages/
│   │   │   ├── auth/         (register, login, verify, reset)
│   │   │   ├── onboarding/   (8-step wizard)
│   │   │   ├── app/          (discover, matches, messages, profile, explore)
│   │   │   └── admin/        (all admin pages)
│   │   ├── components/       (shared UI components)
│   │   ├── contexts/         (auth, socket, notifications)
│   │   ├── hooks/            (useSwipe, useMessages, usePremium, etc.)
│   │   ├── services/         (API calls, socket events)
│   │   └── utils/
│   └── public/               (manifest.json, icons, service worker)
│
└── server/                   (Node.js + Express)
    ├── src/
    │   ├── routes/
    │   │   ├── auth.js
    │   │   ├── profile.js
    │   │   ├── discover.js
    │   │   ├── swipe.js
    │   │   ├── matches.js
    │   │   ├── messages.js
    │   │   ├── explore.js
    │   │   ├── payments.js
    │   │   ├── notifications.js
    │   │   ├── reports.js
    │   │   └── admin/
    │   ├── middleware/
    │   │   ├── auth.js        (JWT verify)
    │   │   ├── tierGate.js    (premium checks)
    │   │   └── rateLimit.js
    │   ├── services/
    │   │   ├── matchService.js
    │   │   ├── notificationService.js
    │   │   ├── emailService.js
    │   │   └── compatibilityService.js
    │   ├── socket/            (Socket.IO event handlers)
    │   └── db/
    │       ├── migrations/    (one file per sprint)
    │       └── queries/
```

---

## 🎨 Design Tokens

```css
--color-primary:   #FD267A;
--color-secondary: #FF6036;
--gradient-brand:  linear-gradient(to right, #FF6036, #FD267A);
--color-superlike: #1DA1F2;
--color-pass:      #E8E8E8;
--color-bg:        #FFFFFF;
--color-bg-dark:   #F7F7F7;
--color-text:      #21243D;
--color-muted:     #9B9B9B;
--border-radius-card: 16px;
--border-radius-pill: 50px;
--shadow-card: 0 4px 20px rgba(0,0,0,0.12);
```

---

*Version 1.0 · Dating App Sprint Plan · 12 Sprints · ~24 weeks*
