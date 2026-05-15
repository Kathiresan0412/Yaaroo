# Yaro0 Backend

Express + TypeScript API workspace for authentication, profiles, matching, messaging, subscriptions, moderation, notifications, and admin operations.

Expected main areas:

- `src/app.ts` - Express app setup
- `src/server.ts` - HTTP server entry point
- `src/config/` - environment, database, storage, SMS, payment, and realtime config
- `src/routes/` - versioned API routes
- `src/controllers/` - request handlers
- `src/services/` - business logic
- `src/repositories/` - database access layer
- `src/models/` - domain models or ORM models
- `src/middleware/` - auth, admin, subscription, validation, and error middleware
- `src/validators/` - request validation schemas
- `src/jobs/` - queue/background jobs
- `src/events/` - websocket/realtime events
- `src/utils/` - shared helpers
- `src/types/` - TypeScript shared types
- `prisma/` - database schema, migrations, and seed data if Prisma is used
