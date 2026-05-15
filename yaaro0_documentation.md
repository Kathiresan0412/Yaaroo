# Yaro0 | தமிழ் இணைவு — Tamil Dating & Matrimony Platform Documentation

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Database Schema](#2-database-schema)
3. [API Documentation](#3-api-documentation)
4. [Express Backend Setup](#4-express-backend-setup)
5. [Next.js Frontend Setup](#5-nextjs-frontend-setup)
6. [Flutter App Setup](#6-flutter-app-setup)
7. [Production Server Setup](#7-production-server-setup)

---

## 1. Project Overview

### Project Structure

```
yaro0/
├── frontend/
│   ├── public-site/          # User-facing web app (Next.js)
│   └── admin-panel/          # Admin dashboard (Next.js)
├── backend/                  # Express + TypeScript API
├── mobile/                   # Flutter app (iOS + Android)
└── docs/                     # Documentation
```

### Technology Stack

**Frontend (Web)**
- Next.js 14 (App Router)
- TypeScript
- Tailwind CSS
- Shadcn/ui Components
- Zustand (State Management)
- React Query (Data Fetching)
- Framer Motion (Animations)
- Socket.io Client (Real-time chat)

**Backend**
- Node.js 20+
- Express.js
- TypeScript
- MySQL 8.0
- Prisma ORM
- JWT token-based API authentication
- BullMQ queue processing
- Socket.io real-time chat
- Cloudflare R2 / AWS S3 file management
- Redis (Queue + Session + Cache)

**Mobile**
- Flutter 3.x (Dart)
- Flutter Bloc (State Management)
- Dio (HTTP Client)
- Firebase Messaging (Push Notifications)
- Agora SDK (Video Calls)

**External Integrations**
- Firebase Cloud Messaging (Push Notifications)
- Agora.io (Video & Voice Calls)
- Razorpay (India/LK Payments)
- Stripe (Global Diaspora Payments)
- Twilio / MSG91 (OTP SMS)
- Cloudflare R2 / AWS S3 (Image Storage)
- Socket.io (WebSocket)

---

### Application Structure

**Public Site / Mobile App (User Portal)**
- Phone OTP registration & login
- Profile creation (Tamil/English bilingual)
- Jathagam (horoscope) details
- Photo upload with moderation
- Browse & discover matches
- Smart filters (location, age, caste, education, diaspora country)
- Swipe / Express Interest
- Mutual match unlock
- Real-time chat (text + voice note)
- Video call (premium)
- Subscription & payment
- Free trial (7 days full access)
- Profile verification (ID upload)
- Block / report user
- Notification centre

**Admin Panel**
- Dashboard with analytics
- User management & verification
- Profile moderation (photo approval)
- Subscription & payment management
- Report & block management
- Notification broadcast
- Banner & announcement management
- Community event management
- Settings & configuration

---

### Key Features

**User Features**
1. Phone OTP authentication (no password required)
2. Bilingual profile — Tamil & English fields
3. Jathagam (star, rasi, lagnam) entry
4. Photo upload — up to 6 photos (admin moderated)
5. Smart match suggestions (AI scoring based on preferences)
6. Free 7-day trial — unlimited messaging
7. After trial: 5 free messages/day or upgrade
8. Video call (Agora — premium only)
9. Women-safe mode — only verified men can message
10. Diaspora filter — connect Tamils in LK, India, UK, Canada, Malaysia, Singapore, UAE
11. Block & report with instant action
12. ID verification badge (optional paid add-on)
13. Horoscope compatibility score display
14. Community events feed

**Admin Features**
1. User verification queue (ID review)
2. Photo moderation queue
3. Subscription plan management
4. Revenue analytics
5. Report queue with action (warn / ban)
6. Broadcast push notifications
7. Event management
8. Global settings (free trial days, message limits, etc.)

---

### Database Overview

Core tables: `users`, `profiles`, `profile_photos`, `preferences`, `jathagams`, `matches`, `interests`, `messages`, `conversations`, `subscriptions`, `subscription_plans`, `payments`, `verifications`, `reports`, `blocks`, `events`, `notifications`, `settings`

---

### API Architecture

**Authentication**
- JWT token-based authentication
- OTP via SMS (Twilio / MSG91)
- Role-based access (admin, moderator, user)

**API Endpoint Structure**
```
/api/v1/auth/*              Authentication (OTP send/verify)
/api/v1/profile/*           Profile CRUD
/api/v1/photos/*            Photo upload & management
/api/v1/matches/*           Match suggestions & algorithms
/api/v1/interests/*         Express interest / accept / decline
/api/v1/conversations/*     Chat conversations
/api/v1/messages/*          Messages (send / receive)
/api/v1/subscriptions/*     Plans & user subscription
/api/v1/payments/*          Payment initiation & webhooks
/api/v1/verifications/*     ID verification upload
/api/v1/reports/*           Report / block users
/api/v1/events/*            Community events
/api/v1/notifications/*     Notification listing
/api/v1/admin/*             Admin operations
```

---

### Deployment Strategy

**Frontend Web** (Vercel): Public site + admin panel, environment variables, API URL setup

**Backend API** (DigitalOcean Droplet / Ubuntu 22.04): Express API, MySQL 8.0, Redis, PM2 (API + workers), Nginx, SSL (Let's Encrypt)

**Flutter App**: Google Play Store (Android), Apple App Store (iOS)

**Storage**: Cloudflare R2 (primary) or AWS S3 (fallback)

**WebSocket**: Socket.io on the Express API server

---

## 2. Database Schema

### Entity Relationship Overview

```
users
  ↓
profiles → jathagams
  ↓         ↓
profile_photos   preferences
  ↓
interests → matches → conversations → messages
  ↓
subscriptions → subscription_plans
  ↓
payments
  ↓
verifications
  ↓
reports / blocks
```

---

### Table Schemas

#### 1. users

```sql
CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    phone VARCHAR(20) UNIQUE NOT NULL,
    phone_verified_at TIMESTAMP NULL,
    email VARCHAR(255) UNIQUE NULL,
    role ENUM('user', 'moderator', 'admin', 'super_admin') DEFAULT 'user',
    is_active BOOLEAN DEFAULT TRUE,
    is_banned BOOLEAN DEFAULT FALSE,
    ban_reason TEXT NULL,
    last_seen_at TIMESTAMP NULL,
    free_trial_started_at TIMESTAMP NULL,
    free_trial_ends_at TIMESTAMP NULL,
    free_messages_used_today INT DEFAULT 0,
    free_messages_reset_at DATE NULL,
    remember_token VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_phone (phone),
    INDEX idx_role (role),
    INDEX idx_active (is_active)
);
```

#### 2. profiles

```sql
CREATE TABLE profiles (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,

    -- Basic info
    name_en VARCHAR(255) NOT NULL,
    name_ta VARCHAR(255),
    gender ENUM('male', 'female') NOT NULL,
    date_of_birth DATE NOT NULL,
    age INT GENERATED ALWAYS AS (TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE())) STORED,

    -- Location
    country VARCHAR(100) NOT NULL DEFAULT 'Sri Lanka',
    state_province VARCHAR(100),
    city VARCHAR(100),
    origin_country VARCHAR(100),       -- Where family is originally from
    origin_district VARCHAR(100),

    -- Religion & community
    religion VARCHAR(100) DEFAULT 'Hindu',
    caste VARCHAR(100),
    sub_caste VARCHAR(100),
    caste_no_bar BOOLEAN DEFAULT FALSE, -- User open to all castes

    -- Education & career
    education_level ENUM('high_school','diploma','bachelors','masters','phd','other'),
    education_field VARCHAR(255),
    profession VARCHAR(255),
    employer VARCHAR(255),
    annual_income_lkr DECIMAL(15,2),

    -- Physical
    height_cm INT,
    weight_kg INT,
    body_type VARCHAR(50),
    complexion VARCHAR(50),

    -- Lifestyle
    mother_tongue VARCHAR(100) DEFAULT 'Tamil',
    languages_known JSON,
    diet ENUM('vegetarian','non_vegetarian','eggetarian','vegan'),
    smoking ENUM('no','occasionally','yes'),
    drinking ENUM('no','occasionally','yes'),

    -- Family
    family_type ENUM('nuclear','joint','extended'),
    family_status ENUM('middle_class','upper_middle_class','rich','affluent'),
    father_occupation VARCHAR(255),
    mother_occupation VARCHAR(255),
    siblings_count INT DEFAULT 0,

    -- About
    bio_en TEXT,
    bio_ta TEXT,

    -- Profile status
    is_verified BOOLEAN DEFAULT FALSE,
    is_women_safe_mode BOOLEAN DEFAULT FALSE,
    profile_completion_pct INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    is_hidden BOOLEAN DEFAULT FALSE,   -- User hides profile temporarily

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user (user_id),
    INDEX idx_gender (gender),
    INDEX idx_country (country),
    INDEX idx_age (age),
    INDEX idx_caste (caste),
    FULLTEXT idx_search (name_en, name_ta, bio_en, profession)
);
```

#### 3. profile_photos

```sql
CREATE TABLE profile_photos (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    photo_url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(500),
    is_primary BOOLEAN DEFAULT FALSE,
    display_order INT DEFAULT 0,
    status ENUM('pending','approved','rejected') DEFAULT 'pending',
    rejection_reason VARCHAR(255),
    reviewed_by BIGINT UNSIGNED NULL,
    reviewed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user (user_id),
    INDEX idx_status (status)
);
```

#### 4. jathagams

```sql
CREATE TABLE jathagams (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    birth_star VARCHAR(100),           -- நட்சத்திரம் (e.g. Rohini, Krithigai)
    birth_rasi VARCHAR(100),           -- ராசி (e.g. Mesham, Rishabam)
    lagnam VARCHAR(100),               -- லக்னம்
    birth_time TIME,
    birth_place VARCHAR(255),
    dhosam ENUM('no','chevvai','kethu','raghu','parigaram_done') DEFAULT 'no',
    horoscope_file_url VARCHAR(500),   -- Optional uploaded horoscope PDF/image
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user (user_id)
);
```

#### 5. preferences

```sql
CREATE TABLE preferences (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,

    -- Age
    preferred_age_min INT DEFAULT 18,
    preferred_age_max INT DEFAULT 45,

    -- Location
    preferred_countries JSON,          -- ['Sri Lanka','India','UK']
    preferred_states JSON,

    -- Community
    preferred_castes JSON,             -- null = open to all
    caste_no_bar BOOLEAN DEFAULT FALSE,
    preferred_religions JSON,

    -- Education
    preferred_education_levels JSON,

    -- Physical
    preferred_height_min_cm INT,
    preferred_height_max_cm INT,

    -- Lifestyle
    preferred_diet JSON,
    preferred_smoking ENUM('no','occasionally','both') DEFAULT 'no',
    preferred_drinking ENUM('no','occasionally','both') DEFAULT 'no',

    -- Horoscope
    dhosam_acceptable BOOLEAN DEFAULT TRUE,
    preferred_stars JSON,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user (user_id)
);
```

#### 6. interests

```sql
CREATE TABLE interests (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sender_id BIGINT UNSIGNED NOT NULL,
    receiver_id BIGINT UNSIGNED NOT NULL,
    status ENUM('pending','accepted','declined') DEFAULT 'pending',
    message TEXT NULL,                 -- Optional intro message with interest
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    responded_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_interest (sender_id, receiver_id),
    INDEX idx_receiver (receiver_id),
    INDEX idx_status (status)
);
```

#### 7. matches

```sql
CREATE TABLE matches (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user1_id BIGINT UNSIGNED NOT NULL,
    user2_id BIGINT UNSIGNED NOT NULL,
    compatibility_score DECIMAL(5,2) DEFAULT 0,  -- 0-100 AI score
    matched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user1_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (user2_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_match (user1_id, user2_id),
    INDEX idx_user1 (user1_id),
    INDEX idx_user2 (user2_id)
);
```

#### 8. conversations

```sql
CREATE TABLE conversations (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    match_id BIGINT UNSIGNED NOT NULL,
    user1_id BIGINT UNSIGNED NOT NULL,
    user2_id BIGINT UNSIGNED NOT NULL,
    last_message_at TIMESTAMP NULL,
    last_message_preview VARCHAR(255),
    user1_unread_count INT DEFAULT 0,
    user2_unread_count INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE,
    FOREIGN KEY (user1_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (user2_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user1 (user1_id),
    INDEX idx_user2 (user2_id)
);
```

#### 9. messages

```sql
CREATE TABLE messages (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    conversation_id BIGINT UNSIGNED NOT NULL,
    sender_id BIGINT UNSIGNED NOT NULL,
    message_type ENUM('text','voice','image','system') DEFAULT 'text',
    content TEXT,
    media_url VARCHAR(500),
    duration_seconds INT,              -- For voice messages
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP NULL,
    is_deleted_by_sender BOOLEAN DEFAULT FALSE,
    is_deleted_by_receiver BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_conversation (conversation_id),
    INDEX idx_sender (sender_id),
    INDEX idx_created (created_at)
);
```

#### 10. subscription_plans

```sql
CREATE TABLE subscription_plans (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    name_ta VARCHAR(100),
    slug VARCHAR(100) UNIQUE NOT NULL,
    duration_days INT NOT NULL,
    price_lkr DECIMAL(10,2),
    price_inr DECIMAL(10,2),
    price_usd DECIMAL(10,2),
    features JSON,                     -- {"unlimited_chat":true,"video_calls":true,"boost":true}
    is_featured BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    display_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO subscription_plans (name, name_ta, slug, duration_days, price_lkr, price_inr, price_usd, features, is_featured, display_order) VALUES
('Free Trial',  'இலவச சோதனை',  'free_trial',  7,    0,      0,     0,    '{"unlimited_chat":true,"video_calls":false,"boost":false,"see_who_liked":false}', FALSE, 0),
('Basic',       'அடிப்படை',     'basic',       30,   1500,   500,   5,    '{"unlimited_chat":true,"video_calls":false,"boost":false,"see_who_liked":false}', FALSE, 1),
('Premium',     'பிரீமியம்',    'premium',     30,   3000,   999,   10,   '{"unlimited_chat":true,"video_calls":true,"boost":true,"see_who_liked":true}',   TRUE,  2),
('Premium 3M',  'பிரீமியம் 3மாதம்','premium_3m',90,  7500,   2499,  24,   '{"unlimited_chat":true,"video_calls":true,"boost":true,"see_who_liked":true}',   FALSE, 3);
```

#### 11. subscriptions

```sql
CREATE TABLE subscriptions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    plan_id BIGINT UNSIGNED NOT NULL,
    starts_at TIMESTAMP NOT NULL,
    ends_at TIMESTAMP NOT NULL,
    is_trial BOOLEAN DEFAULT FALSE,
    status ENUM('active','expired','cancelled') DEFAULT 'active',
    cancelled_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (plan_id) REFERENCES subscription_plans(id),
    INDEX idx_user (user_id),
    INDEX idx_status (status),
    INDEX idx_ends_at (ends_at)
);
```

#### 12. payments

```sql
CREATE TABLE payments (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    plan_id BIGINT UNSIGNED NOT NULL,
    subscription_id BIGINT UNSIGNED NULL,
    gateway ENUM('razorpay','stripe') NOT NULL,
    gateway_order_id VARCHAR(255),
    gateway_payment_id VARCHAR(255),
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'LKR',
    status ENUM('pending','completed','failed','refunded') DEFAULT 'pending',
    gateway_response JSON,
    paid_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (plan_id) REFERENCES subscription_plans(id),
    INDEX idx_user (user_id),
    INDEX idx_status (status),
    INDEX idx_gateway_payment (gateway_payment_id)
);
```

#### 13. verifications

```sql
CREATE TABLE verifications (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    id_type ENUM('nic','passport','driving_license') NOT NULL,
    id_front_url VARCHAR(500) NOT NULL,
    id_back_url VARCHAR(500),
    selfie_url VARCHAR(500) NOT NULL,
    status ENUM('pending','approved','rejected') DEFAULT 'pending',
    rejection_reason TEXT,
    reviewed_by BIGINT UNSIGNED NULL,
    reviewed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user (user_id),
    INDEX idx_status (status)
);
```

#### 14. reports

```sql
CREATE TABLE reports (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reporter_id BIGINT UNSIGNED NOT NULL,
    reported_id BIGINT UNSIGNED NOT NULL,
    reason ENUM('fake_profile','inappropriate_photo','harassment','spam','scam','other') NOT NULL,
    description TEXT,
    status ENUM('pending','reviewed','action_taken','dismissed') DEFAULT 'pending',
    action_taken VARCHAR(255),
    reviewed_by BIGINT UNSIGNED NULL,
    reviewed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (reporter_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (reported_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_reported (reported_id),
    INDEX idx_status (status)
);
```

#### 15. blocks

```sql
CREATE TABLE blocks (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    blocker_id BIGINT UNSIGNED NOT NULL,
    blocked_id BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (blocker_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (blocked_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_block (blocker_id, blocked_id),
    INDEX idx_blocker (blocker_id),
    INDEX idx_blocked (blocked_id)
);
```

#### 16. events

```sql
CREATE TABLE events (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title_en VARCHAR(255) NOT NULL,
    title_ta VARCHAR(255),
    description_en TEXT,
    description_ta TEXT,
    event_type ENUM('virtual_speed_dating','community_meetup','webinar','other') NOT NULL,
    banner_url VARCHAR(500),
    event_date TIMESTAMP NOT NULL,
    registration_deadline TIMESTAMP,
    location VARCHAR(255),
    meeting_link VARCHAR(500),
    max_attendees INT,
    registered_count INT DEFAULT 0,
    ticket_price_lkr DECIMAL(10,2) DEFAULT 0,
    is_free BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_by BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_event_date (event_date),
    INDEX idx_active (is_active)
);
```

#### 17. settings

```sql
CREATE TABLE settings (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    key VARCHAR(255) UNIQUE NOT NULL,
    value TEXT,
    type ENUM('string','integer','boolean','json') DEFAULT 'string',
    description VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_key (key)
);

INSERT INTO settings (key, value, type, description) VALUES
('free_trial_days',         '7',                              'integer', 'Number of days for free trial'),
('free_messages_per_day',   '5',                              'integer', 'Free messages per day after trial'),
('max_photos_per_profile',  '6',                              'integer', 'Maximum photos a user can upload'),
('min_age',                 '18',                             'integer', 'Minimum registration age'),
('app_name_en',             'Yaro0',                     'string',  'App name in English'),
('app_name_ta',             'தமிழ் இணைவு',                   'string',  'App name in Tamil'),
('support_whatsapp',        '94712341017',                    'string',  'WhatsApp support number'),
('maintenance_mode',        'false',                          'boolean', 'Enable maintenance mode'),
('video_call_duration_min', '10',                             'integer', 'Max video call duration in minutes (free)'),
('countries_supported',     '["LK","IN","GB","CA","MY","SG","AE","AU"]', 'json', 'Supported countries');
```

---

## 3. API Documentation

### Base URL

```
Production:  https://api.yaro0.com/api/v1
Staging:     https://api-staging.yaro0.com/api/v1
Local:       http://localhost:8000/api/v1
```

---

### Authentication Endpoints

#### Send OTP
```
POST /auth/otp/send
```
**Request:**
```json
{ "phone": "+94712341017", "country_code": "LK" }
```
**Response:**
```json
{ "success": true, "message": "OTP sent successfully", "expires_in": 300 }
```

#### Verify OTP & Login/Register
```
POST /auth/otp/verify
```
**Request:**
```json
{ "phone": "+94712341017", "otp": "123456" }
```
**Response:**
```json
{
  "success": true,
  "token": "1|abc123...",
  "user": { "id": 1, "phone": "+94712341017", "is_new_user": true },
  "free_trial_active": true,
  "free_trial_ends_at": "2025-06-22T00:00:00Z"
}
```

#### Logout
```
POST /auth/logout
Headers: Authorization: Bearer {token}
```

---

### Profile Endpoints

#### Create / Update Profile
```
POST   /profile        (create)
PUT    /profile        (update)
GET    /profile        (get own profile)
GET    /profile/{id}   (get another user's profile — auth required)
```

**Request Body (Create/Update):**
```json
{
  "name_en": "Arun Kumar",
  "name_ta": "அருண் குமார்",
  "gender": "male",
  "date_of_birth": "1995-06-15",
  "country": "Sri Lanka",
  "city": "Colombo",
  "origin_district": "Jaffna",
  "religion": "Hindu",
  "caste": "Vellalar",
  "caste_no_bar": false,
  "education_level": "bachelors",
  "education_field": "Computer Science",
  "profession": "Software Engineer",
  "height_cm": 172,
  "bio_en": "Looking for a life partner...",
  "bio_ta": "வாழ்க்கைத் துணையை தேடுகிறேன்..."
}
```

#### Update Preferences
```
PUT /profile/preferences
```
```json
{
  "preferred_age_min": 22,
  "preferred_age_max": 32,
  "preferred_countries": ["Sri Lanka", "India"],
  "caste_no_bar": true,
  "preferred_height_min_cm": 155
}
```

#### Update Jathagam
```
PUT /profile/jathagam
```
```json
{
  "birth_star": "Rohini",
  "birth_rasi": "Rishabam",
  "lagnam": "Mesham",
  "birth_time": "06:30:00",
  "birth_place": "Jaffna",
  "dhosam": "no"
}
```

---

### Photos Endpoints

#### Upload Photo
```
POST /photos
Content-Type: multipart/form-data
Body: { "photo": <file>, "is_primary": true }
```
**Response:**
```json
{
  "success": true,
  "photo": {
    "id": 5,
    "photo_url": "https://cdn.yaro0.com/photos/abc123.jpg",
    "status": "pending",
    "message": "Photo submitted for review"
  }
}
```

#### Delete Photo
```
DELETE /photos/{id}
```

#### Reorder Photos
```
PUT /photos/reorder
Body: { "order": [3, 1, 5, 2] }
```

---

### Matches Endpoints

#### Get Match Suggestions
```
GET /matches/suggestions?page=1&per_page=10
```
**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 12,
      "name_en": "Priya S",
      "age": 26,
      "city": "Colombo",
      "profession": "Doctor",
      "compatibility_score": 87.5,
      "primary_photo": "https://cdn.yaro0.com/photos/...",
      "is_verified": true,
      "is_online": false
    }
  ],
  "meta": { "current_page": 1, "total": 48 }
}
```

#### Search Profiles
```
GET /matches/search?gender=female&age_min=22&age_max=30&country=Sri+Lanka&caste=Vellalar&page=1
```

---

### Interests Endpoints

#### Send Interest
```
POST /interests
Body: { "receiver_id": 12, "message": "Hi, I found your profile interesting." }
```

#### Respond to Interest
```
PUT /interests/{id}
Body: { "status": "accepted" }   or   { "status": "declined" }
```

#### Get Received Interests
```
GET /interests/received?status=pending
```

#### Get Sent Interests
```
GET /interests/sent
```

---

### Conversations & Messages Endpoints

#### Get All Conversations
```
GET /conversations
```

#### Get Messages in Conversation
```
GET /conversations/{id}/messages?page=1
```

#### Send Message
```
POST /conversations/{id}/messages
Body: { "message_type": "text", "content": "Hello!" }
```

#### Send Voice Message
```
POST /conversations/{id}/messages
Content-Type: multipart/form-data
Body: { "message_type": "voice", "media": <audio_file>, "duration_seconds": 12 }
```

#### Mark Conversation as Read
```
PUT /conversations/{id}/read
```

---

### Subscriptions Endpoints

#### Get Plans
```
GET /subscriptions/plans
```

#### Get Active Subscription
```
GET /subscriptions/current
```

#### Initiate Payment
```
POST /subscriptions/checkout
Body: { "plan_id": 2, "gateway": "razorpay" }
```
**Response (Razorpay):**
```json
{
  "success": true,
  "gateway": "razorpay",
  "order_id": "order_abc123",
  "amount": 300000,
  "currency": "LKR",
  "key": "rzp_live_xxxx"
}
```

#### Payment Webhook (Razorpay)
```
POST /payments/webhook/razorpay
```

#### Payment Webhook (Stripe)
```
POST /payments/webhook/stripe
```

---

### Verifications Endpoints

#### Submit ID Verification
```
POST /verifications
Content-Type: multipart/form-data
Body: { "id_type": "nic", "id_front": <file>, "id_back": <file>, "selfie": <file> }
```

#### Get Verification Status
```
GET /verifications/status
```

---

### Reports & Blocks Endpoints

#### Report User
```
POST /reports
Body: { "reported_id": 45, "reason": "fake_profile", "description": "This profile seems fake." }
```

#### Block User
```
POST /blocks
Body: { "blocked_id": 45 }
```

#### Unblock User
```
DELETE /blocks/{blocked_id}
```

---

### Events Endpoints

#### Get Events
```
GET /events?upcoming=true
```

#### Get Event Detail
```
GET /events/{id}
```

---

### Notifications Endpoints

#### Get Notifications
```
GET /notifications?page=1
```

#### Mark as Read
```
PUT /notifications/{id}/read
```

#### Mark All as Read
```
PUT /notifications/read-all
```

---

### Admin Endpoints

```
GET    /admin/dashboard                    Analytics summary
GET    /admin/users                        All users (paginated)
GET    /admin/users/{id}                   User detail
PUT    /admin/users/{id}/ban               Ban user
PUT    /admin/users/{id}/activate          Activate user

GET    /admin/photos/pending               Photo moderation queue
PUT    /admin/photos/{id}/approve          Approve photo
PUT    /admin/photos/{id}/reject           Reject photo (+ reason)

GET    /admin/verifications/pending        ID verification queue
PUT    /admin/verifications/{id}/approve   Approve verification
PUT    /admin/verifications/{id}/reject    Reject verification

GET    /admin/reports                      All reports
PUT    /admin/reports/{id}/action          Take action on report

GET    /admin/subscriptions                All subscriptions
GET    /admin/payments                     All payments

POST   /admin/notifications/broadcast      Broadcast push to all users

GET    /admin/events                       Events management
POST   /admin/events                       Create event
PUT    /admin/events/{id}                  Update event
DELETE /admin/events/{id}                  Delete event

GET    /admin/settings                     All settings
PUT    /admin/settings                     Update settings
```

---

## 4. Express Backend Setup

### Requirements

- Node.js 20+
- npm or pnpm
- MySQL 8.0+
- Redis 7+
- Cloudflare R2 / AWS S3 bucket for media storage

### Installation

```bash
cd backend
npm init -y
npm install express cors helmet morgan dotenv jsonwebtoken bcryptjs zod multer socket.io
npm install @prisma/client mysql2 ioredis bullmq
npm install twilio razorpay stripe firebase-admin aws-sdk uuid
npm install -D typescript tsx nodemon prisma eslint prettier
npm install -D @types/express @types/cors @types/morgan @types/jsonwebtoken @types/bcryptjs @types/multer @types/node
npx tsc --init
npx prisma init
```

### `.env` Configuration

```env
NODE_ENV=production
PORT=8000
API_URL=https://api.yaro0.com
FRONTEND_URL=https://yaro0.com
ADMIN_URL=https://admin.yaro0.com

# Database
DATABASE_URL="mysql://yaro0_user:YOUR_DB_PASSWORD@127.0.0.1:3306/yaro0_db"

# Redis
REDIS_URL="redis://127.0.0.1:6379"

# Auth
JWT_SECRET=YOUR_LONG_RANDOM_SECRET
JWT_EXPIRES_IN=30d
OTP_EXPIRES_SECONDS=300

# Storage (Cloudflare R2 / S3 compatible)
S3_ACCESS_KEY_ID=YOUR_R2_ACCESS_KEY
S3_SECRET_ACCESS_KEY=YOUR_R2_SECRET_KEY
S3_REGION=auto
S3_BUCKET=yaro0-media
S3_ENDPOINT=https://YOUR_ACCOUNT_ID.r2.cloudflarestorage.com
CDN_URL=https://cdn.yaro0.com

# SMS OTP
TWILIO_SID=YOUR_TWILIO_SID
TWILIO_TOKEN=YOUR_TWILIO_TOKEN
TWILIO_FROM=+1XXXXXXXXXX
MSG91_AUTH_KEY=YOUR_MSG91_AUTH_KEY

# Payments
RAZORPAY_KEY=rzp_live_XXXXXXXXXX
RAZORPAY_SECRET=YOUR_RAZORPAY_SECRET
STRIPE_KEY=pk_live_XXXXXXXXXX
STRIPE_SECRET=sk_live_XXXXXXXXXX
STRIPE_WEBHOOK_SECRET=whsec_XXXXXXXXXX

# Firebase Push Notifications
FIREBASE_PROJECT_ID=YOUR_FIREBASE_PROJECT_ID
FIREBASE_CLIENT_EMAIL=YOUR_FIREBASE_CLIENT_EMAIL
FIREBASE_PRIVATE_KEY="YOUR_FIREBASE_PRIVATE_KEY"

# Agora Video Calls
AGORA_APP_ID=YOUR_AGORA_APP_ID
AGORA_APP_CERTIFICATE=YOUR_AGORA_CERTIFICATE

# Mail
SMTP_HOST=smtp.mailgun.org
SMTP_PORT=587
SMTP_USER=YOUR_MAILGUN_USER
SMTP_PASSWORD=YOUR_MAILGUN_PASSWORD
MAIL_FROM_ADDRESS=hello@yaro0.com
MAIL_FROM_NAME="Yaro0"
```

### Project Structure

```
backend/
├── prisma/
│   ├── schema.prisma
│   └── seed.ts
├── src/
│   ├── app.ts
│   ├── server.ts
│   ├── config/
│   │   ├── env.ts
│   │   ├── prisma.ts
│   │   ├── redis.ts
│   │   └── storage.ts
│   ├── routes/
│   │   ├── index.ts
│   │   ├── auth.routes.ts
│   │   ├── profile.routes.ts
│   │   ├── photo.routes.ts
│   │   ├── match.routes.ts
│   │   ├── interest.routes.ts
│   │   ├── conversation.routes.ts
│   │   ├── subscription.routes.ts
│   │   ├── payment.routes.ts
│   │   ├── verification.routes.ts
│   │   ├── report.routes.ts
│   │   ├── event.routes.ts
│   │   ├── notification.routes.ts
│   │   └── admin.routes.ts
│   ├── controllers/
│   │   ├── auth.controller.ts
│   │   ├── profile.controller.ts
│   │   ├── photo.controller.ts
│   │   ├── jathagam.controller.ts
│   │   ├── preference.controller.ts
│   │   ├── match.controller.ts
│   │   ├── interest.controller.ts
│   │   ├── conversation.controller.ts
│   │   ├── message.controller.ts
│   │   ├── subscription.controller.ts
│   │   ├── payment.controller.ts
│   │   ├── verification.controller.ts
│   │   ├── report.controller.ts
│   │   ├── block.controller.ts
│   │   ├── event.controller.ts
│   │   ├── notification.controller.ts
│   │   └── admin/
│   │       ├── dashboard.controller.ts
│   │       ├── user.controller.ts
│   │       ├── photo-moderation.controller.ts
│   │       ├── verification-moderation.controller.ts
│   │       ├── report.controller.ts
│   │       ├── subscription.controller.ts
│   │       ├── event.controller.ts
│   │       └── setting.controller.ts
│   ├── middleware/
│   │   ├── auth.middleware.ts
│   │   ├── admin.middleware.ts
│   │   ├── subscription.middleware.ts
│   │   ├── validate.middleware.ts
│   │   └── error.middleware.ts
│   ├── validators/
│   │   ├── auth.validator.ts
│   │   ├── profile.validator.ts
│   │   └── payment.validator.ts
│   ├── services/
│   │   ├── otp.service.ts
│   │   ├── matching.service.ts
│   │   ├── notification.service.ts
│   │   ├── payment.service.ts
│   │   ├── storage.service.ts
│   │   └── agora.service.ts
│   ├── repositories/
│   ├── jobs/
│   │   ├── queues.ts
│   │   ├── send-otp.job.ts
│   │   ├── send-push-notification.job.ts
│   │   └── compute-match-scores.job.ts
│   ├── events/
│   │   ├── socket.ts
│   │   └── chat.events.ts
│   ├── types/
│   └── utils/
├── tests/
├── package.json
└── tsconfig.json
```

### API App Setup (`src/app.ts`)

```ts
import cors from "cors";
import express from "express";
import helmet from "helmet";
import morgan from "morgan";
import { apiRouter } from "./routes";
import { errorMiddleware } from "./middleware/error.middleware";

export const app = express();

app.use(helmet());
app.use(cors({ origin: [process.env.FRONTEND_URL!, process.env.ADMIN_URL!], credentials: true }));
app.use(express.json({ limit: "2mb" }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan("combined"));

app.use("/api/v1", apiRouter);
app.use(errorMiddleware);
```

### Routes (`src/routes/index.ts`)

```ts
import { Router } from "express";
import { authRouter } from "./auth.routes";
import { profileRouter } from "./profile.routes";
import { photoRouter } from "./photo.routes";
import { matchRouter } from "./match.routes";
import { interestRouter } from "./interest.routes";
import { conversationRouter } from "./conversation.routes";
import { subscriptionRouter } from "./subscription.routes";
import { paymentRouter } from "./payment.routes";
import { verificationRouter } from "./verification.routes";
import { reportRouter } from "./report.routes";
import { eventRouter } from "./event.routes";
import { notificationRouter } from "./notification.routes";
import { adminRouter } from "./admin.routes";
import { authMiddleware } from "../middleware/auth.middleware";
import { adminMiddleware } from "../middleware/admin.middleware";

export const apiRouter = Router();

apiRouter.get("/health", (_req, res) => res.json({ success: true, service: "yaro0-api" }));
apiRouter.use("/auth", authRouter);
apiRouter.use("/events", eventRouter);
apiRouter.use("/payments/webhook", paymentRouter);

apiRouter.use(authMiddleware);
apiRouter.use("/profile", profileRouter);
apiRouter.use("/photos", photoRouter);
apiRouter.use("/matches", matchRouter);
apiRouter.use("/interests", interestRouter);
apiRouter.use("/conversations", conversationRouter);
apiRouter.use("/subscriptions", subscriptionRouter);
apiRouter.use("/verifications", verificationRouter);
apiRouter.use("/reports", reportRouter);
apiRouter.use("/notifications", notificationRouter);

apiRouter.use("/admin", adminMiddleware, adminRouter);
```

### Admin Middleware (`src/middleware/admin.middleware.ts`)

```ts
import type { NextFunction, Request, Response } from "express";

export function adminMiddleware(req: Request, res: Response, next: NextFunction) {
  const role = req.user?.role;

  if (!["admin", "super_admin", "moderator"].includes(role)) {
    return res.status(403).json({
      success: false,
      message: "Unauthorized. Admin access required.",
    });
  }

  next();
}
```

### Package Scripts

```json
{
  "scripts": {
    "dev": "tsx watch src/server.ts",
    "build": "tsc",
    "start": "node dist/server.js",
    "worker": "tsx src/jobs/queues.ts",
    "prisma:generate": "prisma generate",
    "prisma:migrate": "prisma migrate dev",
    "prisma:deploy": "prisma migrate deploy",
    "prisma:seed": "tsx prisma/seed.ts"
  }
}
```

### Commands

```bash
# Development API
npm run dev

# Generate Prisma client
npm run prisma:generate

# Migrations & seeding
npm run prisma:migrate
npm run prisma:seed

# Background workers
npm run worker

# Production build
npm run build
npm start
```

---
## 5. Next.js Frontend Setup

### Project Structure

```
frontend/
├── public-site/
│   └── src/
│       ├── app/
│       │   ├── (auth)/
│       │   │   ├── login/page.tsx
│       │   │   └── register/page.tsx
│       │   ├── (main)/
│       │   │   ├── layout.tsx
│       │   │   ├── discover/page.tsx
│       │   │   ├── matches/page.tsx
│       │   │   ├── messages/
│       │   │   │   ├── page.tsx
│       │   │   │   └── [id]/page.tsx
│       │   │   ├── interests/page.tsx
│       │   │   ├── events/
│       │   │   │   ├── page.tsx
│       │   │   │   └── [id]/page.tsx
│       │   │   ├── profile/
│       │   │   │   ├── page.tsx
│       │   │   │   ├── edit/page.tsx
│       │   │   │   └── photos/page.tsx
│       │   │   └── subscription/page.tsx
│       │   └── layout.tsx
│       ├── components/
│       │   ├── layout/         # Navbar, BottomNav, Sidebar
│       │   ├── profile/        # ProfileCard, ProfileDetail, PhotoGallery
│       │   ├── discover/       # SwipeCard, FilterDrawer
│       │   ├── messages/       # ChatWindow, MessageBubble, VoiceMessage
│       │   ├── subscription/   # PlanCard, PaymentModal
│       │   └── ui/             # Button, Input, Modal, Badge, Avatar
│       ├── lib/                # api.ts, socket.ts, utils.ts, constants.ts
│       ├── store/              # useAuthStore, useChatStore, useUIStore
│       └── types/              # user.ts, profile.ts, message.ts, subscription.ts
│
└── admin-panel/
    └── src/
        ├── app/
        │   ├── (auth)/login/page.tsx
        │   └── (dashboard)/
        │       ├── layout.tsx
        │       ├── dashboard/page.tsx
        │       ├── users/
        │       ├── photos/
        │       ├── verifications/
        │       ├── reports/
        │       ├── subscriptions/
        │       ├── events/
        │       └── settings/
        └── components/
            ├── layout/         # AdminSidebar, AdminHeader
            ├── dashboard/      # StatsCard, RecentSignups, RevenueChart
            ├── moderation/     # PhotoModerationCard, VerificationCard, ReportCard
            └── users/          # UserTable, UserDetail, BanModal
```

### Installation

```bash
# Public site
npx create-next-app@latest public-site --typescript --tailwind --app
cd public-site
npm install zustand @tanstack/react-query axios framer-motion lucide-react react-hot-toast date-fns socket.io-client
npx shadcn-ui@latest init
npx shadcn-ui@latest add button input card dialog select badge separator avatar tabs

# Admin panel
npx create-next-app@latest admin-panel --typescript --tailwind --app
cd admin-panel
npm install zustand @tanstack/react-query axios lucide-react react-hot-toast recharts date-fns
npx shadcn-ui@latest init
npx shadcn-ui@latest add button input card dialog select badge table tabs
```

### Configuration

#### `next.config.js`

```js
/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    domains: ['api.yaro0.com', 'cdn.yaro0.com'],
  },
}
module.exports = nextConfig
```

#### `.env.local` — Public Site

```env
NEXT_PUBLIC_API_URL=https://api.yaro0.com/api/v1
NEXT_PUBLIC_SITE_URL=https://yaro0.com
NEXT_PUBLIC_SOCKET_URL=https://api.yaro0.com
NEXT_PUBLIC_RAZORPAY_KEY=rzp_live_XXXXXXXXXX
NEXT_PUBLIC_AGORA_APP_ID=YOUR_AGORA_APP_ID
```

#### `.env.local` — Admin Panel

```env
NEXT_PUBLIC_API_URL=https://api.yaro0.com/api/v1
NEXT_PUBLIC_SITE_URL=https://admin.yaro0.com
```

#### `tailwind.config.ts`

```ts
import type { Config } from 'tailwindcss'

const config: Config = {
  content: ['./src/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#B91C1C',     // Deep Tamil red
          50:  '#FEF2F2',
          100: '#FEE2E2',
          600: '#DC2626',
          700: '#B91C1C',
          900: '#7F1D1D',
        },
        gold: {
          DEFAULT: '#D97706',
          500: '#D97706',
          600: '#B45309',
        }
      },
      fontFamily: {
        sans:  ['var(--font-inter)'],
        tamil: ['var(--font-noto-sans-tamil)'],
      },
    },
  },
  plugins: [],
}
export default config
```

### API Client (`lib/api.ts`)

```ts
import axios, { AxiosInstance, AxiosRequestConfig } from 'axios';

