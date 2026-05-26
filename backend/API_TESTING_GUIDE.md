# Hướng Dẫn Test API với Token

## 1. Lấy Firebase Token

### Cách 1: Từ Flutter App (Recommended)
1. Login vào Flutter app
2. Thêm code này vào `login_view.dart` sau khi login thành công:
```dart
final token = await FirebaseAuth.instance.currentUser?.getIdToken();
print('🔑 TOKEN: $token');
```
3. Copy token từ console

### Cách 2: Từ Firebase Console
1. Vào [Firebase Console](https://console.firebase.google.com/)
2. Chọn project `zalo-lite-47899`
3. Authentication → Users → Click vào user
4. Copy UID
5. Dùng Firebase Admin SDK để tạo custom token (không khuyến khích cho testing)

### Cách 3: Dùng REST API
```bash
# Login và lấy token
curl -X POST https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=YOUR_API_KEY \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "dai@gmail.com",
    "password": "123456",
    "returnSecureToken": true
  }'
```

## 2. Test API với Token

### Dùng file `test-api.http` (VS Code REST Client)
1. Mở file `backend/test-api.http`
2. Thay `YOUR_FIREBASE_TOKEN_HERE` bằng token thực
3. Click "Send Request" trên mỗi endpoint

### Dùng curl
```bash
# Get profile
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:5244/api/auth/profile

# Get my info
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:5244/api/user/me

# Create feed
curl -X POST http://localhost:5244/api/feed \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content":[{"text":"Hello","media":[]}]}'
```

### Dùng Postman/Insomnia
1. Tạo request mới
2. Thêm header: `Authorization: Bearer YOUR_TOKEN`
3. Send request

## 3. API Endpoints Summary

### 🔓 Public (không cần token)
- `POST /api/user` - Register user mới
- `POST /api/otp/generate` - Tạo OTP
- `POST /api/otp/verify` - Verify OTP

### 🔒 Protected (cần token)

#### Auth
- `GET /api/auth/profile` - Lấy thông tin từ token

#### User
- `GET /api/user/me` - Lấy thông tin user hiện tại
- `GET /api/user/{id}` - Lấy thông tin user khác
- `GET /api/user` - Lấy tất cả users
- `PUT /api/user/me` - Cập nhật thông tin
- `DELETE /api/user/me` - Xóa account

#### Feed
- `POST /api/feed` - Tạo feed mới
- `GET /api/feed/{id}` - Lấy feed theo ID
- `GET /api/feed/me` - Lấy feeds của mình

#### Friend
- `GET /api/friends` - Danh sách bạn bè
- `GET /api/friends/requests/received` - Lời mời nhận được
- `GET /api/friends/requests/sent` - Lời mời đã gửi
- `POST /api/friends/requests` - Gửi lời mời kết bạn
- `PATCH /api/friends/requests/{id}` - Accept/Reject
- `DELETE /api/friends/{id}` - Unfriend
- `POST /api/friends/block/{id}` - Block
- `DELETE /api/friends/block/{id}` - Unblock

## 4. Token Expiration

Firebase ID Token hết hạn sau **1 giờ**. Nếu gặp lỗi 401:
1. Lấy token mới từ Flutter app
2. Hoặc dùng refresh token để lấy token mới

## 5. Troubleshooting

### Lỗi 401 "Token không hợp lệ"
- Kiểm tra token có đúng format không (phải có 3 phần ngăn cách bởi dấu `.`)
- Token đã hết hạn → lấy token mới
- Backend chưa khởi động → restart backend

### Lỗi "NullReferenceException"
- `FirebaseApp` chưa được khởi tạo → restart backend
- Kiểm tra file `serviceAccountKey.json` có đúng không

### Lỗi "Incorrect number of segments"
- Token bị cắt hoặc sai format
- Copy lại token đầy đủ (không có khoảng trắng)
