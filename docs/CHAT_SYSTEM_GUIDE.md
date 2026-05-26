# Hệ Thống Chat 1-1 và Group - Giống Zalo

## 📋 Tổng Quan

Hệ thống chat hoàn chỉnh với các tính năng:
- ✅ Chat 1-1 (Private Chat)
- ✅ Chat nhóm (Group Chat)
- ✅ Real-time messaging với SignalR
- ✅ Gửi tin nhắn text, hình ảnh, video, audio, file
- ✅ Reply tin nhắn
- ✅ Forward tin nhắn
- ✅ React tin nhắn (emoji)
- ✅ Chỉnh sửa tin nhắn
- ✅ Xóa tin nhắn
- ✅ Typing indicator
- ✅ Read receipts (đã đọc)
- ✅ Delivered receipts (đã nhận)
- ✅ Online/Offline status
- ✅ Unread count
- ✅ Pin conversation
- ✅ Mute conversation
- ✅ Group management (thêm/xóa thành viên, đổi tên nhóm, v.v.)

## 🏗️ Kiến Trúc

### Backend Stack
- **ASP.NET Core 8.0**
- **Firestore** (NoSQL Database)
- **SignalR** (Real-time communication)
- **Redis** (Caching & Session)

### Database Structure (Firestore)

#### Collection: `conversations`
```json
{
  "id": "conv_123",
  "type": "private | group",
  "participants": [
    {
      "user_id": "user_1",
      "user_name": "John Doe",
      "avatar": "url",
      "role": "admin | member",
      "joined_at": "timestamp",
      "last_seen": "timestamp",
      "is_muted": false,
      "is_pinned": false,
      "unread_count": 5,
      "last_read_message_id": "msg_123",
      "nickname": "Johnny"
    }
  ],
  "participant_ids": ["user_1", "user_2"],
  "last_message": { /* Message object */ },
  "settings": {
    "is_notification_enabled": true,
    "theme": "default",
    "background_url": null,
    "emoji_set": "default",
    "auto_download_media": true,
    "disappearing_messages_duration": null
  },
  "created_at": "timestamp",
  "updated_at": "timestamp",

  // Group specific
  "group_name": "My Group",
  "group_avatar_url": "url",
  "group_description": "Description",
  "created_by": "user_1",
  "pinned_message_id": "msg_456",
  "pinned_message_content": "Important message",
  "only_admin_can_send": false,
  "only_admin_can_edit_info": true,
  "approval_required_to_join": false,
  "is_archived": false
}
```

#### Sub-collection: `conversations/{conversationId}/messages`
```json
{
  "id": "msg_123",
  "conversation_id": "conv_123",
  "sender_id": "user_1",
  "sender_name": "John Doe",
  "sender_avatar": "url",
  "type": "text | image | video | audio | file | sticker | location | contact",
  "content": "Hello!",

  // Media fields
  "media_url": "url",
  "thumbnail_url": "url",
  "file_name": "document.pdf",
  "file_size": 1024000,
  "duration": 120,

  // Reply fields
  "reply_to_message_id": "msg_122",
  "reply_to_content": "Previous message",
  "reply_to_sender_name": "Jane Doe",

  // Forward
  "is_forwarded": false,

  // Reactions
  "reactions": {
    "❤️": ["user_1", "user_2"],
    "👍": ["user_3"]
  },

  // Status
  "is_deleted": false,
  "deleted_at": null,
  "is_edited": false,
  "edited_at": null,

  // Receipts
  "read_by": {
    "user_2": "timestamp",
    "user_3": "timestamp"
  },
  "delivered_to": {
    "user_2": "timestamp",
    "user_3": "timestamp"
  },

  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

## 🔌 API Endpoints

### Conversations

#### 1. Get All Conversations
```http
GET /api/chat/conversations
Authorization: Bearer {firebase_token}
```

**Response:**
```json
{
  "success": true,
  "message": "Conversations retrieved successfully",
  "data": [
    {
      "id": "conv_123",
      "type": "private",
      "participants": [...],
      "last_message": {...},
      "other_user_id": "user_2",
      "other_user_name": "Jane Doe",
      "other_user_avatar": "url",
      "other_user_online": true,
      "is_muted": false,
      "is_pinned": false,
      "unread_count": 3,
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T12:00:00Z"
    }
  ]
}
```

#### 2. Get Conversation by ID
```http
GET /api/chat/conversations/{conversationId}
Authorization: Bearer {firebase_token}
```

#### 3. Create Conversation
```http
POST /api/chat/conversations
Authorization: Bearer {firebase_token}
Content-Type: application/json