class ApiClient {
  private client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: process.env.NEXT_PUBLIC_API_URL,
      headers: { 'Content-Type': 'application/json' },
    });

    this.client.interceptors.request.use((config) => {
      const token = localStorage.getItem('token');
      if (token) config.headers.Authorization = `Bearer ${token}`;
      return config;
    });

    this.client.interceptors.response.use(
      (response) => response.data,
      (error) => {
        if (error.response?.status === 401) {
          localStorage.removeItem('token');
          window.location.href = '/login';
        }
        return Promise.reject(error);
      }
    );
  }

  get<T>(url: string, config?: AxiosRequestConfig): Promise<T>    { return this.client.get(url, config); }
  post<T>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T>  { return this.client.post(url, data, config); }
  put<T>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T>   { return this.client.put(url, data, config); }
  delete<T>(url: string, config?: AxiosRequestConfig): Promise<T> { return this.client.delete(url, config); }
}

export const api = new ApiClient();

export const authApi = {
  sendOtp:   (data: { phone: string; country_code: string }) => api.post('/auth/otp/send', data),
  verifyOtp: (data: { phone: string; otp: string })          => api.post('/auth/otp/verify', data),
  logout:    ()                                               => api.post('/auth/logout'),
};

export const profileApi = {
  get:               ()            => api.get('/profile'),
  getUser:           (id: number)  => api.get(`/profile/${id}`),
  create:            (data: any)   => api.post('/profile', data),
  update:            (data: any)   => api.put('/profile', data),
  updateJathagam:    (data: any)   => api.put('/profile/jathagam', data),
  updatePreferences: (data: any)   => api.put('/profile/preferences', data),
};

