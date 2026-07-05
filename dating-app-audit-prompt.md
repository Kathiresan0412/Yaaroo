# Dating App Full Audit Prompt

Copy everything below the line and paste it into your AI coding assistant (Claude Code, Cursor, etc.) inside your project folder. It will scan your codebase and produce a `summary.md` report.

---

## PROMPT TO USE

You are auditing a dating app codebase (mobile/web, with chat, image feed, and profile browsing). Go through the entire codebase (frontend + backend) and produce a file called `summary.md`. Do NOT just describe things in general — for every issue, reference the actual file name, function name, and line number where possible.

Organize `summary.md` into these sections, in this order:

### 1. Page-by-Page / Component-by-Component Summary
For every screen and major component (Login, Sign up, Home/Discover feed, Profile view, Chat list, Chat room, Match screen, Settings, etc.):
- What it does
- Which APIs/functions it calls, and in what order
- Any obvious inefficiency (unnecessary re-renders, duplicate API calls, blocking calls, missing loading states)

### 2. Image Loading & Caching Audit
Specifically check:
- Is there any image caching layer (memory + disk cache) implemented, or is every image re-fetched from network each time?
- When a user navigates: Profile A → Profile B → back to Profile A, does the image reload from network or from cache?
- Are images being fetched at full resolution even in small UI elements (thumbnails, avatars)? Is there resizing/compression happening?
- Recommend a concrete caching solution appropriate to the stack (e.g., `react-native-fast-image` / `expo-image` for RN, `Coil`/`Glide` for Android, `Kingfisher`/`SDWebImage` for iOS, browser HTTP cache headers + service worker for web).
- List every screen where this re-fetch bug currently happens.

### 3. API Call Pattern & Progressive Loading Audit
Check whether profile/feed data is fetched as ONE large blocking call (username + photo + bio + preferences + distance + verification, etc. all at once) or split into progressive calls:
- Does the UI wait for the full payload before showing anything?
- Recommend splitting into:
  - Fast, small "preview" payload: username + primary photo + online status (loads first, shown instantly)
  - Secondary payload: bio, interests, additional photos, verification badges (loads after, fills in)
  - Heavy/optional payload: mutual friends, extended stats, etc. (lazy loaded on demand/scroll)
- Identify which current endpoints should be split, and propose new endpoint/service boundaries.
- Flag any N+1 API call patterns (e.g., calling chat list, then calling user details per chat one-by-one instead of batching).

### 4. Response Time & Performance Testing
- List all API endpoints found in the code, and for each: expected payload size, whether it's paginated, whether it can be cached client-side.
- Identify any endpoint doing heavy work synchronously that should be async/background (e.g., match calculation, image processing, notification sending).
- Flag any missing pagination/infinite scroll on lists (feed, chat list, matches).
- Flag any missing debounce/throttle on search, typing indicators, or swipe actions.
- Note where a loading skeleton/shimmer should replace a blank screen or spinner.

### 5. Unit & Functional Test Coverage
- List which functions/components currently HAVE tests and which do NOT.
- For untested critical logic (auth, matching algorithm, chat message send/receive, payment/subscription if any), write starter unit tests.
- For each screen, write a functional test checklist (what to manually or automatically verify): e.g. "Chat room: sending a message updates UI optimistically before server confirms."

### 6. UX/UI Smoothness Checklist
For each screen, check and report on:
- Loading states (skeletons vs spinners vs blank screen)
- Error states (what happens on failed API call — is there a retry, or silent failure?)
- Empty states (no matches yet, no messages yet)
- Animation/transition jank (any layout shift, flicker, or delayed image pop-in)
- Whether navigating back preserves scroll position and previously loaded data (no refetch/reset)

### 7. Security & Vulnerability Audit
Check specifically for a dating app's typical risk areas:
- **Auth**: token storage (is it in plain AsyncStorage/localStorage vs secure storage/keychain?), token expiry/refresh handling, session fixation.
- **Data exposure**: does any API return more user data than the screen needs (e.g., exact GPS coordinates instead of distance, private fields leaking in profile responses)?
- **Image/media security**: are private photos served via public unguessable URLs? Are signed/expiring URLs used? Can one user access another's private media by guessing IDs?
- **Chat security**: are messages transmitted over TLS only, any plaintext storage, is there rate limiting to prevent spam/harassment, can user IDs be enumerated?
- **IDOR checks**: can a user fetch another user's profile/chat data by changing an ID in the request?
- **Input validation**: profile bio, chat messages, image uploads — check for XSS, injection, unrestricted file upload types/sizes.
- **Rate limiting / abuse**: login attempts, swipe/report spam, message flooding.
- **Location privacy**: how precise is location data stored and shared; is there a "safe distance" rounding.
- List each finding with severity (Critical/High/Medium/Low) and a suggested fix.

### 8. Final Prioritized Fix List
At the very end of `summary.md`, output a table:

| # | Issue | File/Location | Severity | Suggested Fix | Effort (S/M/L) |
|---|-------|----------------|----------|----------------|----------------|

Sort by severity first, then by effort (quick wins near the top).

---

**Important instructions for the AI doing this audit:**
- Actually open and read the relevant files before reporting — do not guess or generalize.
- Be specific: name real functions, real files, real line numbers.
- Every issue must include a concrete fix, not just "this could be improved."
- Keep the report scannable — use short bullet points, not long paragraphs.
- If something is already implemented well, say so briefly instead of ignoring it (so we know what NOT to touch).

---
