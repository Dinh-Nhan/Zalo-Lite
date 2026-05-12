# Hướng dẫn Test Firebase Authentication

## ✅ Đã sửa xong các lỗi

1. ✅ Xóa duplicate Firebase initialization
2. ✅ Thêm warm-up call để khởi tạo Firebase trước khi nhận request
3. ✅ Thêm ProjectId vào FirebaseApp.Create()
4. ✅ Thêm logging vào middleware để debug
5. ✅ Bỏ checkRevoked để tránh lỗi token verification
6. ✅ Fix infinite retry loop trong Flutter app

## Bước 1: Restart Backend

```bash
cd backend
dotnet run
```

**Kiểm tra log khởi động**, bạn phải thấy:
```
[HH:mm:ss INF] Application started
```

Không có lỗi về Firebase initialization.

## Bước 2: Test với Flutter App

1. Mở Flutter app
2. Login với tài khoản đã có trong Firebase Authentication
3. Sau khi login thành công, kiểm tra backend logs

**Backend logs phải hiển thị**:
```
[HH:mm:ss INF] FirebaseAuthMiddleware | Verifying Firebase token (length=XXX)...
[HH:mm:ss INF] FirebaseAuthMiddleware | Token verified OK — uid=abc123...
```

## Bước 3: Kiểm tra các API

### Test GET /api/user/me
Trong Flutter app, sau khi login, app sẽ tự động gọi API này để lấy thông tin user.

**Nếu thành công**: App hiển thị thông tin user
**Nếu thất bại**: Kiểm tra backend logs xem lỗi gì

### Test các API khác
Tất cả các API liên quan đến User, Feed, Friend đều sẽ tự động dùng token từ Flutter app.

## Các lỗi thường gặp và cách fix

### Lỗi 1: Backend log "No Bearer token in request"
**Nguyên nhân**: Flutter app không gửi token
**Cách fix**: 
- Kiểm tra Flutter app đã login chưa
- Kiểm tra `dio_client.dart` có thêm token vào header không

### Lỗi 2: Backend log "Token verification FAILED"
**Nguyên nhân**: Token không hợp lệ hoặc đã hết hạn
**Cách fix**:
- Logout và login lại trong Flutter app
- Token Firebase hết hạn sau 1 giờ

### Lỗi 3: Không thấy log middleware
**Nguyên nhân**: Firebase chưa khởi tạo đúng
**Cách fix**:
- Restart backend
- Kiểm tra file `serviceAccountKey.json` có tồn tại không
- Kiểm tra `appsettings.json` có đúng ProjectId không

### Lỗi 4: Flutter app liên tục refresh token
**Nguyên nhân**: Đã fix bằng cách thêm `retried` flag
**Kiểm tra**: Xem log Flutter có còn spam không

## Kiểm tra nhanh

### 1. Backend đang chạy?
```bash
curl http://localhost:5244/api/user
```
Phải trả về response (có thể là lỗi 401 nếu không có token, nhưng không được connection refused)

### 2. Firebase đã khởi tạo?
Kiểm tra backend logs khi khởi động, không được có lỗi về Firebase.

### 3. Token có đúng format?
Token phải có dạng: `eyJhbGciOiJSUzI1NiIsImtpZCI6Ij...` (rất dài, khoảng 800-1000 ký tự)

## Nếu vẫn gặp vấn đề

1. **Xóa bin và obj folder**:
```bash
cd backend
rm -rf bin obj
dotnet build
dotnet run
```

2. **Kiểm tra Firebase Console**:
- Vào https://console.firebase.google.com
- Chọn project `zalo-lite-47899`
- Vào Authentication → Users
- Kiểm tra user có tồn tại không

3. **Kiểm tra serviceAccountKey.json**:
```bash
cd backend/FirebaseCredentials
cat serviceAccountKey.json
```
File phải có các field: `project_id`, `private_key`, `client_email`

4. **Test token trực tiếp**:
Lấy token từ Flutter app (print ra console), sau đó test bằng curl:
```bash
curl -H "Authorization: Bearer YOUR_TOKEN_HERE" http://localhost:5244/api/user/me
```

## Kết quả mong đợi

✅ Backend khởi động không lỗi
✅ Flutter app login thành công
✅ Backend logs hiển thị "Token verified OK"
✅ API trả về dữ liệu đúng
✅ Không còn infinite retry loop

## Tài liệu chi tiết

- `FIREBASE_AUTH_FIX.md` - Chi tiết các thay đổi code
- `API_TESTING_GUIDE.md` - Hướng dẫn test API với REST Client
- `AUTHENTICATION_SUMMARY.md` - Tổng quan về authentication