export const matchApi = {
  suggestions: (params?: any) => api.get('/matches/suggestions', { params }),
  search:      (params?: any) => api.get('/matches/search', { params }),
};

export const interestApi = {
  received: (params?: any) => api.get('/interests/received', { params }),
  sent:     ()             => api.get('/interests/sent'),
  send:     (data: any)    => api.post('/interests', data),
  respond:  (id: number, status: 'accepted' | 'declined') => api.put(`/interests/${id}`, { status }),
};

export const conversationApi = {
  getAll:    ()                          => api.get('/conversations'),
  messages:  (id: number, params?: any) => api.get(`/conversations/${id}/messages`, { params }),
  send:      (id: number, data: any)    => api.post(`/conversations/${id}/messages`, data),
  markRead:  (id: number)               => api.put(`/conversations/${id}/read`),
};

export const subscriptionApi = {
  plans:    ()           => api.get('/subscriptions/plans'),
  current:  ()           => api.get('/subscriptions/current'),
  checkout: (data: any)  => api.post('/subscriptions/checkout', data),
};
```

### Auth Store (`store/useAuthStore.ts`)

```ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface User {
  id: number;
  phone: string;
  role: string;
  free_trial_active: boolean;
  free_trial_ends_at: string | null;
}

interface AuthStore {
  token: string | null;
  user: User | null;
  setAuth:   (token: string, user: User) => void;
  clearAuth: () => void;
  isLoggedIn: () => boolean;
}

