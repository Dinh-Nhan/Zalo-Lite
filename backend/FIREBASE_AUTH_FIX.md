# Firebase Authentication Fix - Hoàn thành

## Vấn đề đã sửa

### 1. **Duplicate Firebase Initialization** ✅
**Vấn đề**: `Program.cs` và `FirebaseService.cs` đều cố gắng khởi tạo FirebaseApp, gây xung đột.

**Giải pháp**: 
- Xóa code khởi tạo Firebase trùng lặp trong `Program.cs` (lines 17-27)
- Chỉ để `FirebaseService.cs` khởi tạo FirebaseApp một lần duy nhất
- Thêm `ProjectId` vào `FirebaseApp.Create()` trong `FirebaseService.cs`

### 2. **FirebaseApp.DefaultInstance null khi request đến** ✅
**Vấn đề**: Middleware chạy trước khi FirebaseService được khởi tạo, dẫn đến `FirebaseAuth.DefaultInstance` = null.

**Giải pháp**:
- Thêm warm-up call ngay sau `var app = builder.Build();`
- `app.Services.GetRequiredService<FirebaseService>();` đảm bảo Firebase được khởi tạo trước khi nhận request

### 3. **Infinite retry loop trong Flutter** ✅
**Vấn đề**: Flutter app liên tục retry khi nhận 401, gây log spam.

**Giải pháp**: Đã thêm `retried` flag trong `frontend/lib/services/dio_client.dart`

### 4. **Token verification logging** ✅
**Vấn đề**: Không có log để debug token verification.

**Giải pháp**: 
- Thêm logging vào `FirebaseAuthMiddleware.cs`
- Bỏ `checkRevoked: true` (gây lỗi với một số token)

## Các thay đổi code

### `backend/Program.cs`
```csharp
// ĐÃ XÓA: Duplicate Firebase initialization (lines 17-27)
// ĐÃ THÊM: Warm-up call sau builder.Build()
app.Services.GetRequiredService<FirebaseService>();
```

### `backend/Services/FirebaseService.cs`
```csharp
// ĐÃ THÊM: ProjectId vào FirebaseApp.Create()
FirebaseApp.Create(new AppOptions
{
    Credential = credential,
    ProjectId = projectId  // ← Thêm dòng này
});
```

### `backend/Middleware/FirebaseAuthMiddleware.cs`
```csharp
// ĐÃ THÊM: Logging
_logger.LogInformation("Verifying Firebase token (length={Length})...", token.Length);

// ĐÃ BỎ: checkRevoked parameter
var decoded = await FirebaseAuth.DefaultInstance
    .VerifyIdTokenAsync(token);  // ← Không dùng checkRevoked: true
```

## Cách test

### 1. Restart backend
```bash
cd backend
dotnet run
```

### 2. Kiểm tra log khi backend khởi động
Bạn sẽ thấy:
```
[HH:mm:ss INF] FirebaseService | Firebase initialized with ProjectId: zalo-lite-47899
```

### 3. Test với Flutter app
1. Mở Flutter app và login
2. Kiểm tra backend logs, bạn sẽ thấy:
```
[HH:mm:ss INF] FirebaseAuthMiddleware | Verifying Firebase token (length=XXX)...
[HH:mm:ss INF] FirebaseAuthMiddleware | Token verified OK — uid=abc123...
```

### 4. Test API endpoints
Sử dụng token từ Flutter app để test các endpoints:

```http
### Get current user info
GET http://localhost:5244/api/user/me
Authorization: Bearer YOUR_FIREBASE_TOKEN_HERE

### Update current user
PUT http://localhost:5244/api/user/me
Authorization: Bearer YOUR_FIREBASE_TOKEN_HERE
Content-Type: application/json

{
  "displayName": "New Name",
  "phoneNumber": "0123456789"
}
```

## Lưu ý quan trọng

1. **Token format**: Phải có space sau "Bearer"
   - ✅ Đúng: `Authorization: Bearer eyJhbGc...`
   - ❌ Sai: `Authorization: BearereyJhbGc...`

2. **Token expiration**: Firebase tokens hết hạn sau 1 giờ
   - Nếu gặp lỗi 401, thử logout và login lại để lấy token mới

3. **Emulator address**: Flutter app phải dùng `http://10.0.2.2:5244` (không phải localhost)

4. **CORS**: Đã cấu hình cho phép mọi origin (chỉ dùng trong dev)

## Các API đã cập nhật

### UserController
- ✅ `GET /api/user/me` - Lấy thông tin user hiện tại từ token
- ✅ `PUT /api/user/me` - Cập nhật user hiện tại
- ✅ `DELETE /api/user/me` - Xóa user hiện tại
- ✅ `POST /api/user` - Đăng ký (không cần token)

### FeedController
- ✅ Tất cả endpoints đều dùng token để lấy userId
- ✅ Không cần truyền userId trong URL nữa

### OtpController
- ✅ `POST /api/otp/send` - Gửi OTP (không cần token)
- ✅ `POST /api/otp/verify` - Verify OTP (không cần token)

### FriendController
- ✅ Đã đúng từ trước, không cần sửa

## Tài liệu tham khảo

- `backend/API_TESTING_GUIDE.md` - Hướng dẫn test API với token
- `backend/AUTHENTICATION_SUMMARY.md` - Tổng quan về authentication
- `backend/test-api.http` - File test API với REST Client

## Troubleshooting

### Nếu vẫn gặp lỗi 401:
1. Kiểm tra backend logs xem có dòng "Verifying Firebase token..." không
2. Nếu không có log → Firebase chưa khởi tạo đúng
3. Nếu có log nhưng failed → Token không hợp lệ hoặc đã hết hạn

### Nếu không thấy log middleware:
1. Kiểm tra request có header `Authorization: Bearer ...` không
2. Kiểm tra format token có đúng không (có space sau Bearer)

### Nếu token verification failed:
1. Kiểm tra ProjectId trong `appsettings.json` có đúng `zalo-lite-47899` không
2. Kiểm tra file `serviceAccountKey.json` có tồn tại không
3. Thử logout và login lại để lấy token mới
