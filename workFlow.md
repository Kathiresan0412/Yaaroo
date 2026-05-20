2. App Overview & Modules
Dating App
├── Public Pages        → Landing, Login, Register
├── Onboarding          → Step-by-step profile setup wizard
├── User App
│   ├── Discovery       → Swipe / Like / Pass
│   ├── Matches         → List of mutual likes
│   ├── Messages        → 1:1 chat with matches
│   ├── Profile         → View & edit own profile
│   └── Settings        → Preferences, privacy, account
└── Admin Portal
    ├── Dashboard       → Stats & KPIs
    ├── Users           → Manage all users
    ├── Reports         → Reported content & users
    ├── Matches         → View match activity
    ├── Content         → Moderation queue
    └── Settings        → App-level configuration


3. Authentication Flow — Register & Login
3.1 Registration Flow
[Landing Page]
      |
      ▼
[Register Page]
  ┌─────────────────────────────────┐
  │  First Name *                   │
  │  Last Name *                    │
  │  Email Address *                │
  │  Password * (min 8 chars)       │
  │  Confirm Password *             │
  │  Date of Birth * (must be 18+)  │
  │  Gender *                       │
  │  [ ] Agree to Terms & Privacy   │
  │  [Sign Up]                      │
  │  ─── or ───                     │
  │  [Continue with Google]         │
  │  [Continue with Facebook]       │
  └─────────────────────────────────┘
      |
      ▼
[Email Verification Sent]
  → User clicks link in email
      |
      ▼
[Email Verified ✓]
      |
      ▼
[Redirect to Onboarding Wizard]
Validation Rules:

Email: valid format, unique in DB
Password: min 8 chars, 1 uppercase, 1 number, 1 special char
Date of Birth: user must be ≥ 18 years old
Gender: Male / Female / Non-binary / Prefer not to say


3.2 Login Flow
[Login Page]
  ┌─────────────────────────────────┐
  │  Email Address *                │
  │  Password *                     │
  │  [ ] Remember me                │
  │  [Login]                        │
  │  Forgot Password?               │
  │  ─── or ───                     │
  │  [Continue with Google]         │
  │  [Continue with Facebook]       │
  └─────────────────────────────────┘
      |
      ├── Success → [Home / Discovery Screen]
      └── Fail    → Show error message

3.3 Forgot Password Flow
[Forgot Password Page]
  → Enter registered email
  → System sends reset link (expires in 15 mins)
  → User clicks link → [Reset Password Page]
  → Enter new password + confirm
  → Redirect to Login

4. User Onboarding Flow
After email verification, new users go through a step-by-step wizard (cannot skip, progress saved at each step).
Step 1: Profile Photos
Step 2: About You (bio, headline)
Step 3: Personal Details (height, education, job, etc.)
Step 4: Lifestyle & Interests
Step 5: Favourites (pets, colours, food, music, etc.)
Step 6: Relationship Goals
Step 7: Discovery Preferences (who to show)
Step 8: Location Permission
         ↓
[Complete! → Home Screen]
Progress bar shown at top throughout wizard.

5. Profile Setup — Full Detail
5.1 Photos
FieldDetailMinimum photos2Maximum photos9Supported formatsJPG, PNG, WEBPMax file size10 MB per photoFirst photoUsed as main display photoPhoto reorderDrag-and-dropPhoto moderationAuto + manual review

5.2 Basic Info
FieldTypeOptions / NotesDisplay NameTextAuto-filled from registrationAgeAuto-calculatedFrom DOB — not editableGenderSelectMale / Female / Non-binary / OtherPronounsSelectHe/Him, She/Her, They/Them, CustomSexual OrientationMulti-selectStraight, Gay, Lesbian, Bisexual, Pansexual, Asexual, OtherHeadline / TaglineText (max 60 chars)e.g. "Adventure seeker ☀️"Bio / About MeTextarea (max 500 chars)Free text descriptionLocationAuto-detect or manualCity + CountryShow LocationToggleShow exact city or keep vague