export const useAuthStore = create<AuthStore>()(
  persist(
    (set, get) => ({
      token: null,
      user:  null,
      setAuth:   (token, user) => set({ token, user }),
      clearAuth: ()            => set({ token: null, user: null }),
      isLoggedIn: ()           => !!get().token,
    }),
    { name: 'auth-storage' }
  )
);
```

### Running & Deployment

```bash
# Development
cd public-site  && npm run dev   # http://localhost:3000
cd admin-panel  && npm run dev   # http://localhost:3001

# Production build
npm run build && npm start

# Deploy to Vercel
npm i -g vercel
vercel  # run inside each project folder
```

---

## 6. Flutter App Setup

### Requirements

- Flutter 3.19+
- Dart 3.x
- Android Studio / Xcode
- Firebase project (for push notifications)

### Installation

```bash
flutter create yaro0_app --org com.yaro0 --platforms=android,ios
cd yaro0_app
```

### `pubspec.yaml` Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_bloc: ^8.1.5
  equatable: ^2.0.5

  # HTTP
  dio: ^5.4.3
  pretty_dio_logger: ^1.3.1

  # Storage
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.3

  # Navigation
  go_router: ^13.2.0

  # UI
  cached_network_image: ^3.3.1
  image_picker: ^1.1.2
  photo_view: ^0.14.0
  shimmer: ^3.0.0
  lottie: ^3.1.0
  country_picker: ^2.0.24
  intl_phone_field: ^3.2.0

  # Real-time
  socket_io_client: ^2.0.3        # Socket.io realtime chat

  # Video calls
  agora_rtc_engine: ^6.3.2

  # Push notifications
  firebase_core: ^2.27.0
  firebase_messaging: ^14.7.20
  flutter_local_notifications: ^17.1.2

  # Payments
  razorpay_flutter: ^1.3.8

  # Media
  file_picker: ^8.0.3
  flutter_sound: ^9.2.13     # Voice messages
  permission_handler: ^11.3.1

  # Utilities
  intl: ^0.19.0
  timeago: ^3.6.1
  uuid: ^4.4.0
  url_launcher: ^6.2.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.9
  json_serializable: ^6.8.0
  flutter_gen_runner: ^5.4.0
```