{
  "type": "private",
  "participant_ids": ["user_2"]
}
```

**For Group:**
```json
{
  "type": "group",
  "participant_ids": ["user_2", "user_3", "user_4"],
  "group_name": "My Group",
  "group_avatar_url": "url",
  "group_description": "This is my group"
}
```

#### 4. Update Group
```http
PUT /api/chat/conversations/group
Authorization: Bearer {firebase_token}
Content-Type: application/json

{
  "conversation_id": "conv_123",
  "group_name": "New Group Name",
  "group_avatar_url": "new_url",
  "group_description": "New description"
}
```

#### 5. Add Participants
```http
POST /api/chat/conversations/participants
Authorization: Bearer {firebase_token}
Content-Type: application/json

{
  "conversation_id": "conv_123",
  "user_ids": ["user_5", "user_6"]
}
```

#### 6. Remove Participant
```http
DELETE /api/chat/conversations/{conversationId}/participants/{userIdToRemove}
Authorization: Bearer {firebase_token}
```

#### 7. Delete/Leave Conversation
```http
DELETE /api/chat/conversations/{conversationId}
Authorization: Bearer {firebase_token}
```

### Messages

#### 1. Get Messages
```http
GET /api/chat/conversations/{conversationId}/messages?limit=50&beforeMessageId=msg_123
Authorization: Bearer {firebase_token}
```

#### 2. Send Message
```http
POST /api/chat/messages
Authorization: Bearer {firebase_token}
Content-Type: application/json

{
  "conversation_id": "conv_123",
  "type": "text",
  "content": "Hello!",
  "reply_to_message_id": null,
  "is_forwarded": false
}
```

**Send Image:**
```json
{
  "conversation_id": "conv_123",
  "type": "image",
  "content": "Check this out!",
  "media_url": "https://example.com/image.jpg",
  "thumbnail_url": "https://example.com/thumb.jpg"
}
```

**Send File:**
```json
{
  "conversation_id": "conv_123",
  "type": "file",
  "content": "Document attached",
  "media_url": "https://example.com/doc.pdf",
  "file_name": "document.pdf",
  "file_size": 1024000
}
```

#### 3. Update Message
```http
PUT /api/chat/messages
Authorization: Bearer {firebase_token}
Content-Type: application/json

{
  "message_id": "msg_123",
  "conversation_id": "conv_123",
  "new_content": "Updated message"
}
```

#### 4. Delete Message
```http
DELETE /api/chat/conversations/{conversationId}/messages/{messageId}
Authorization: Bearer {firebase_token}
```

#### 5. React to Message
```http
POST /api/chat/messages/react
Authorization: Bearer {firebase_token}
Content-Type: application/json

{
  "message_id": "msg_123",
  "conversation_id": "conv_123",
  "emoji": "❤️"
}
```

#### 6. Mark as Read
```http
POST /api/chat/conversations/{conversationId}/messages/{messageId}/read
Authorization: Bearer {firebase_token}
```

#### 7. Mark as Delivered
```http
POST /api/chat/conversations/{conversationId}/messages/{messageId}/delivered
Authorization: Bearer {firebase_token}
```

## 🔄 SignalR Real-time Events

### Connection
```javascript
// Connect to hub
const connection = new signalR.HubConnectionBuilder()
    .withUrl("https://your-api.com/hubs/chat?userId=user_123")
    .build();