5.3 Physical Attributes
FieldTypeOptionsHeightNumbercm or ft/in (user selects unit)Body TypeSelectSlim / Athletic / Average / Curvy / Heavy-set / Prefer not to sayEthnicityMulti-selectAsian, Black, Hispanic, Middle Eastern, White, Mixed, Other, Prefer not to sayHair ColourSelectBlack, Brown, Blonde, Red, Grey, White, Bald, Dyed / OtherEye ColourSelectBrown, Blue, Green, Hazel, Grey, Other

5.4 Life & Background
FieldTypeOptionsEducation LevelSelectHigh School, Some College, Bachelor's, Master's, PhD, Vocational, OtherUniversity / SchoolTextOptional — name of institutionJob TitleTexte.g. "Software Engineer"CompanyTextOptionalIndustrySelectTech, Healthcare, Finance, Education, Creative, Hospitality, OtherAnnual IncomeSelectPrefer not to say / ranges (hidden from others by default)ReligionSelectAtheist, Agnostic, Christian, Muslim, Hindu, Buddhist, Jewish, Spiritual, Other, Prefer not to sayPolitical ViewsSelectLiberal, Conservative, Moderate, Apolitical, Prefer not to sayNationalitySelect (searchable)Country listLanguages SpokenMulti-selectLanguage listStar Sign / ZodiacSelectAries–Pisces (auto-fill if DOB given)MBTI PersonalitySelectINFJ, ENFP… (all 16)

5.5 Lifestyle
FieldTypeOptionsSmokingSelectNever / Socially / Regularly / Trying to quitDrinkingSelectNever / Socially / RegularlyDrugsSelectNever / Sometimes / Often / Prefer not to sayExercise / FitnessSelectNever / Rarely / Sometimes / Often / DailyDietSelectNo restrictions / Vegetarian / Vegan / Halal / Kosher / Gluten-free / OtherSleep ScheduleSelectEarly bird / Night owl / VariesLiving SituationSelectAlone / With roommates / With family / With partnerHave ChildrenSelectNo / Yes (living with me) / Yes (not living with me) / Prefer not to sayWant ChildrenSelectYes / No / Maybe / Someday / Not sureHave PetsSelectDog(s) / Cat(s) / Fish / Bird / Rabbit / Reptile / None / OtherWant PetsSelectYes / No / Already have

6. Matching Preferences & Compatibility Fields
6.1 Favourite Items (for Compatibility Matching)
These fields are used in the compatibility algorithm. Users pick favourites and the system uses them to boost or reduce match scores.
🐾 Favourite Pet / Animal

Dog, Cat, Fish, Bird, Rabbit, Hamster, Turtle, Snake, No Pet, Multiple Pets

🎨 Favourite Colour

Red, Orange, Yellow, Green, Blue, Purple, Pink, Black, White, Grey, Multicolour

🍕 Favourite Food / Cuisine

Italian, Chinese, Indian, Japanese, Mexican, Thai, American, Mediterranean, Middle Eastern, Sri Lankan, Korean, French, Seafood, BBQ, Vegetarian/Vegan, Fast Food, Home-cooked

🎵 Favourite Music Genre

Pop, Rock, Hip-Hop / Rap, R&B, Jazz, Classical, Electronic / EDM, Country, Reggae, Latin, K-Pop, Metal, Folk, Indie, Gospel

🎬 Favourite Movie Genre

Action, Romance, Comedy, Thriller, Horror, Sci-Fi, Documentary, Animation, Drama, Fantasy, True Crime

📺 Favourite TV Show Type

Reality TV, Drama Series, Comedy, Anime, True Crime, Sports, Documentary, News, Nature

📚 Favourite Books / Reading

Fiction, Non-Fiction, Romance, Self-Help, Sci-Fi, Biography, Fantasy, Mystery, Thriller, Comics / Manga, I don't read much

🏄 Favourite Hobbies / Activities
Multi-select (pick up to 10):

Hiking, Cooking, Travelling, Photography, Gaming, Reading, Fitness / Gym, Dancing, Swimming, Yoga, Painting, Music / Instruments, Cycling, Sports, Movies, Volunteering, Gardening, DIY / Crafts, Meditation, Shopping, Karaoke, Surfing, Rock Climbing, Wine / Coffee Tasting