### Project Structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── router.dart
├── core/
│   ├── api/
│   │   ├── api_client.dart
│   │   ├── api_endpoints.dart
│   │   └── interceptors/
│   │       ├── auth_interceptor.dart
│   │       └── error_interceptor.dart
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── colors.dart
│   ├── services/
│   │   ├── storage_service.dart
│   │   ├── push_notification_service.dart
│   │   └── socket_service.dart
│   └── utils/
│       ├── validators.dart
│       └── formatters.dart
├── features/
│   ├── auth/
│   │   ├── bloc/
│   │   │   ├── auth_bloc.dart
│   │   │   ├── auth_event.dart
│   │   │   └── auth_state.dart
│   │   ├── data/
│   │   │   └── auth_repository.dart
│   │   └── presentation/
│   │       ├── login_screen.dart
│   │       └── otp_screen.dart
│   ├── profile/
│   │   ├── bloc/
│   │   ├── data/
│   │   └── presentation/
│   │       ├── create_profile_screen.dart
│   │       ├── edit_profile_screen.dart
│   │       └── view_profile_screen.dart
│   ├── discover/
│   │   ├── bloc/
│   │   ├── data/
│   │   └── presentation/
│   │       └── discover_screen.dart
│   ├── messages/
│   │   ├── bloc/
│   │   ├── data/
│   │   └── presentation/
│   │       ├── conversations_screen.dart
│   │       └── chat_screen.dart
│   ├── subscription/
│   │   ├── bloc/
│   │   ├── data/
│   │   └── presentation/
│   │       └── subscription_screen.dart
│   └── video_call/
│       └── presentation/
│           └── video_call_screen.dart
└── shared/
    ├── widgets/
    │   ├── profile_avatar.dart
    │   ├── verified_badge.dart
    │   └── loading_shimmer.dart
    └── models/
        ├── user_model.dart
        ├── profile_model.dart
        └── message_model.dart