await connection.start();
```

### Events to Send (Client → Server)

#### 1. Send Message
```javascript
await connection.invoke("SendMessage", {
    conversationId: "conv_123",
    type: "text",
    content: "Hello!",
    replyToMessageId: null,
    isForwarded: false
}, "user_123");
```

#### 2. User Typing
```javascript
await connection.invoke("UserTyping", "conv_123", "user_123", true);
// Stop typing
await connection.invoke("UserTyping", "conv_123", "user_123", false);
```

#### 3. Mark as Read
```javascript
await connection.invoke("MarkAsRead", "conv_123", "msg_123", "user_123");
```

#### 4. Mark as Delivered
```javascript
await connection.invoke("MarkAsDelivered", "conv_123", "msg_123", "user_123");
```

#### 5. React to Message
```javascript
await connection.invoke("ReactToMessage", {
    messageId: "msg_123",
    conversationId: "conv_123",
    emoji: "❤️"
}, "user_123");
```

#### 6. Delete Message
```javascript
await connection.invoke("DeleteMessage", "conv_123", "msg_123", "user_123");
```

#### 7. Update Message
```javascript
await connection.invoke("UpdateMessage", {
    messageId: "msg_123",
    conversationId: "conv_123",
    newContent: "Updated content"
}, "user_123");
```

#### 8. Create Conversation
```javascript
await connection.invoke("CreateConversation", {
    type: "group",
    participantIds: ["user_2", "user_3"],
    groupName: "My Group"
}, "user_123");
```

#### 9. Add Participants
```javascript
await connection.invoke("AddParticipants", {
    conversationId: "conv_123",
    userIds: ["user_4", "user_5"]
}, "user_123");
```

#### 10. Remove Participant
```javascript
await connection.invoke("RemoveParticipant", "conv_123", "user_4", "user_123");
```

#### 11. Update Group
```javascript
await connection.invoke("UpdateGroup", {
    conversationId: "conv_123",
    groupName: "New Name",
    groupAvatarUrl: "new_url"
}, "user_123");
```

### Events to Receive (Server → Client)

#### 1. Receive Message
```javascript
connection.on("ReceiveMessage", (message) => {
    console.log("New message:", message);
    // Update UI
});
```

#### 2. Message Sent (Confirmation)
```javascript
connection.on("MessageSent", (message) => {
    console.log("Message sent successfully:", message);
});
```

#### 3. User Typing
```javascript
connection.on("UserTyping", (data) => {
    console.log(`${data.userName} is typing...`);
    // Show typing indicator
});
```

#### 4. Message Read
```javascript
connection.on("MessageRead", (data) => {
    console.log(`Message ${data.messageId} read by ${data.readBy}`);
    // Update read status
});
```

#### 5. Message Delivered
```javascript
connection.on("MessageDelivered", (data) => {
    console.log(`Message ${data.messageId} delivered to ${data.deliveredTo}`);
    // Update delivered status
});
```

#### 6. Message Reaction Updated
```javascript
connection.on("MessageReactionUpdated", (data) => {
    console.log("Reactions updated:", data.reactions);
    // Update reactions UI
});
```

#### 7. Message Deleted
```javascript
connection.on("MessageDeleted", (data) => {
    console.log(`Message ${data.messageId} deleted`);
    // Remove message from UI
});
```

#### 8. Message Updated
```javascript
connection.on("MessageUpdated", (message) => {
    console.log("Message updated:", message);
    // Update message in UI
});
```

#### 9. User Status Changed
```javascript
connection.on("UserStatusChanged", (data) => {
    console.log(`User ${data.userId} is ${data.isOnline ? 'online' : 'offline'}`);
    // Update user status
});
```

#### 10. Conversation Created
```javascript
connection.on("ConversationCreated", (conversation) => {
    console.log("New conversation:", conversation);
    // Add to conversation list
});
```

#### 11. Participants Added
```javascript
connection.on("ParticipantsAdded", (data) => {
    console.log("New participants added:", data.newParticipants);
    // Update participant list
});
```

#### 12. Participant Removed
```javascript
connection.on("ParticipantRemoved", (data) => {
    console.log(`User ${data.removedUserId} removed from conversation`);
    // Update participant list
});
```

#### 13. Removed from Conversation
```javascript
connection.on("RemovedFromConversation", (data) => {
    console.log("You were removed from conversation");
    // Remove conversation from list
});
```

#### 14. Group Updated
```javascript
connection.on("GroupUpdated", (conversation) => {
    console.log("Group info updated:", conversation);
    // Update group info
});
```

#### 15. Error
```javascript
connection.on("Error", (error) => {
    console.error("Error:", error.message);
    // Show error to user
});
```

## 📱 Flutter/Mobile Integration Example

### 1. Setup SignalR
```dart
import 'package:signalr_netcore/signalr_client.dart';

class ChatService {
  late HubConnection _hubConnection;

  Future<void> connect(String userId) async {
    _hubConnection = HubConnectionBuilder()
        .withUrl("https://your-api.com/hubs/chat?userId=$userId")
        .build();

    // Register event handlers
    _hubConnection.on("ReceiveMessage", _handleReceiveMessage);
    _hubConnection.on("UserTyping", _handleUserTyping);
    _hubConnection.on("MessageRead", _handleMessageRead);
    _hubConnection.on("UserStatusChanged", _handleUserStatusChanged);

    await _hubConnection.start();
  }

  void _handleReceiveMessage(List<Object>? arguments) {
    if (arguments != null && arguments.isNotEmpty) {
      final message = arguments[0] as Map<String, dynamic>;
      // Update UI with new message
    }
  }

  Future<void> sendMessage(SendMessageRequest request, String userId) async {
    await _hubConnection.invoke("SendMessage", args: [request.toJson(), userId]);
  }

