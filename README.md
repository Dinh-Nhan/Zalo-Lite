# 💬 Zalo Lite - Chat Application

Hệ thống chat 1-1 và group hoàn chỉnh với giao diện giống Zalo, được xây dựng với ASP.NET Core và Flutter.

## 🎯 Tính Năng

### ✅ Chat 1-1
- Gửi tin nhắn text, hình ảnh, video, audio, file
- Reply tin nhắn
- Forward tin nhắn
- React với emoji (❤️, 👍, 😂, 😮, 😢, 😡)
- Chỉnh sửa tin nhắn
- Thu hồi tin nhắn
- Typing indicator
- Read receipts (✓✓)
- Delivered receipts (✓)
- Online/Offline status
- Last seen
- Unread count
- Pin conversation
- Mute notifications

### ✅ Chat Nhóm
- Tạo nhóm với tên, avatar, mô tả
- Thêm/xóa thành viên
- Rời nhóm
- Admin/Member roles
- Chỉ admin gửi tin nhắn (option)
- Chỉ admin sửa thông tin (option)
- Pin message trong nhóm
- Quản lý thành viên

### ✅ Real-time
- SignalR WebSocket
- Instant messaging
- Typing indicators
- Online status
- Read/Delivered receipts
- Reactions real-time

## 🏗️ Kiến Trúc

```
┌─────────────────────────────────────────────────────────────┐
│                  Mobile App (Flutter)                        │
│  Conversation List → Chat Screen → Group Info                │
└─────────────────────────────────────────────────────────────┘
                            │
                    HTTP + SignalR
                            │
┌─────────────────────────────────────────────────────────────┐
│              Backend API (ASP.NET Core 8.0)                  │
│  ChatController → ChatService → ChatHub (SignalR)            │
└─────────────────────────────────────────────────────────────┘
                            │
                    Firestore SDK
                            │
┌─────────────────────────────────────────────────────────────┐
│                   Firestore Database                         │
│  conversations/ → messages/                                  │
└─────────────────────────────────────────────────────────────┘
```

## 📂 Cấu Trúc Project

```
zalo-lite/
├── backend/                    # ASP.NET Core API
│   ├── Controllers/
│   │   └── ChatController.cs
│   ├── Services/
│   │   └── ChatService.cs
│   ├── Hubs/
│   │   └── ChatHub.cs
│   ├── Models/Conversation/
│   ├── dtos/
│   └── Program.cs
│
├── frontend/                   # Flutter App
│   ├── lib/
│   │   ├── models/chat/
│   │   │   ├── conversation.dart
│   │   │   ├── message.dart
│   │   │   └── participant.dart
│   │   ├── views/chat/
│   │   │   ├── conversation_list_screen.dart
│   │   │   ├── chat_screen.dart
│   │   │   ├── new_conversation_screen.dart
│   │   │   └── group_info_screen.dart
│   │   ├── widgets/chat/
│   │   │   ├── conversation_tile.dart
│   │   │   ├── message_bubble.dart
│   │   │   └── typing_indicator.dart
│   │   └── services/chat/
│   │       ├── chat_service.dart
│   │       └── signalr_service.dart
│   └── pubspec.yaml
│
└── docs/                       # Documentation
    ├── CHAT_SYSTEM_GUIDE.md
    ├── ARCHITECTURE_DIAGRAM.md
    ├── COMPLETE_SYSTEM_OVERVIEW.md
    └── Chat_API.postman_collection.json
```

## 🚀 Quick Start

### Backend Setup

```bash
# Navigate to backend
cd backend

# Restore packages
dotnet restore

# Update Firebase credentials
# Edit: backend/FirebaseCredentials/serviceAccountKey.json

# Update appsettings.json
# Set Firebase ProjectId and Redis connection

# Run
dotnet run
```

Backend sẽ chạy tại: `https://localhost:7000`

### Frontend Setup

```bash
# Navigate to frontend
cd frontend

# Get dependencies
flutter pub get

# Run on device/emulator
flutter run
```

## 📡 API Endpoints