```

### API Client (`core/api/api_client.dart`)

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String baseUrl = 'https://api.yaro0.com/api/v1';
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Handle logout
        }
        handler.next(error);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? params})  =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data})                 =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data})                  =>
      _dio.put(path, data: data);

  Future<Response> delete(String path)                               =>
      _dio.delete(path);

  Future<Response> upload(String path, FormData formData)            =>
      _dio.post(path, data: formData,
          options: Options(contentType: 'multipart/form-data'));
}
```

### `.env` Constants (`core/constants/app_constants.dart`)

```dart
class AppConstants {
  static const String apiBaseUrl        = 'https://api.yaro0.com/api/v1';
  static const String cdnBaseUrl        = 'https://cdn.yaro0.com';
  static const String socketUrl         = 'https://api.yaro0.com';
  static const String razorpayKey       = 'rzp_live_XXXXXXXXXX';
  static const String agoraAppId        = 'YOUR_AGORA_APP_ID';
  static const int    freeMessagesPerDay = 5;
}
```

### Running

```bash
# Debug
flutter run

# Production build — Android
flutter build apk --release
flutter build appbundle --release    # For Play Store

# Production build — iOS
flutter build ios --release
```

---

## 7. Production Server Setup

### Server Architecture

```
Internet
    │
[Cloudflare CDN + WAF]
    │
[Nginx Reverse Proxy — api.yaro0.com]
    └── :80 / :443 → Express API + Socket.io (Node.js on 127.0.0.1:8000)

[DigitalOcean Droplet — Ubuntu 22.04 LTS]
    ├── Node.js 20+
    ├── Express + TypeScript API
    ├── PM2 (API process + queue workers)
    ├── MySQL 8.0
    ├── Redis 7.x
    └── Nginx

[Cloudflare R2]                  ← User photos & media
[Vercel]                         ← Next.js public site (yaro0.com)
[Vercel]                         ← Next.js admin panel (admin.yaro0.com)
[Google Play Store / App Store]  ← Flutter app
```

