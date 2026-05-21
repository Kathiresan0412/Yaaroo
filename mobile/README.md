# Yaro0 Mobile

Flutter workspace for the iOS and Android app.

The app reads the backend URL from `mobile/.env`:

```env
YAARO0_API_URL=https://yaaro-backend.vercel.app
```

Use `mobile/.env.example` as the template. The real `mobile/.env` file is local-only and ignored by git.

You can still override it at run time with `--dart-define` if `.env` is missing:

```sh
flutter run --dart-define=YAARO0_API_URL=http://127.0.0.1:8000
```

For an Android emulator, use `http://10.0.2.2:8000` so the emulator can reach the host machine.

Main areas:

- `lib/app/` - app shell and router
- `lib/core/` - API client, constants, services, utilities
- `lib/features/` - feature modules using Bloc
- `lib/shared/` - reusable widgets and models
