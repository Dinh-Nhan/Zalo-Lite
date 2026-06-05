# 💬 Chat Module - Flutter

Module chat hoàn chỉnh với giao diện giống Zalo cho Flutter app.

## 📁 Cấu Trúc

```
lib/
├── models/chat/
│   ├── conversation.dart       # Model cuộc hội thoại
│   ├── message.dart           # Model tin nhắn
│   └── participant.dart       # Model người tham gia
│
├── views/chat/
│   ├── conversation_list_screen.dart  # Danh sách hội thoại
│   ├── chat_screen.dart              # Màn hình chat
│   ├── new_conversation_screen.dart  # Tạo hội thoại mới
│   └── group_info_screen.dart        # Thông tin nhóm
│
├── widgets/chat/
│   ├── conversation_tile.dart   # Item trong danh sách
│   ├── message_bubble.dart      # Bubble tin nhắn
│   └── typing_indicator.dart    # Typing indicator
│
└── services/chat/
    ├── chat_service.dart        # HTTP API service
    └── signalr_service.dart     # SignalR real-time service
```

## 🎨 UI Components

### ConversationTile
Item trong danh sách hội thoại với:
- Avatar với online indicator
- Tên người/nhóm
- Last message preview
- Timestamp
- Unread badge
- Pin/Mute icons
- Swipe actions

### MessageBubble
Bubble tin nhắn với:
- Sender/Receiver style khác nhau
- Support nhiều loại: text, image, video, audio, file
- Reply preview
- Reactions
- Read receipts
- Long press menu

### TypingIndicator
Animation 3 dots khi người khác đang typing

## 🔌 Services

### ChatService
HTTP REST API service:
```dart
final chatService = ChatService(baseUrl: 'https://your-api.com');
chatService.setAuthToken(token);

// Get conversations
final conversations = await chatService.getConversations();

// Send message
final message = await chatService.sendMessage(
  conversationId: 'conv_123',
  type: 'text',
  content: 'Hello!',
);
```

### SignalRService
Real-time messaging service:
```dart
final signalRService = SignalRService(
  baseUrl: 'https://your-api.com',
  userId: 'user_123',
);

await signalRService.connect();

// Listen for messages
signalRService.onReceiveMessage = (message) {
  print('New message: ${message.content}');
};

// Send message
await signalRService.sendMessage(
  conversationId: 'conv_123',
  type: 'text',
  content: 'Hello!',
);
```

## 🚀 Usage

### 1. Add Dependencies

Đã có trong `pubspec.yaml`:
```yaml
dependencies:
  dio: ^5.4.0
  signalr_netcore: ^1.3.6
  cached_network_image: ^3.3.1
  image_picker: ^1.0.7
  file_picker: ^6.1.1
  intl: ^0.19.0
```

### 2. Initialize Services

```dart
import 'package:flutter/material.dart';
import 'services/chat/chat_service.dart';
import 'services/chat/signalr_service.dart';
import 'views/chat/conversation_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final chatService = ChatService(
    baseUrl: 'https://your-api.com',
  );

  final signalRService = SignalRService(
    baseUrl: 'https://your-api.com',
    userId: 'current_user_id',
  );

  // Set auth token
  chatService.setAuthToken('your_firebase_token');

  // Connect SignalR
  await signalRService.connect();

  runApp(MyApp(
    chatService: chatService,
    signalRService: signalRService,
  ));
}
```

### 3. Navigate to Chat

```dart
// Open conversation list
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ConversationListScreen(),
  ),
);

// Open specific chat
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ChatScreen(
      conversation: conversation,
    ),
  ),
);
```

## 🎯 Features

### Conversation List Screen
- [x] Tabs (Tất cả, Nhóm)
- [x] Search conversations
- [x] Pull to refresh
- [x] Swipe actions (Pin, Mute, Delete)
- [x] Create new conversation
- [x] Online status indicator
- [x] Unread count badge

### Chat Screen
- [x] Message list với pagination
- [x] Send text messages
- [x] Send media (image, video, file)
- [x] Reply to message
- [x] React with emoji
- [x] Edit message
- [x] Delete message
- [x] Typing indicator
- [x] Read receipts
- [x] Scroll to bottom button
- [x] Date separators
- [x] Pinned message banner
- [x] Attachment menu

### Group Info Screen
- [x] Group header
- [x] Member list
- [x] Add members
- [x] Remove members
- [x] Admin management
- [x] Group settings
- [x] Leave group

## 🎨 Customization

### Thay đổi màu sắc

Trong `message_bubble.dart`:
```dart
// Màu bubble sender (hiện tại: xanh Zalo)
color: Color(0xFF0084FF)

// Thay đổi thành màu khác
color: Color(0xFF00C853) // Xanh lá
```

### Thay đổi avatar placeholder

Trong `conversation_tile.dart`:
```dart
CircleAvatar(
  backgroundColor: Colors.blue[100], // Thay đổi màu nền
  child: Text(
    conversation.displayName[0].toUpperCase(),
    style: TextStyle(color: Colors.blue[700]), // Thay đổi màu chữ
  ),
)
```

## 📝 Models

### Conversation
```dart
class Conversation {
  final String id;
  final String type; // 'private' | 'group'
  final List<Participant> participants;
  final Message? lastMessage;
  final String? groupName;
  final bool isMuted;
  final bool isPinned;
  final int unreadCount;
  // ...
}
```

### Message
```dart
class Message {
  final String id;
  final String senderId;
  final String type; // 'text' | 'image' | 'video' | ...
  final String content;
  final String? mediaUrl;
  final Map<String, List<String>>? reactions;
  final bool isMine;
  // ...
}
```

### Participant
```dart
class Participant {
  final String userId;
  final String userName;
  final String avatar;
  final String role; // 'admin' | 'member'
  final bool isOnline;
  // ...
}
```

## 🔧 API Integration

### Get Conversations
```dart
final conversations = await chatService.getConversations();
```

### Get Messages
```dart
final messages = await chatService.getMessages(
  conversationId,
  limit: 50,
  beforeMessageId: lastMessageId,
);
```

### Send Message
```dart
final message = await chatService.sendMessage(
  conversationId: conversationId,
  type: 'text',
  content: 'Hello!',
  replyToMessageId: replyToId,
);
```

### Create Conversation
```dart
final conversation = await chatService.createConversation(
  type: 'group',
  participantIds: ['user1', 'user2'],
  groupName: 'My Group',
);
```

## 🔄 Real-time Events

### Listen for new messages
```dart
signalRService.onReceiveMessage = (message) {
  setState(() {
    messages.add(message);
  });
  scrollToBottom();
};
```

### Listen for typing
```dart
signalRService.onUserTyping = (conversationId, userId, isTyping) {
  if (conversationId == currentConversationId) {
    setState(() {
      this.isTyping = isTyping;
    });
  }
};
```

### Listen for read receipts
```dart
signalRService.onMessageRead = (conversationId, messageId, userId) {
  // Update message status
  updateMessageStatus(messageId, 'read');
};
```

## 🐛 Troubleshooting

### SignalR không kết nối
- Kiểm tra baseUrl đúng chưa
- Kiểm tra userId có trong query string
- Check network connection

### Messages không hiển thị
- Verify API response format
- Check model parsing
- Review console logs

### Images không load
- Kiểm tra mediaUrl
- Verify CORS settings
- Check image URL accessibility

## 📄 License

MIT License

---

**Happy Coding! 🚀**
