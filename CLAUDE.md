# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Zalo Lite is a Zalo-like chat application with 1-1 and group messaging, built with an ASP.NET Core 8 backend and a Flutter frontend. Real-time communication uses SignalR; data is stored in Firestore; media uploads go through Cloudinary; and Redis is used for caching.

## Commands

### Backend (from `backend/`)

```bash
dotnet restore          # Install packages
dotnet build            # Build
dotnet run              # Run (http://localhost:5244 / https://localhost:7000)
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

Frontend requires a `.env` file in `frontend/` with `AGORA_APP_ID` and `AGORA_APP_CERTIFICATE`. Firebase options are in `frontend/lib/firebase_options.dart`.

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

**JSON naming:** Both REST controllers and SignalR hub are configured with `SnakeCaseLower` — all payloads use `snake_case` in transit. The `SignalRService` event handlers accept both snake_case and PascalCase keys (e.g. `data['conversation_id'] ?? data['ConversationId']`) to handle both directions.

**Background services:** `StoryExpirationService` and `DisappearingMessageService` run as hosted services.

**In-memory cache in ChatService:** `ConversationResponse` and user objects are cached for 5 minutes in static `ConcurrentDictionary` fields — mutations must invalidate or update these caches to stay consistent.

### Frontend

**Routing:** `go_router` with auth-guard redirect logic in `lib/apps/router.dart`. `RouterNotifier` listens to `FirebaseAuth.authStateChanges()` and triggers redirects. Unauthenticated users are sent to `/login`; authenticated users are redirected away from auth routes to `/chat-list`.

**State management:** Mix of `provider` (for `CallProvider`, `FriendProvider`, `ChatProvider`) and `flutter_bloc` (BLoC pattern in feature modules). Feature-specific BLoCs live in `lib/features/<feature>/providers/`.

**API calls:** `DioClient` (`lib/services/dio_client.dart`) is the base HTTP client. `ApiService` wraps it. Feature-specific services extend from there. Base URL is configured in `lib/config/api_config.dart` — uses `http://10.0.2.2:5244` for Android emulator.

**Real-time:** `SignalR` via `signalr_netcore` package. `SignalRService` (`lib/services/chat/signalr_service.dart`) connects to `/hubs/chat?userId=<uid>&access_token=<firebase_token>`. `FriendHub` at `/hubs/friend` uses only `?access_token=<token>` and verifies the token itself (no userId param). Automatic reconnect is configured with delays `[2000, 5000, 10000, 30000]` ms.

**ChatProvider lifecycle:** `ChatProvider.init(uid)` must be called after login. It connects SignalR, loads conversations, starts the 3-minute heartbeat timer, and saves the FCM token. Call `setContext(ctx)` to give it access to `CallProvider` for incoming call routing. The provider observes `AppLifecycleState` to mark online/offline on resume/pause.

**Online presence:** Redis stores online status with a TTL. The frontend refreshes it every 3 minutes via `Heartbeat` SignalR call. On app resume, `SetOnline` is invoked; on pause, `SetOffline`. `ChatHub` tracks in-memory `_onlineUsers` (uid → Set\<connectionId\>) and `_connections` (connectionId → uid) as `ConcurrentDictionary`.

**Optimistic UI for messages:** `ChatProvider.sendMessage()` adds a temporary message with id `_pending_<timestamp>` and status `sending` immediately. A FIFO `Queue<String>` tracks pending IDs; when the server confirms via `MessageSent`, the first pending ID is dequeued and its message replaced in-place.

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
- `friendships/` — edges between users with `sender_id`, `addressee_id`, `status`

## Call Flow

Voice/video calls use Agora RTC for media and SignalR for signaling. The Agora token is generated **client-side** in `AgoraConfig.generateToken()` using the app certificate from `.env`. Channel name is deterministic: sorted `[uid1, uid2].join('_')`.

Signaling sequence:
1. Caller → `InitiateCall` (SignalR) → backend pushes `IncomingCall` to callee via SignalR group, and sends FCM to callee if offline.
2. Callee accepts → `AcceptCall` → backend pushes `CallAccepted` to caller.
3. Both sides join the Agora channel independently using the same generated channel name.
4. Either side ends → `EndCall` → backend pushes `CallEnded` to the other side.
5. `ChatProvider.saveCallMessage()` saves the call record as a `type: 'call'` message via REST API.

The `CallProvider` manages call state (`dialing → active → ended/rejected/missed`) and a live duration timer. `ChatProvider._onIncomingCall()` bridges the SignalR event to `CallProvider.receiveIncomingCall()`.

## SignalR Hub Events

**ChatHub** (client → server):
`SendMessage`, `UserTyping`, `MarkAsRead`, `MarkAsDelivered`, `ReactToMessage`, `DeleteMessage`, `UpdateMessage`, `CreateConversation`, `AddParticipants`, `RemoveParticipant`, `UpdateGroup`, `InitiateCall`, `AcceptCall`, `RejectCall`, `EndCall`, `Heartbeat`, `SetOnline`, `SetOffline`

**ChatHub** (server → client):
`ReceiveMessage`, `MessageSent`, `UserTyping`, `MessageRead`, `MessageDelivered`, `MessageReactionUpdated`, `MessageDeleted`, `MessageUpdated`, `UserStatusChanged`, `ConversationCreated`, `GroupUpdated`, `ParticipantsAdded`, `ParticipantRemoved`, `RemovedFromConversation`, `IncomingCall`, `CallAccepted`, `CallRejected`, `CallEnded`, `Error`

**FriendHub** pushes friendship events to `user_{uid}` groups from `FriendshipService` via `IHubContext<FriendHub>`.

## Key Conventions

- Controllers extract `uid` by casting `HttpContext.Items["User"]` to `FirebaseToken` — use the existing `GetUserIdFromToken()` pattern.
- New services that need request scope: add `[ScopedService]` attribute instead of registering manually in `Program.cs`.
- Flutter feature modules in `lib/features/` follow the pattern: `screens/`, `providers/` (BLoC), `widgets/`, `services/`.
- The `.env` file in `frontend/` must be listed under `assets:` in `pubspec.yaml` (already present).
- FCM push is fire-and-forget inside `Task.Run()` in `ChatHub` — it must not block the hub method.
- When adding a new Firestore query that filters by membership, follow the `WhereArrayContains("participant_ids", userId)` pattern used in `ChatService`.
