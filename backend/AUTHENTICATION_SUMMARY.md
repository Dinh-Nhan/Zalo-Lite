# Authentication Summary - Zalo Lite Backend

## Tổng Quan

Backend sử dụng **Firebase Authentication** với JWT tokens. Middleware `FirebaseAuthMiddleware` verify token và đặt user info vào `HttpContext.Items["User"]`.

## Flow Authentication

```
Client (Flutter)
    ↓ Login với Firebase
    ↓ Lấy ID Token
    ↓ Gửi request với header: Authorization: Bearer <token>
    ↓
Backend Middleware (FirebaseAuthMiddleware)
    ↓ Verify token với Firebase
    ↓ Set HttpContext.Items["User"] = FirebaseToken
    ↓
Controller (với [FirebaseAuthorize])
    ↓ Kiểm tra User có null không
    ↓ Lấy uid từ FirebaseToken
    ↓ Xử lý business logic
```

## Middleware: FirebaseAuthMiddleware

**Location:** `backend/Middleware/FirebaseAuthMiddleware.cs`

**Chức năng:**
- Đọc header `Authorization: Bearer <token>`
- Verify token với `FirebaseAuth.DefaultInstance.VerifyIdTokenAsync()`
- Nếu hợp lệ → set `HttpContext.Items["User"] = FirebaseToken`
- Nếu không hợp lệ → set `HttpContext.Items["User"] = null`

**Logging:**
- `[INF] Verifying Firebase token (length=...)` - Bắt đầu verify
- `[INF] Token verified OK — uid=...` - Verify thành công
- `[WRN] Token verification FAILED: [ExceptionType] Message` - Verify thất bại

## Attribute: FirebaseAuthorizeAttribute

**Location:** `backend/Utils/FirebaseAuthorizeAttribute.cs`

**Chức năng:**
- Kiểm tra `HttpContext.Items["User"]` có null không
- Nếu null → trả về 401 Unauthorized
- Nếu có → cho phép request tiếp tục

**Cách dùng:**
```csharp
[FirebaseAuthorize]  // ← Áp dụng cho toàn controller
public class UserController : ControllerBase
{
    [HttpGet("me")]  // ← Endpoint này cần token
    public IActionResult GetMe() { ... }

    [HttpPost]
    [AllowAnonymous]  // ← Endpoint này không cần token
    public IActionResult Create() { ... }
}
```

## Lấy User ID trong Controller

### Pattern 1: Property helper (Recommended)
```csharp
[FirebaseAuthorize]
public class MyController : ControllerBase
{
    private string CurrentUid =>
        (HttpContext.Items["User"] as FirebaseToken)?.Uid
        ?? throw new UnauthorizedAccessException("Unauthenticated");

    [HttpGet("me")]
    public async Task<IActionResult> GetMe()
    {
        var uid = CurrentUid;  // ← Dùng property
        // ...
    }
}
```

### Pattern 2: Inline cast
```csharp
[HttpGet("me")]
public async Task<IActionResult> GetMe()
{
    var token = (FirebaseToken)HttpContext.Items["User"]!;
    var uid = token.Uid;
    // ...
}
```

### Pattern 3: Nullable check
```csharp
[HttpPost]
[AllowAnonymous]
public async Task<IActionResult> Create()
{
    var token = HttpContext.Items["User"] as FirebaseToken;
    var uid = token?.Uid ?? "anonymous";  // ← Fallback nếu không có token
    // ...
}
```

## Controllers Authentication Status

| Controller | Class Attribute | Endpoints | Notes |
|------------|----------------|-----------|-------|
| **AuthController** | `[FirebaseAuthorize]` | Tất cả cần token | Test endpoint |
| **UserController** | `[FirebaseAuthorize]` | Hầu hết cần token | `POST /api/user` có `[AllowAnonymous]` cho register |
| **FeedController** | `[FirebaseAuthorize]` | Tất cả cần token | - |
| **FriendController** | `[FirebaseAuthorize]` | Tất cả cần token | - |
| **OtpController** | Không có | Tất cả public | Dùng cho forgot password |

## Endpoints Không Cần Token

```
POST /api/user              - Register user mới
POST /api/otp/generate      - Tạo OTP
POST /api/otp/verify        - Verify OTP
```

## Endpoints Cần Token

```
# Auth
GET  /api/auth/profile

# User
GET  /api/user/me
GET  /api/user/{id}
GET  /api/user
PUT  /api/user/me
PUT  /api/user/{id}
DELETE /api/user/me
DELETE /api/user/{id}

# Feed
POST /api/feed
GET  /api/feed/{id}
GET  /api/feed/me

# Friend
GET  /api/friends
GET  /api/friends/requests/received
GET  /api/friends/requests/sent
GET  /api/friends/blocked
GET  /api/friends/status/{id}
POST /api/friends/requests
PATCH /api/friends/requests/{id}
DELETE /api/friends/requests/{id}
DELETE /api/friends/{id}
POST /api/friends/block/{id}
DELETE /api/friends/block/{id}
```

## Common Issues & Solutions

### Issue 1: NullReferenceException khi verify token
**Nguyên nhân:** `FirebaseApp.DefaultInstance` là null

**Solution:** Thêm warm-up trong `Program.cs`:
```csharp
var app = builder.Build();
app.Services.GetRequiredService<FirebaseService>();  // ← Warm-up
```

### Issue 2: Token verification failed với token hợp lệ
**Nguyên nhân:** 
- `FirebaseApp` không có `ProjectId`
- Credentials file sai project

**Solution:** Kiểm tra `FirebaseService.cs`:
```csharp
FirebaseApp.Create(new AppOptions
{
    Credential = credential,
    ProjectId = projectId  // ← Bắt buộc
});
```

### Issue 3: 401 Unauthorized dù đã gửi token
**Nguyên nhân:**
- Token format sai (không có "Bearer " prefix)
- Token đã hết hạn (>1 giờ)
- Middleware chưa chạy

**Solution:**
- Kiểm tra header: `Authorization: Bearer <token>`
- Lấy token mới từ Firebase
- Kiểm tra log middleware

## Testing

Xem file `test-api.http` và `API_TESTING_GUIDE.md` để biết cách test API với token.

## Security Notes

1. **Không bao giờ log token đầy đủ** — chỉ log length hoặc 10 ký tự đầu
2. **Token hết hạn sau 1 giờ** — client phải refresh
3. **Không dùng `checkRevoked: true`** trong production (slow)
4. **Validate uid từ token** — không tin tưởng uid từ request body
5. **Dùng HTTPS** trong production — token có thể bị sniff trên HTTP