---

### Domain & DNS Configuration

| Record | Name | Value | Purpose |
|--------|------|-------|---------|
| A | `@` | `YOUR_DROPLET_IP` | Main site (or Vercel) |
| A | `api` | `YOUR_DROPLET_IP` | Express API |
| CNAME | `admin` | `cname.vercel-dns.com` | Admin panel |
| CNAME | `cdn` | `YOUR_R2_BUCKET.r2.cloudflarestorage.com` | Media CDN |

---

### Server Provisioning (DigitalOcean Droplet)

**Recommended spec (initial):** 4 vCPU, 8 GB RAM, 160 GB SSD — Basic droplet (~$48/month)

**Scale to:** 8 vCPU / 16 GB RAM once you reach 10,000+ active users

```bash
# 1. Initial server setup
adduser yaro0
usermod -aG sudo yaro0
ufw allow OpenSSH
ufw allow 80
ufw allow 443
ufw enable

# 2. Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# 3. Install MySQL 8.0
apt install -y mysql-server
mysql_secure_installation

mysql -u root -p
CREATE DATABASE yaro0_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'yaro0_user'@'localhost' IDENTIFIED BY 'YOUR_STRONG_PASSWORD';
GRANT ALL PRIVILEGES ON yaro0_db.* TO 'yaro0_user'@'localhost';
FLUSH PRIVILEGES;

# 4. Install Redis
apt install -y redis-server
systemctl enable redis-server

# 5. Install Nginx and Certbot
apt install -y nginx certbot python3-certbot-nginx

# 6. Install PM2 for process management
npm install -g pm2
```