🌍 Favourite Travel Destination Type

Beach, Mountains, City, Adventure / Backpacking, Luxury, Road Trips, Cultural, Staycation

☕ Morning Person or Night Person

Morning Bird, Night Owl, Both / Flexible

🗓️ Weekend Activity Preference

Stay home and relax, Go out and socialise, Mix of both, Depends on the week

💬 Communication Style

Texter, Caller, In-person only, Mix of all

❤️ Love Language

Words of Affirmation, Acts of Service, Receiving Gifts, Quality Time, Physical Touch

💍 Relationship Goal

Long-term relationship, Short-term / Casual, Friends first, Friendship only, Not sure yet, Marriage-minded


6.2 Discovery / Matching Preferences
PreferenceTypeDetailShow meSelectMen / Women / EveryoneAge RangeRange slidere.g. 22–35DistanceRange sliderkm or miles, up to 100+Verified profiles onlyToggleOnly show verified usersWith photos onlyToggleRequire profile photoMatch by interestsToggleBoost users with shared hobbiesGlobal modeToggleShow users worldwide (ignore distance)

6.3 Compatibility Score Algorithm (Concept)
Compatibility Score = (Shared Interests × 0.25)
                    + (Same Love Language × 0.15)
                    + (Same Relationship Goal × 0.20)
                    + (Same Lifestyle × 0.15)
                    + (Same Values / Religion × 0.10)
                    + (Same Favourite Genres × 0.10)
                    + (Mutual Liked Hobbies × 0.05)
Score displayed as a % match on the discovery card.

7. Home / Discovery Feed (Swipe Screen)
7.1 Card Layout
Each profile card displays:

Main photo (full card)
Name + Age
Distance away
Match % score
Top 3 shared interests (icons)
Headline / tagline
Expand arrow → full profile preview

7.2 Swipe Actions
ActionGesture / ButtonResultLikeSwipe right / ❤️Sends like; if mutual → Match!Pass / DislikeSwipe left / ✕Moves to next cardSuper LikeSwipe up / ⭐Special highlight; limited per dayBoost🔥 buttonYour profile shown to more people (timed)Undo↩️Undo last swipe (premium feature)
7.3 Match Notification
When two users both like each other:
🎉 It's a Match!
   You and [Name] liked each other.
   [Send a Message]  [Keep Swiping]

8. Match & Messaging System
8.1 Matches Screen

Grid or list view of all mutual matches
Match timestamp shown
Unread message badge
Search matches by name
Archived matches tab

8.2 Chat Screen
FeatureDetailText messagesStandard chatEmoji reactionsReact to messagesGIF supportVia Giphy integrationPhoto sharingSend photos in chatVoice messagesRecord & send audioRead receiptsSeen / DeliveredTyping indicator"... is typing"Message deleteDelete for myself / for bothReport messageFlag inappropriate contentBlock userFrom within chat
8.3 Chat Rules

Messaging only available between mutual matches
If unmatched: chat is hidden but messages saved for report purposes
Message requests: optionally allow non-match messages (premium)


9. Notifications
TriggerTypeMessage ExampleNew matchPush + In-app"You matched with Sarah! 🎉"New messagePush + In-app"Alex: Hey there!"Profile like receivedIn-app (blurred in free plan)"Someone liked you!"Super like receivedPush + In-app"You got a Super Like!"Profile viewIn-app (premium)"3 people viewed your profile today"Boost endedIn-app"Your boost ended. See results."Match expiredIn-app"Your match with Tom expires soon"Verification reminderEmail + In-app"Verify your profile to get more matches"InactivityEmail"You have X new likes waiting!"

10. Settings & Account Management
10.1 Account Settings

Change email
Change password
Linked social accounts (Google / Facebook)
Phone number (optional, for 2FA)
Two-factor authentication toggle
Delete account (with confirmation + 30-day grace period)

10.2 Profile Settings

Edit all profile fields
Manage photos
Boost profile
Verification (selfie + ID)

10.3 Privacy Settings

Who can see my profile: Everyone / Matches only / Nobody (pause mode)
Show distance: Exact / Approximate / Hide
Show active status: On / Off
Read receipts: On / Off
Incognito mode (premium): Browse without being seen

