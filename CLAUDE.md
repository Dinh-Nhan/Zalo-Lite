# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Zalo Lite is a Zalo-like chat application with 1-1 and group messaging, built with an ASP.NET Core 8 backend and a Flutter frontend. Real-time communication uses SignalR; data is stored in Firestore; media uploads go through Cloudinary; and Redis is used for caching.

## Commands

### Backend (from `backend/`)

```bash
dotnet restore          # Install packages
dotnet build            # Build
dotnet run              # Run (listens on http://localhost:5244 and https://localhost:7000)
dotnet watch run        # Run with hot reload
```

Backend requires `appsettings.json` with `Firebase.ProjectId`, `Firebase.CredentialsFilePath`, `Redis.ConnectString`, and `Cloudinary` config. The Firebase service account key goes in `backend/FirebaseCredentials/serviceAccountKey.json`.

Swagger UI is available at `https://localhost:7000/swagger` in Development mode.

### Frontend (from `frontend/`)

```bash
flutter pub get         # Install packages
flutter run             # Run on connected device/emulator
flutter build apk       # Build Android APK
flutter analyze         # Lint
```

Frontend requires a `.env` file in `frontend/` with Agora credentials (used for calls). Firebase options are in `frontend/lib/firebase_options.dart`.

## Architecture

### Backend

```
Controllers/ → Services/ → Firestore (via FirebaseService)
                         ↘ Redis (via RedisService)
                         ↘ Cloudinary (via CloudinaryService)
Hubs/ (SignalR)         → ChatHub, FriendHub
Middleware/             → FirebaseAuthMiddleware, GlobalExceptionHandler
```

**Auth flow:** `FirebaseAuthMiddleware` extracts and verifies the Firebase ID token from `Authorization: Bearer <token>`, then stores the decoded `FirebaseToken` in `HttpContext.Items["User"]`. Controllers use `[FirebaseAuthorize]` (a custom `IAuthorizationFilter` in `Utils/FirebaseAuthorizeAttribute.cs`) — not ASP.NET's built-in `[Authorize]`. Endpoints that should be public use `[AllowAnonymous]`.

**Service registration:** Services decorated with `[ScopedService]` are auto-registered via Scrutor's assembly scan in `Program.cs`. `UserService` and `FirebaseService` are registered explicitly. `FirebaseService` is a singleton and is warmed up immediately on startup.

**Error handling:** Throw `AppException(ErrorCode.XYZ)` to return structured error responses. `GlobalExceptionHandler` middleware maps `AppException` → error metadata, `ValidationException` → 422, and unhandled exceptions → 500. All responses use `ApiResponse<T>` with `Success`, `Code`, `Message`, and `Result` fields.

**Error codes** are defined as enum values in `backend/Enums/ErrorCode.cs` with `[ErrorMeta(code, message, httpStatus)]` attributes. Error ranges: 1xxx = auth, 2xxx = user, 3xxx = message, 4xxx = conversation, 5xxx = feed, 9xxx = common.

**DTOs and mapping:** Request DTOs live in `dtos/Request/`, response DTOs in `dtos/Response/`. Mapster handles mapping; configs are in `Mappings/`. FluentValidation validators are in `Validators/` and auto-registered.

**Background service:** `StoryExpirationService` runs as a hosted service to expire story/feed content.

### Frontend

**Routing:** `go_router` with auth-guard redirect logic in `lib/apps/router.dart`. `RouterNotifier` listens to `FirebaseAuth.authStateChanges()` and triggers redirects. Unauthenticated users are sent to `/login`; authenticated users are redirected away from auth routes to `/chat-list`.

**State management:** Mix of `provider` (for `CallProvider`, `FriendProvider`) and `flutter_bloc` (BLoC pattern in feature modules). Feature-specific BLoCs live in `lib/features/<feature>/providers/`.

**API calls:** `DioClient` (`lib/services/dio_client.dart`) is the base HTTP client. `ApiService` wraps it. Feature-specific services extend from there. Base URL is configured in `lib/config/api_config.dart` — uses `http://10.0.2.2:5244` for Android emulator.

**Real-time:** `SignalR` via `signalr_netcore` package. Chat hub at `wss://<host>/hubs/chat`, friend hub at `/hubs/friend`.

**Key features by view:**
- `views/auth/` — Firebase Auth login, OTP, registration flow
- `views/chat/` — chat list, chat detail, conversation screen, group info
- `views/home/` — home shell, splash/load screen
- `features/friends/` — friend requests, friend list (BLoC-based)
- `features/calling/` — Agora RTC video/voice calls

**Firestore collections:**
- `users/` — user profiles
- `conversations/` — 1-1 and group conversations with participant metadata
- `conversations/{id}/messages/` — messages subcollection
- `feeds/` — stories/posts with expiration

## Key Conventions

- Controllers extract `uid` by casting `HttpContext.Items["User"]` to `FirebaseToken` — use the existing `GetUserIdFromToken()` pattern.
- New services that need request scope: add `[ScopedService]` attribute instead of registering manually in `Program.cs`.
- Flutter feature modules in `lib/features/` follow the pattern: `screens/`, `providers/` (BLoC), `widgets/`, `services/`.
- The `.env` file in `frontend/` must be listed under `assets:` in `pubspec.yaml` (already present).