### Conversations
```
GET    /api/chat/conversations
GET    /api/chat/conversations/{id}
POST   /api/chat/conversations
PUT    /api/chat/conversations/group
POST   /api/chat/conversations/participants
DELETE /api/chat/conversations/{id}/participants/{userId}
DELETE /api/chat/conversations/{id}
```

### Messages
```
GET    /api/chat/conversations/{id}/messages
POST   /api/chat/messages
PUT    /api/chat/messages
DELETE /api/chat/conversations/{id}/messages/{msgId}
POST   /api/chat/messages/react
POST   /api/chat/conversations/{id}/messages/{msgId}/read
POST   /api/chat/conversations/{id}/messages/{msgId}/delivered
```

### SignalR Hub
```
wss://localhost:7000/hubs/chat?userId={userId}
```

## 🗄️ Database Schema

### Firestore Collections

**conversations/**
```javascript
{
  id: string,
  type: "private" | "group",
  participants: [
    {
      user_id: string,
      user_name: string,
      avatar: string,
      role: "admin" | "member",
      unread_count: number,
      is_muted: boolean,
      is_pinned: boolean
    }
  ],
  last_message: Message,
  group_name: string,
  created_at: timestamp,
  updated_at: timestamp
}
```

**conversations/{id}/messages/**
```javascript
{
  id: string,
  sender_id: string,
  type: "text" | "image" | "video" | "audio" | "file",
  content: string,
  media_url: string,
  reactions: {
    "❤️": [userId1, userId2]
  },
  read_by: {
    userId: timestamp
  },
  created_at: timestamp
}
```

## 📚 Documentation

Xem thêm documentation chi tiết trong thư mục `docs/`:

- **[CHAT_SYSTEM_GUIDE.md](docs/CHAT_SYSTEM_GUIDE.md)** - Hướng dẫn chi tiết hệ thống
- **[ARCHITECTURE_DIAGRAM.md](docs/ARCHITECTURE_DIAGRAM.md)** - Sơ đồ kiến trúc
- **[COMPLETE_SYSTEM_OVERVIEW.md](docs/COMPLETE_SYSTEM_OVERVIEW.md)** - Tổng quan hệ thống
- **[Chat_API.postman_collection.json](docs/Chat_API.postman_collection.json)** - Postman collection

## 🧪 Testing

### Test với Postman

1. Import file `docs/Chat_API.postman_collection.json`
2. Update variables:
   - `base_url`: https://localhost:7000
   - `token`: YOUR_FIREBASE_TOKEN
3. Test các endpoints

### Test SignalR

```bash
# Install wscat
npm install -g wscat

# Connect
wscat -c "wss://localhost:7000/hubs/chat?userId=user_123"
```

## 🎨 UI Screenshots

### Conversation List
- ✅ Tabs (Tất cả, Nhóm)
- ✅ Search
- ✅ Avatar với online indicator
- ✅ Unread badge
- ✅ Swipe actions

### Chat Screen
- ✅ Message bubbles (xanh/xám)
- ✅ Typing indicator
- ✅ Reply preview
- ✅ Reactions
- ✅ Read receipts
- ✅ Attachment menu

### Group Info
- ✅ Member list
- ✅ Add/remove members
- ✅ Admin management
- ✅ Group settings

## 🔧 Tech Stack

### Backend
- ASP.NET Core 8.0
- Firestore (NoSQL Database)
- SignalR (Real-time)
- Redis (Caching)
- FluentValidation
- Mapster

### Frontend
- Flutter 3.x
- Dio (HTTP client)
- SignalR NetCore
- Cached Network Image
- Image Picker
- File Picker

## 📝 TODO

- [ ] Voice recording
- [ ] Video player
- [ ] Image viewer với zoom
- [ ] Message search
- [ ] Media gallery
- [ ] Push notifications
- [ ] Dark mode
- [ ] E2E encryption
- [ ] Voice/Video calls

## 🤝 Contributing

Pull requests are welcome!

## 📄 License

MIT License

## 📧 Contact

Nếu có vấn đề, hãy tạo issue trên GitHub.

---

**Made with ❤️ by Senior Fullstack Developer**
