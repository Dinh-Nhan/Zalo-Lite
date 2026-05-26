# Fix Firestore Authentication Error

## ✅ Vấn đề đã sửa

### Lỗi trước đó:
```
Grpc.Core.RpcException: Status(StatusCode="Unauthenticated", Detail="Request had invalid authentication credentials. Expected OAuth 2 access token, login cookie or other valid authentication credential.")
```

### Nguyên nhân:
1. Firestore không nhận được credentials đúng cách
2. Dùng `GoogleCredential.FromFile()` (deprecated method)
3. Không set `GOOGLE_APPLICATION_CREDENTIALS` environment variable

### Giải pháp:

**File: `backend/Services/FirebaseService.cs`**

```csharp
// 1. Resolve full path TRƯỚC khi dùng
var resolvedPath = Path.GetFullPath(credentialsFilePath, AppContext.BaseDirectory);
if (!File.Exists(resolvedPath))
{
    throw new FileNotFoundException($"Firebase credentials file not found: {resolvedPath}", resolvedPath);
}

// 2. Dùng CredentialFactory thay vì GoogleCredential.FromFile (deprecated)
var credential = CredentialFactory
    .FromFile<ServiceAccountCredential>(resolvedPath)
    .ToGoogleCredential();

// 3. Initialize FirebaseApp với credential
if (FirebaseApp.DefaultInstance == null)
{
    FirebaseApp.Create(new AppOptions
    {
        Credential = credential,
        ProjectId = projectId
    });
}

// 4. Set environment variable cho Firestore
Environment.SetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS", resolvedPath);

// 5. Initialize Firestore với cùng credential
FirestoreDb = new FirestoreDbBuilder
{
    ProjectId = projectId,
    Credential = credential
}.Build();
```

## Các thay đổi chính:

1. ✅ **Resolve path trước** - Đảm bảo file tồn tại trước khi dùng
2. ✅ **Dùng CredentialFactory** - Thay thế deprecated method
3. ✅ **Set environment variable** - Firestore sẽ tự động dùng credentials này
4. ✅ **Dùng cùng credential** - FirebaseApp và Firestore dùng chung credential object

## Test lại:

```bash
cd backend
dotnet run
```

### Kết quả mong đợi:

1. Backend khởi động không lỗi
2. Token verification thành công:
   ```
   [INF] FirebaseAuthMiddleware | Token verified OK — uid="..."
   ```
3. Firestore query thành công (không còn lỗi Unauthenticated)
4. API `/api/user/me` trả về dữ liệu user

### Nếu vẫn lỗi:

1. **Kiểm tra serviceAccountKey.json có đúng permissions không**:
   - Vào Firebase Console → Project Settings → Service Accounts
   - Download lại service account key mới
   - Thay thế file `backend/FirebaseCredentials/serviceAccountKey.json`

2. **Kiểm tra Firestore rules**:
   - Vào Firebase Console → Firestore Database → Rules
   - Đảm bảo rules cho phép service account đọc/ghi

3. **Kiểm tra project ID**:
   - Trong `appsettings.json`: `"ProjectId": "zalo-lite-47899"`
   - Trong `serviceAccountKey.json`: `"project_id": "zalo-lite-47899"`
   - Phải giống nhau!

## Timeline sửa lỗi:

1. ✅ **Fix 1**: Duplicate Firebase initialization → Đã sửa
2. ✅ **Fix 2**: Missing warm-up call → Đã sửa
3. ✅ **Fix 3**: Token verification → Đã hoạt động!
4. ✅ **Fix 4**: Firestore authentication → Vừa sửa xong

## Bước tiếp theo:

Restart backend và test API `/api/user/me` với token từ Flutter app.