---

### Nginx Configuration

**`/etc/nginx/sites-available/yaro0-api`**

```nginx
server {
    listen 80;
    server_name api.yaro0.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.yaro0.com;

    ssl_certificate     /etc/letsencrypt/live/api.yaro0.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.yaro0.com/privkey.pem;

    client_max_body_size 20M;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Socket.io websocket upgrade
    location /socket.io/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
ln -s /etc/nginx/sites-available/yaro0-api /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# Get SSL certificate
certbot --nginx -d api.yaro0.com
```

---

### Deploy Express API

```bash
cd /var/www
git clone https://github.com/YOUR_USERNAME/yaro0-api.git
cd yaro0-api/backend

npm ci
cp .env.example .env

# Edit .env with production values before running migrations
npm run prisma:generate
npm run prisma:deploy
npm run prisma:seed

npm run build
```

---

### PM2 Configuration

**`ecosystem.config.js`**

```js
module.exports = {
  apps: [
    {
      name: "yaro0-api",
      script: "dist/server.js",
      cwd: "/var/www/yaro0-api/backend",
      instances: 2,
      exec_mode: "cluster",
      env: {
        NODE_ENV: "production",
        PORT: 8000,
      },
    },
    {
      name: "yaro0-worker",
      script: "dist/jobs/queues.js",
      cwd: "/var/www/yaro0-api/backend",
      instances: 1,
      env: {
        NODE_ENV: "production",
      },
    },
  ],
};
```

```bash
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

---

### Cron Jobs

Use cron only for simple scheduled commands. Prefer BullMQ repeatable jobs for recurring app tasks.

```bash
crontab -e -u yaro0
# Optional daily maintenance hook:
0 0 * * * cd /var/www/yaro0-api/backend && npm run jobs:daily >> /var/log/yaro0/daily.log 2>&1
```

Scheduled jobs to implement in BullMQ:

```ts
// src/jobs/schedules.ts
// subscriptions:expire daily
// free-messages:reset daily at 00:00
// matches:compute-scores hourly
```

---

### Production Checklist

```
✅ NODE_ENV=production in .env
✅ JWT_SECRET is long and private
✅ SSL certificate installed (Let's Encrypt auto-renew)
✅ Nginx config tested (nginx -t)
✅ MySQL user has only necessary privileges (not root)
✅ Redis password set in production if publicly reachable
✅ npm run build completed successfully
✅ Prisma migrations deployed with npm run prisma:deploy
✅ PM2 running API and worker processes
✅ PM2 startup configured after reboot
✅ R2/S3 bucket CORS configured for cdn.yaro0.com
✅ Firebase credentials configured through environment variables or secure file mount
✅ Cloudflare WAF enabled
✅ Razorpay webhook URL registered: https://api.yaro0.com/api/v1/payments/webhook/razorpay
✅ Stripe webhook URL registered: https://api.yaro0.com/api/v1/payments/webhook/stripe
✅ Vercel projects connected to GitHub for auto-deploy
✅ Flutter app signed with release keystore
```

---

### Quick Deployment Commands

```bash
# Pull latest changes and re-deploy backend
cd /var/www/yaro0-api/backend
git pull origin main
npm ci
npm run prisma:generate
npm run prisma:deploy
npm run build
pm2 restart yaro0-api yaro0-worker

# Restart Nginx
systemctl reload nginx

# Check processes
pm2 status

# View logs
pm2 logs yaro0-api
pm2 logs yaro0-worker
tail -f /var/log/nginx/error.log
```
