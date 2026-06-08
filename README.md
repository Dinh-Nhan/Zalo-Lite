# 💬 Zalo Lite — Ứng dụng nhắn tin

> **Đồ án môn học:** Lập trình thiết bị di động  
> **Trường:** Đại học Giao thông Vận tải TP.HCM (UTC2)  
> **Năm học:** 2025 – 2026

## 👥 Thành viên nhóm

| STT | Họ và tên            | MSSV       | Vai trò     |
| :-: | -------------------- | ---------- | ----------- |
|  1  | Mai Quốc Đại         | 6451071013 | Nhóm trưởng |
|  2  | Nguyễn Khánh Hà      | 6451071022 | Thành viên  |
|  3  | Đinh Nhật Huyền Nhân | 6451071055 | Thành viên  |
|  4  | Phan Công Trí        | 6451071080 | Thành viên  |
|  5  | Lê Quốc Trung        | 6451071082 | Thành viên  |

---

## 📝 Mô tả dự án

**Zalo Lite** là ứng dụng nhắn tin theo thời gian thực (real-time) lấy cảm hứng từ Zalo, được xây dựng với kiến trúc Client-Server. Dự án bao gồm 4 thành phần chính:

| Thành phần     | Mô tả                               | Công nghệ                    |
| -------------- | ----------------------------------- | ---------------------------- |
| **backend/**   | REST API & WebSocket Server         | ASP.NET Core 8.0 (C#)        |
| **frontend/**  | Ứng dụng di động (Android/iOS)      | Flutter / Dart               |
| **web_admin/** | Trang quản trị dành cho Admin       | Flutter Web                  |
| **functions/** | Cloud Functions (Push Notification) | Firebase Functions (Node.js) |

---

## 🚀 Tính năng chính

### 📱 Ứng dụng Mobile (frontend)

- **Chat 1-1 & Nhóm:** Gửi tin nhắn text, hình ảnh, video, audio, file đính kèm
- **Real-time:** Nhận tin nhắn tức thì qua SignalR WebSocket
- **Cuộc gọi:** Voice/Video call qua Agora RTC Engine
- **Bạn bè:** Gửi/nhận lời mời kết bạn, quét mã QR để kết bạn nhanh
- **NewsFeed & Story:** Đăng bài viết, story (tự động hết hạn sau 24h)
- **Thông báo đẩy:** Firebase Cloud Messaging (FCM)
- **Tương tác tin nhắn:** Reply, forward, react emoji, thu hồi, chỉnh sửa
- **Trạng thái:** Online/Offline, typing indicator, read/delivered receipts

### 🖥️ Trang quản trị (web_admin)

- Dashboard thống kê tổng quan
- Quản lý người dùng, bài viết (Feed), báo cáo vi phạm
- Quản lý kết bạn (Friendships)
- Gửi thông báo đẩy tới người dùng
- Quản lý phản hồi (Feedback)

---

## 🔧 Công nghệ sử dụng

### Backend (ASP.NET Core)

| Công nghệ / Package    | Phiên bản | Mục đích                                       |
| ---------------------- | --------- | ---------------------------------------------- |
| .NET SDK               | 8.0       | Nền tảng chạy Backend                          |
| ASP.NET Core           | 8.0       | Web API Framework                              |
| SignalR                | 8.0.15    | Real-time WebSocket (Chat, Friend)             |
| Google.Cloud.Firestore | 4.2.0     | NoSQL Database                                 |
| FirebaseAdmin          | 3.5.0     | Firebase Authentication & FCM                  |
| StackExchange.Redis    | 2.12.14   | Caching (lưu trạng thái online, OTP, tìm kiếm) |
| CloudinaryDotNet       | 1.29.1    | Upload & quản lý hình ảnh/video                |
| FluentValidation       | 11.3.1    | Validation dữ liệu đầu vào                     |
| Mapster                | 10.0.7    | Object mapping (DTO ↔ Model)                   |
| Serilog                | 10.0.0    | Structured Logging                             |
| Swashbuckle (Swagger)  | 6.6.2     | API Documentation                              |
| Scrutor                | 7.0.0     | Auto DI Registration                           |
| Groq API               | —         | AI Content Moderation (LLaMA 3.1)              |

### Frontend Mobile (Flutter)

| Công nghệ / Package         | Phiên bản | Mục đích                           |
| --------------------------- | --------- | ---------------------------------- |
| Flutter                     | 3.41.9    | Mobile UI Framework                |
| Dart                        | 3.11.5    | Ngôn ngữ lập trình                 |
| firebase_core               | ^2.31.0   | Firebase SDK                       |
| firebase_auth               | ^4.19.0   | Xác thực người dùng                |
| cloud_firestore             | ^4.17.5   | Truy vấn Firestore                 |
| firebase_messaging          | ^14.9.4   | Push Notification                  |
| dio                         | ^5.7.0    | HTTP Client                        |
| signalr_netcore             | ^1.4.4    | Kết nối WebSocket với Backend      |
| agora_rtc_engine            | ^6.3.2    | Voice/Video Call                   |
| provider                    | ^6.1.1    | State Management                   |
| go_router                   | ^17.1.0   | Routing / Navigation               |
| image_picker                | ^1.1.2    | Chọn ảnh từ Gallery/Camera         |
| camera                      | ^0.10.5+5 | Chụp ảnh trực tiếp                 |
| qr_flutter                  | ^4.1.0    | Tạo mã QR                          |
| mobile_scanner              | ^5.2.3    | Quét mã QR                         |
| table_calendar              | ^3.1.2    | Lịch (Calendar)                    |
| flutter_dotenv              | ^6.0.1    | Đọc biến môi trường từ file `.env` |
| flutter_local_notifications | ^17.2.4   | Thông báo cục bộ                   |
| flutter_callkeep            | ^1.0.0    | Hiển thị giao diện cuộc gọi đến    |
| permission_handler          | ^11.3.1   | Quản lý quyền (Camera, Mic,...)    |

### Web Admin (Flutter Web)

| Công nghệ / Package  | Phiên bản | Mục đích                           |
| -------------------- | --------- | ---------------------------------- |
| Flutter Web          | 3.41.9    | Web UI Framework                   |
| firebase_core        | ^3.6.0    | Firebase SDK                       |
| firebase_auth        | ^5.3.1    | Xác thực Admin                     |
| cloud_firestore      | ^5.4.3    | Truy vấn Firestore                 |
| flutter_riverpod     | ^2.6.1    | State Management                   |
| go_router            | ^14.3.0   | Routing                            |
| google_fonts         | ^6.2.1    | Typography                         |
| fl_chart             | ^0.69.0   | Biểu đồ thống kê                   |
| cached_network_image | ^3.4.1    | Tải & cache ảnh                    |
| flutter_dotenv       | ^6.0.1    | Đọc biến môi trường từ file `.env` |

### Dịch vụ bên thứ ba (Third-party Services)

| Dịch vụ                                              | Mục đích                                   |
| ---------------------------------------------------- | ------------------------------------------ |
| **Firebase** (Firestore, Auth, FCM, Cloud Functions) | Database, xác thực, push notification      |
| **Redis**                                            | Caching trạng thái online, lưu OTP         |
| **Cloudinary**                                       | Lưu trữ & quản lý media (ảnh, video, file) |
| **Groq (LLaMA 3.1 8B)**                              | AI kiểm duyệt nội dung bài viết            |
| **Agora**                                            | Voice/Video Call Engine                    |
| **Gmail SMTP**                                       | Gửi email OTP xác thực                     |

---

## 📋 Yêu cầu hệ thống (Prerequisites)

Trước khi cài đặt, đảm bảo máy tính đã cài sẵn:

| Phần mềm                            | Phiên bản tối thiểu | Link tải                                                                 |
| ----------------------------------- | ------------------- | ------------------------------------------------------------------------ |
| Flutter SDK                         | 3.41.9              | [flutter.dev](https://flutter.dev/docs/get-started/install)              |
| Dart SDK                            | 3.11.5              | (Đi kèm Flutter SDK)                                                     |
| .NET SDK                            | 8.0                 | [dotnet.microsoft.com](https://dotnet.microsoft.com/download/dotnet/8.0) |
| Redis Server                        | 7.x                 | Hướng dẫn cài đặt ở bên dưới bảng này                                    |
| Android Studio / VS Code            | Mới nhất            | IDE lập trình                                                            |
| Android Emulator hoặc thiết bị thật | Android 6.0+        | Chạy ứng dụng mobile                                                     |
| Node.js (tùy chọn)                  | 18.x                | Cần nếu deploy Cloud Functions                                           |

### Cài đặt Redis Server trên Docker Desktop

#### Cài đặt Docker Desktop

Cài đặt Docker Desktop (https://docs.docker.com/desktop/setup/install/windows-install/) - Lưu ý: Lựa chọn hệ điều hành phù hợp

Chạy lệnh sau ở Terminal hoặc Command Prompt:

```bash
docker run -d -p 6379:6379 redis
```

Sau khi chạy lệnh trên, mở Docker Desktop, chọn Redis, đảm bảo trạng thái là "Running"

---

## ⚙️ Hướng dẫn cài đặt và chạy dự án

### Bước 1: Clone dự án

```bash
git clone https://github.com/Dinh-Nhan/Zalo-Lite.git
cd Zalo-Lite
```

### Bước 2: Cấu hình các biến môi trường cần thiết và quan trọng (nếu thiếu thì dự án sẽ không thể chạy được)

1. Truy cập Google Drive: [Google Drive](https://drive.google.com/drive/folders/1_Dq62gvkSPkGK1nc3hK4sVd03IRj8_zB)
   **⚠️ Lưu ý:** Sử dụng tài khoảng Google: `example.st.utc2.edu.vn` - phải là tên miền của trường UTC2 thì mới có thể truy cập được vì đảm bảo tính bảo mật của dự án.

2. Truy cập vào thư mục `backend/` trên Drive sẽ thấy file **appsettings.json** và thư mục **FirebaseCredentials**.

- Tải file **appsettings.json** về và di chuyển vào gốc của thư mục `backend/` trong dự án
- Tải thư mục **FirebaseCredentials** về và di chuyển vào gốc của thư mục `backend/` trong dự án

3. Truy cập vào thư mục `frontend/` trên Drive sẽ thấy file **.env**.

- Tải file **.env** về và di chuyển vào gốc của thư mục `frontend/` trong dự án

4. Truy cập vào thư mục `web-admin/` trên Drive sẽ thấy file **.env**.

- Tải file **.env** về và di chuyển vào gốc của thư mục `web-admin/` trong dự án

## 📂 Cấu trúc sau khi thực hiện hướng dẫn như sau

```
Zalo_Lite/
│
├── backend/                          # Backend API (ASP.NET Core 8.0)
│   ├── Controllers/                  # API Controllers
│   ├── FirebaseCredentials/          # Chứa file json dùng để kết nối đến Firebase
│   │   └── serviceAccountKey.json    # Service Account Key của Firebase
│   ├── appsettings.json              # Cấu hình ứng dụng
│   └── Program.cs                    # Entry point
│
├── frontend/                         # Mobile App (Flutter)
│   ├── lib/
│   ├── .env                          # Cấu hình API URL
│   └── pubspec.yaml                  # Dependencies
│
├── web_admin/                        # Admin Dashboard (Flutter Web)
│   ├── lib/
│   ├── .env                          # Cấu hình tài khoản Admin
│   └── pubspec.yaml                  # Dependencies
│
├── functions/                        # Firebase Cloud Functions (Node.js)
│
├── docs/                             # Tài liệu kỹ thuật
│
└── README.md                         # File này
```

### Bước 3: Chạy Backend (ASP.NET Core)

```bash
# Di chuyển vào thư mục backend
cd backend

# Khôi phục các package NuGet
dotnet restore

# Biên dịch dự án
dotnet build

# Chạy ứng dụng
dotnet run
```

> Backend sẽ chạy tại: `http://localhost:5244`  
> Swagger UI: `http://localhost:5244/swagger/index.html`

**⚠️ Lưu ý:** Đảm bảo Redis Server đang chạy trên máy trước khi khởi động Backend:

### Bước 4: Chạy Frontend Mobile (Flutter)

```bash
# Di chuyển vào thư mục frontend
cd frontend

# Tải các package Dart
flutter pub get
```

**Chạy trên Android Emulator:**

```bash
flutter run
```

**Chạy trên thiết bị Android thật (qua Wi-Fi cùng mạng):**

1. Mở file `frontend/.env`
2. Sửa `API_BASE_URL` thành IP máy tính của bạn:
   ```env
   API_BASE_URL=http://192.168.1.xxx:5244
   ```
3. Chạy lệnh:
   ```bash
   flutter run
   ```

### Bước 5: Chạy Web Admin (Flutter Web)

```bash
# Di chuyển vào thư mục web_admin
cd web_admin

# Tải các package Dart
flutter pub get

# Chạy trên trình duyệt Chrome
flutter run -d chrome
```

> Web Admin sẽ mở tại: `http://localhost:xxxx` (port do Flutter tự chọn)

---

## 🔑 Tài khoản test

### Ứng dụng Mobile (frontend)

| Mô tả            | Email                  | Mật khẩu      |
| ---------------- | ---------------------- | ------------- |
| Tài khoản test 1 | `testuser01@gmail.com` | `Test@123456` |
| Tài khoản test 2 | `testuser02@gmail.com` | `Test@123456` |

> **Lưu ý:** Các tài khoản trên đã được đăng ký sẵn trên Firebase Authentication. Bạn có thể đăng ký tài khoản mới trực tiếp trên ứng dụng.

### Trang quản trị Web Admin

| Mô tả           | Email                | Mật khẩu       |
| --------------- | -------------------- | -------------- |
| Tài khoản Admin | `admin123@gmail.com` | `admin123@456` |

---

## 📂 Cấu trúc thư mục dự án

```
Zalo_Lite/
│
├── backend/                          # Backend API (ASP.NET Core 8.0)
│   ├── Controllers/                  # API Controllers
│   │   ├── AuthController.cs         #   Xác thực (Login/Register)
│   │   ├── ChatController.cs         #   Chat 1-1 & Nhóm
│   │   ├── FeedController.cs         #   Bài viết & Story
│   │   ├── FriendController.cs       #   Kết bạn
│   │   ├── OtpController.cs          #   Xác thực OTP qua Email
│   │   └── UserController.cs         #   Quản lý người dùng
│   ├── Hubs/                         # SignalR WebSocket Hubs
│   │   ├── ChatHub.cs                #   Real-time Chat
│   │   └── FriendHub.cs              #   Real-time Friend requests
│   ├── Services/                     # Business Logic Layer
│   ├── Models/                       # Data Models
│   ├── dtos/                         # Data Transfer Objects
│   ├── Middleware/                    # Custom Middleware (Auth, Exception)
│   ├── FirebaseCredentials/          # Firebase Service Account Key
│   ├── appsettings.json              # Cấu hình ứng dụng
│   └── Program.cs                    # Entry point
│
├── frontend/                         # Mobile App (Flutter)
│   ├── lib/
│   │   ├── config/                   # Cấu hình (API URL, Theme)
│   │   ├── models/                   # Data Models
│   │   ├── views/                    # UI Screens
│   │   │   ├── auth/                 #   Đăng nhập / Đăng ký
│   │   │   ├── chat/                 #   Màn hình Chat
│   │   │   ├── call/                 #   Cuộc gọi Voice/Video
│   │   │   ├── contacts/            #   Danh bạ & Bạn bè
│   │   │   ├── home/                 #   Trang chủ
│   │   │   └── settings/            #   Cài đặt
│   │   ├── features/                 # Feature modules
│   │   │   ├── calling/              #   Voice/Video Call
│   │   │   ├── friends/              #   Quản lý bạn bè
│   │   │   ├── newfeed/              #   NewsFeed & Story
│   │   │   ├── feedback/             #   Phản hồi
│   │   │   └── profile/              #   Hồ sơ cá nhân
│   │   ├── services/                 # API & SignalR Services
│   │   ├── providers/                # State Management
│   │   └── main.dart                 # Entry point
│   ├── .env                          # Cấu hình API URL
│   └── pubspec.yaml                  # Dependencies
│
├── web_admin/                        # Admin Dashboard (Flutter Web)
│   ├── lib/
│   │   ├── core/                     # Theme, Router, Constants
│   │   ├── features/                 # Modules quản trị
│   │   └── main.dart                 # Entry point
│   ├── .env                          # Cấu hình tài khoản Admin
│   └── pubspec.yaml                  # Dependencies
│
├── functions/                        # Firebase Cloud Functions (Node.js)
│   └── index.js                      # Push Notification dispatcher
│
├── docs/                             # Tài liệu kỹ thuật
│   ├── CHAT_SYSTEM_GUIDE.md
│   ├── ARCHITECTURE_DIAGRAM.md
│   ├── COMPLETE_SYSTEM_OVERVIEW.md
│   ├── FLUTTER_INTEGRATION_EXAMPLE.md
│   └── Chat_API.postman_collection.json
│
└── README.md                         # File này
```

---

## ⚠️ Các lưu ý quan trọng

### 1. File cấu hình bắt buộc

Các file sau **BẮT BUỘC** phải tồn tại để dự án hoạt động. Nếu thiếu, ứng dụng sẽ crash:

| File                     | Vị trí                         | Mô tả                                             |
| ------------------------ | ------------------------------ | ------------------------------------------------- |
| `serviceAccountKey.json` | `backend/FirebaseCredentials/` | Khóa xác thực Firebase (không được push lên Git)  |
| `appsettings.json`       | `backend/`                     | Cấu hình Backend (Redis, Cloudinary, Email, Groq) |
| `.env`                   | `frontend/`                    | Chứa `API_BASE_URL` — địa chỉ Backend API         |
| `.env`                   | `web_admin/`                   | Chứa `ADMIN_EMAIL` và `ADMIN_PASSWORD`            |

### 2. Redis Server phải đang chạy

Backend sử dụng Redis để lưu trữ trạng thái online/offline, OTP và cache. Nếu Redis không chạy, Backend sẽ báo lỗi kết nối khi khởi động.

### 3. Địa chỉ IP khi test trên thiết bị

| Thiết bị                   | Địa chỉ API_BASE_URL        |
| -------------------------- | --------------------------- |
| Android Emulator           | `http://10.0.2.2:5244`      |
| Thiết bị thật (cùng Wi-Fi) | `http://<IP-máy-tính>:5244` |
| iOS Simulator              | `http://localhost:5244`     |

### 4. Thứ tự khởi chạy khuyến nghị

1. **Redis Server** → khởi động trước
2. **Backend** (`dotnet run`) → khởi động sau Redis
3. **Frontend** (`flutter run`) → khởi động sau Backend
4. **Web Admin** (`flutter run -d chrome`) → có thể chạy độc lập (kết nối trực tiếp Firestore)

---

## 📚 Tài liệu tham khảo

- [Flutter Documentation](https://docs.flutter.dev/)
- [ASP.NET Core Documentation](https://learn.microsoft.com/aspnet/core/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [SignalR Documentation](https://learn.microsoft.com/aspnet/core/signalr/)
- [Agora RTC Documentation](https://docs.agora.io/en/)

---

## 📄 License

Dự án này được thực hiện cho mục đích học tập tại Trường Đại học Giao thông Vận tải TP.HCM (UTC2).