  Future<void> disconnect() async {
    await _hubConnection.stop();
  }
}
```

### 2. Chat Screen Example
```dart
class ChatScreen extends StatefulWidget {
  final String conversationId;

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  List<Message> _messages = [];
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _chatService.connect(currentUserId);
  }

  Future<void> _loadMessages() async {
    // Load messages from API
    final response = await http.get(
      Uri.parse('https://your-api.com/api/chat/conversations/${widget.conversationId}/messages'),
      headers: {'Authorization': 'Bearer $token'}
    );

    setState(() {
      _messages = parseMessages(response.body);
    });
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _chatService.sendMessage(
      SendMessageRequest(
        conversationId: widget.conversationId,
        type: 'text',
        content: content,
      ),
      currentUserId
    );

    _messageController.clear();
  }

  void _onTyping() {
    _chatService.userTyping(widget.conversationId, currentUserId, true);

    _typingTimer?.cancel();
    _typingTimer = Timer(Duration(seconds: 2), () {
      _chatService.userTyping(widget.conversationId, currentUserId, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return MessageBubble(message: _messages[index]);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              onChanged: (_) => _onTyping(),
              decoration: InputDecoration(
                hintText: 'Type a message...',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
```

## 🎨 UI Features (Giống Zalo)

### 1. Conversation List Screen
- Avatar (tròn)
- Tên người/nhóm
- Last message preview
- Timestamp
- Unread badge (số tin nhắn chưa đọc)
- Pin icon (nếu được pin)
- Mute icon (nếu bị tắt thông báo)
- Online status indicator (chấm xanh)
- Swipe actions: Pin, Mute, Delete

### 2. Chat Screen
- Header: Avatar, Name, Online status, Last seen
- Message bubbles:
  - Sender (bên phải, màu xanh)
  - Receiver (bên trái, màu trắng/xám)
  - Timestamp
  - Read/Delivered status (✓✓)
  - Reply indicator
  - Reactions below message
- Input area:
  - Text input
  - Emoji button
  - Attach button (camera, gallery, file, location)
  - Send button
- Typing indicator
- Scroll to bottom button
- Load more messages on scroll up

### 3. Message Actions (Long press)
- Reply
- Forward
- Copy
- React (emoji picker)
- Edit (own messages)
- Delete (own messages)
- Info

### 4. Group Info Screen
- Group avatar
- Group name
- Group description
- Members list with roles
- Add members button
- Leave group button
- Group settings

## 🔐 Security & Best Practices

1. **Authentication**: Tất cả API đều yêu cầu Firebase token
2. **Authorization**: Kiểm tra user có quyền truy cập conversation không
3. **Validation**: Validate tất cả input với FluentValidation
4. **Error Handling**: Global exception handler
5. **Rate Limiting**: Implement rate limiting cho API
6. **File Upload**: Validate file type và size
7. **XSS Protection**: Sanitize user input
8. **CORS**: Configure CORS properly cho production

## 🚀 Deployment

### 1. Build Backend
```bash
cd backend
dotnet build -c Release
dotnet publish -c Release -o ./publish
```

### 2. Environment Variables
```env
Firebase__ProjectId=your-project-id
Firebase__CredentialsFilePath=/path/to/serviceAccountKey.json
Redis__ConnectString=localhost:6379
```

### 3. Run
```bash
dotnet backend.dll
```

## 📊 Performance Optimization

1. **Pagination**: Load messages in batches (50 messages)
2. **Caching**: Cache user info, conversation list in Redis
3. **Indexing**: Index Firestore collections properly
4. **Lazy Loading**: Load media on demand
5. **Compression**: Compress images before upload
6. **CDN**: Use CDN for media files

## 🧪 Testing

### Test SignalR Connection
```bash
# Install wscat
npm install -g wscat

# Connect
wscat -c "wss://your-api.com/hubs/chat?userId=user_123"
```

### Test API
```bash
# Get conversations
curl -X GET "https://your-api.com/api/chat/conversations" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Send message
curl -X POST "https://your-api.com/api/chat/messages" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "conversation_id": "conv_123",
    "type": "text",
    "content": "Hello!"
  }'
```

## 📝 TODO / Future Enhancements

- [ ] Voice messages
- [ ] Video calls
- [ ] Voice calls
- [ ] Message search
- [ ] Media gallery
- [ ] Message encryption (E2E)
- [ ] Disappearing messages
- [ ] Message scheduling
- [ ] Polls
- [ ] Stickers store
- [ ] Chat themes
- [ ] Backup & restore
- [ ] Multi-device sync
- [ ] Push notifications
- [ ] Message translation

## 🐛 Troubleshooting

### SignalR không kết nối được
- Kiểm tra CORS configuration
- Kiểm tra firewall/network
- Kiểm tra userId trong query string

### Messages không real-time
- Kiểm tra SignalR connection status
- Kiểm tra event handlers đã register chưa
- Check server logs

### Unread count không chính xác
- Gọi MarkAsRead khi user xem tin nhắn
- Kiểm tra participants array trong conversation

## 📞 Support

Nếu có vấn đề, hãy tạo issue hoặc liên hệ team.

---

**Happy Coding! 🚀**