10.4 Notification Settings

Manage push notifications per trigger
Manage email notifications

10.5 Subscription / Premium

Free vs Premium plan feature comparison table
Upgrade CTA
Manage billing
Cancel subscription

10.6 Help & Support

FAQ
Contact support form
Report a bug
Community guidelines


11. Admin Portal — Full Detail
Admin portal is a separate web dashboard accessible at /admin with role-based access.
11.1 Admin Roles
RoleAccess LevelSuper AdminFull access — all modules, settings, rolesModeratorUsers, reports, content moderationSupport AgentView users, respond to tickets, no deleteAnalystRead-only access to stats and reports

11.2 Dashboard (Home)
KPI widgets displayed:

Total registered users
Active users (last 7 / 30 days)
New sign-ups today / this week / this month
Total matches made
Messages sent today
Reports pending review
Verified users count
Premium subscribers count
Revenue (this month vs last month)

Charts:

Daily active users (line chart, last 30 days)
Sign-ups over time (bar chart)
Match rate (%)
Top countries by user count (map or bar)
Gender distribution (pie chart)
Age distribution (histogram)


11.3 User Management
User List Table:
ColumnDetailIDInternal user IDNameDisplay nameEmailRegistered emailAgeCalculatedGenderM/F/OtherLocationCity, CountryStatusActive / Suspended / Banned / DeletedVerified✓ / ✗Premium✓ / ✗JoinedRegistration dateLast ActiveTimestampActionsView / Edit / Suspend / Ban / Delete
Filters: Status, Gender, Age range, Country, Verified, Premium, Date range
User Detail Page:

All profile info and photos
Activity timeline (logins, swipes, messages)
All matches and chats (for moderation)
Reports made by / against user
Subscription history
Manual override: verify badge, give premium, suspend, ban, delete


11.4 Reports & Moderation
Report Queue Table:
ColumnDetailReport IDAuto-generatedReporterUser who reportedReported UserUser being reportedReasonHarassment / Fake profile / Spam / Inappropriate photo / Under 18 / OtherDescriptionFree textStatusPending / Reviewed / Actioned / DismissedDateTimestampActionsReview / Dismiss / Warn User / Suspend / Ban
Moderation Actions available:

Send warning to user
Remove specific photo
Suspend account (1 day / 3 days / 7 days / custom)
Permanent ban
Mark report as false / dismiss
Escalate to Super Admin


11.5 Content Moderation

Photo review queue (new uploads awaiting approval if manual review enabled)
AI-flagged content (nudity, offensive language detection)
Batch approve / reject photos
Flag keywords list (profanity filter management)
Review bio/headline text flagged by system


11.6 Match Analytics

Total matches per day (chart)
Average time to first message after match
Match rate by age group, location, gender
Top matched interests / hobbies
Ghost rate (matched but never messaged)


11.7 Message Monitoring

Search messages by keyword (for safety/compliance)
View flagged/reported messages
Delete specific messages
No mass surveillance — only accessed via report workflow or court order


11.8 Subscription & Revenue

Active subscribers list
Revenue by plan type
Monthly recurring revenue (MRR) chart
Churn rate
Refund requests management
Promo codes — create, view, disable


11.9 Notifications / Broadcasts

Send push notification to all users (or filtered segment)
Send email campaign
Schedule announcements (e.g. new feature launch)
View notification delivery stats


11.10 App Settings (Super Admin Only)
SettingDetailMinimum ageDefault 18Max swipes per day (free)e.g. 20Super likes per day (free)e.g. 1Boost duratione.g. 30 minutesMatch expirye.g. 7 days before unmatching inactive matchesPhoto moderation modeAuto / Manual / BothMaintenance modeEnable/disable app globallyFeature flagsToggle features on/off without deployEmail templatesEdit transactional email templatesTerms & PrivacyUpdate legal documentsSupported countriesEnable/disable regions

11.11 Admin Audit Log
All admin actions are logged:
FieldDetailAdmin userWho performed the actionActione.g. "Banned user #12345"TargetAffected entityTimestampWhen it happenedIP AddressFor security audit

