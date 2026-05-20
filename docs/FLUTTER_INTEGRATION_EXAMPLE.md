# Flutter Integration Example - Chat System

## 📦 Dependencies

Thêm vào `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # HTTP & API
  http: ^1.1.0
  dio: ^5.4.0

  # SignalR
  signalr_netcore: ^1.3.6

  # State Management
  provider: ^6.1.1
  # hoặc
  riverpod: ^2.4.9
  # hoặc
  bloc: ^8.1.3

  # Local Storage
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # UI
  cached_network_image: ^3.3.1
  image_picker: ^1.0.7
  file_picker: ^6.1.1
  emoji_picker_flutter: ^1.6.3
  flutter_chat_bubble: ^2.0.2

  # Utils
  intl: ^0.19.0
  timeago: ^3.6.0
  uuid: ^4.3.3
```

## 🏗️ Project Structure

```
lib/
├── models/
│   ├── conversation.dart
│   ├── message.dart
│   ├── participant.dart
│   └── user.dart
├── services/
│   ├── api_service.dart
│   ├── chat_service.dart
│   └── signalr_service.dart
├── providers/
│   ├── chat_provider.dart
│   └── conversation_provider.dart
├── screens/
│   ├── conversation_list_screen.dart
│   ├── chat_screen.dart
│   └── group_info_screen.dart
└── widgets/
    ├── message_bubble.dart
    ├── typing_indicator.dart
    └── conversation_tile.dart
```

## 📝 Models

### conversation.dart
```dart
class Conversation {
  final String id;
  final String type;
  final List<Participant> participants;
  final Message? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Group specific
  final String? groupName;
  final String? groupAvatarUrl;
  final String? groupDescription;

  // Private chat - other user
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserAvatar;
  final bool? otherUserOnline;
  final DateTime? otherUserLastSeen;

  // User specific
  final bool isMuted;
  final bool isPinned;
  final int unreadCount;
  final bool isArchived;

  Conversation({
    required this.id,
    required this.type,
    required this.participants,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.groupName,
    this.groupAvatarUrl,
    this.groupDescription,
    this.otherUserId,
    this.otherUserName,
    this.otherUserAvatar,
    this.otherUserOnline,
    this.otherUserLastSeen,
    this.isMuted = false,
    this.isPinned = false,
    this.unreadCount = 0,
    this.isArchived = false,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      type: json['type'],
      participants: (json['participants'] as List)
          .map((p) => Participant.fromJson(p))
          .toList(),
      lastMessage: json['last_message'] != null
          ? Message.fromJson(json['last_message'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      groupName: json['group_name'],
      groupAvatarUrl: json['group_avatar_url'],
      groupDescription: json['group_description'],
      otherUserId: json['other_user_id'],
      otherUserName: json['other_user_name'],
      otherUserAvatar: json['other_user_avatar'],
      otherUserOnline: json['other_user_online'],
      otherUserLastSeen: json['other_user_last_seen'] != null
          ? DateTime.parse(json['other_user_last_seen'])
          : null,
      isMuted: json['is_muted'] ?? false,
      isPinned: json['is_pinned'] ?? false,
      unreadCount: json['unread_count'] ?? 0,
      isArchived: json['is_archived'] ?? false,
    );
  }

  String get displayName {
    if (type == 'group') {
      return groupName ?? 'Group';
    }
    return otherUserName ?? 'User';
  }

  String get displayAvatar {
    if (type == 'group') {
      return groupAvatarUrl ?? '';
    }
    return otherUserAvatar ?? '';
  }
}
```

### message.dart
```dart
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String type;
  final String content;

  // Media
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? fileName;
  final int? fileSize;
  final int? duration;

  // Reply
  final String? replyToMessageId;
  final String? replyToContent;
  final String? replyToSenderName;

  final bool isForwarded;

  // Reactions
  final Map<String, List<String>>? reactions;
  final int totalReactions;

  // Status
  final bool isDeleted;
  final DateTime? deletedAt;
  final bool isEdited;
  final DateTime? editedAt;

  final Map<String, DateTime>? readBy;
  final Map<String, DateTime>? deliveredTo;
  final String status; // sent, delivered, read

  final DateTime createdAt;
  final DateTime updatedAt;

  final bool isMine;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.type,
    required this.content,
    this.mediaUrl,
    this.thumbnailUrl,
    this.fileName,
    this.fileSize,
    this.duration,
    this.replyToMessageId,
    this.replyToContent,
    this.replyToSenderName,
    this.isForwarded = false,
    this.reactions,
    this.totalReactions = 0,
    this.isDeleted = false,
    this.deletedAt,
    this.isEdited = false,
    this.editedAt,
    this.readBy,
    this.deliveredTo,
    this.status = 'sent',
    required this.createdAt,
    required this.updatedAt,
    this.isMine = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      senderAvatar: json['sender_avatar'],
      type: json['type'],
      content: json['content'],
      mediaUrl: json['media_url'],
      thumbnailUrl: json['thumbnail_url'],
      fileName: json['file_name'],
      fileSize: json['file_size'],
      duration: json['duration'],
      replyToMessageId: json['reply_to_message_id'],
      replyToContent: json['reply_to_content'],
      replyToSenderName: json['reply_to_sender_name'],
      isForwarded: json['is_forwarded'] ?? false,
      reactions: json['reactions'] != null
          ? Map<String, List<String>>.from(json['reactions'])
          : null,
      totalReactions: json['total_reactions'] ?? 0,
      isDeleted: json['is_deleted'] ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'])
          : null,
      isEdited: json['is_edited'] ?? false,
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'])
          : null,
      readBy: json['read_by'] != null
          ? Map<String, DateTime>.from(json['read_by'])
          : null,
      deliveredTo: json['delivered_to'] != null
          ? Map<String, DateTime>.from(json['delivered_to'])
          : null,
      status: json['status'] ?? 'sent',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isMine: json['is_mine'] ?? false,
    );
  }
}
```

## 🔌 Services

### signalr_service.dart
```dart
import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  HubConnection? _hubConnection;
  final String baseUrl;
  final String userId;

  // Callbacks
  Function(Message)? onReceiveMessage;
  Function(String conversationId, String userId, bool isTyping)? onUserTyping;
  Function(String conversationId, String messageId, String userId)? onMessageRead;
  Function(String userId, bool isOnline)? onUserStatusChanged;
  Function(Conversation)? onConversationCreated;

  SignalRService({
    required this.baseUrl,
    required this.userId,
  });

  Future<void> connect() async {
    _hubConnection = HubConnectionBuilder()
        .withUrl('$baseUrl/hubs/chat?userId=$userId')
        .withAutomaticReconnect()
        .build();

    // Register event handlers
    _hubConnection!.on('ReceiveMessage', _handleReceiveMessage);
    _hubConnection!.on('UserTyping', _handleUserTyping);
    _hubConnection!.on('MessageRead', _handleMessageRead);
    _hubConnection!.on('MessageDelivered', _handleMessageDelivered);
    _hubConnection!.on('MessageReactionUpdated', _handleReactionUpdated);
    _hubConnection!.on('MessageDeleted', _handleMessageDeleted);
    _hubConnection!.on('MessageUpdated', _handleMessageUpdated);
    _hubConnection!.on('UserStatusChanged', _handleUserStatusChanged);
    _hubConnection!.on('ConversationCreated', _handleConversationCreated);
    _hubConnection!.on('GroupUpdated', _handleGroupUpdated);
    _hubConnection!.on('ParticipantsAdded', _handleParticipantsAdded);
    _hubConnection!.on('ParticipantRemoved', _handleParticipantRemoved);
    _hubConnection!.on('Error', _handleError);

    await _hubConnection!.start();
    print('SignalR Connected');
  }

  Future<void> disconnect() async {
    await _hubConnection?.stop();
    print('SignalR Disconnected');
  }

  // Send message
  Future<void> sendMessage({
    required String conversationId,
    required String type,
    required String content,
    String? mediaUrl,
    String? thumbnailUrl,
    String? fileName,
    int? fileSize,
    int? duration,
    String? replyToMessageId,
    bool isForwarded = false,
  }) async {
    await _hubConnection?.invoke('SendMessage', args: [
      {
        'conversation_id': conversationId,
        'type': type,
        'content': content,
        'media_url': mediaUrl,
        'thumbnail_url': thumbnailUrl,
        'file_name': fileName,
        'file_size': fileSize,
        'duration': duration,
        'reply_to_message_id': replyToMessageId,
        'is_forwarded': isForwarded,
      },
      userId,
    ]);
  }

  // User typing
  Future<void> userTyping(String conversationId, bool isTyping) async {
    await _hubConnection?.invoke('UserTyping', args: [
      conversationId,
      userId,
      isTyping,
    ]);
  }

  // Mark as read
  Future<void> markAsRead(String conversationId, String messageId) async {
    await _hubConnection?.invoke('MarkAsRead', args: [
      conversationId,
      messageId,
      userId,
    ]);
  }

  // React to message
  Future<void> reactToMessage({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) async {
    await _hubConnection?.invoke('ReactToMessage', args: [
      {
        'conversation_id': conversationId,
        'message_id': messageId,
        'emoji': emoji,
      },
      userId,
    ]);
  }

  // Delete message
  Future<void> deleteMessage(String conversationId, String messageId) async {
    await _hubConnection?.invoke('DeleteMessage', args: [
      conversationId,
      messageId,
      userId,
    ]);
  }

  // Update message
  Future<void> updateMessage({
    required String conversationId,
    required String messageId,
    required String newContent,
  }) async {
    await _hubConnection?.invoke('UpdateMessage', args: [
      {
        'conversation_id': conversationId,
        'message_id': messageId,
        'new_content': newContent,
      },
      userId,
    ]);
  }

  // Event handlers
  void _handleReceiveMessage(List<Object>? args) {
    if (args != null && args.isNotEmpty) {
      final messageJson = args[0] as Map<String, dynamic>;
      final message = Message.fromJson(messageJson);
      onReceiveMessage?.call(message);
    }
  }

  void _handleUserTyping(List<Object>? args) {
    if (args != null && args.isNotEmpty) {
      final data = args[0] as Map<String, dynamic>;
      onUserTyping?.call(
        data['conversation_id'],
        data['user_id'],
        data['is_typing'],
      );
    }
  }

  void _handleMessageRead(List<Object>? args) {
    if (args != null && args.isNotEmpty) {
      final data = args[0] as Map<String, dynamic>;
      onMessageRead?.call(
        data['conversation_id'],
        data['message_id'],
        data['read_by'],
      );
    }
  }

  void _handleMessageDelivered(List<Object>? args) {
    // Handle delivered
  }

  void _handleReactionUpdated(List<Object>? args) {
    // Handle reaction update
  }

  void _handleMessageDeleted(List<Object>? args) {
    // Handle message deleted
  }

  void _handleMessageUpdated(List<Object>? args) {
    // Handle message updated
  }

  void _handleUserStatusChanged(List<Object>? args) {
    if (args != null && args.isNotEmpty) {
      final data = args[0] as Map<String, dynamic>;
      onUserStatusChanged?.call(
        data['user_id'],
        data['is_online'],
      );
    }
  }

  void _handleConversationCreated(List<Object>? args) {
    if (args != null && args.isNotEmpty) {
      final convJson = args[0] as Map<String, dynamic>;
      final conversation = Conversation.fromJson(convJson);
      onConversationCreated?.call(conversation);
    }
  }

  void _handleGroupUpdated(List<Object>? args) {
    // Handle group updated
  }

  void _handleParticipantsAdded(List<Object>? args) {
    // Handle participants added
  }

  void _handleParticipantRemoved(List<Object>? args) {
    // Handle participant removed
  }

  void _handleError(List<Object>? args) {
    if (args != null && args.isNotEmpty) {
      final error = args[0] as Map<String, dynamic>;
      print('SignalR Error: ${error['message']}');
    }
  }
}
```

## 🎨 UI Screens

### conversation_list_screen.dart
```dart
class ConversationListScreen extends StatefulWidget {
  @override
  _ConversationListScreenState createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  final ChatService _chatService = ChatService();
  List<Conversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _setupSignalR();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final conversations = await _chatService.getConversations();
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Show error
    }
  }

  void _setupSignalR() {
    _chatService.signalRService.onReceiveMessage = (message) {
      // Update conversation list
      _loadConversations();
    };

    _chatService.signalRService.onConversationCreated = (conversation) {
      setState(() {
        _conversations.insert(0, conversation);
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showNewConversationDialog,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _conversations.length,
              itemBuilder: (context, index) {
                final conversation = _conversations[index];
                return ConversationTile(
                  conversation: conversation,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          conversation: conversation,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  void _showNewConversationDialog() {
    // Show dialog to create new conversation
  }
}
```

### chat_screen.dart
```dart
class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  ChatScreen({required this.conversation});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;
  Timer? _typingTimer;
  String? _typingUserId;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupSignalR();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final messages = await _chatService.getMessages(widget.conversation.id);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _setupSignalR() {
    _chatService.signalRService.onReceiveMessage = (message) {
      if (message.conversationId == widget.conversation.id) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();

        // Mark as read
        _chatService.signalRService.markAsRead(
          widget.conversation.id,
          message.id,
        );
      }
    };

    _chatService.signalRService.onUserTyping = (conversationId, userId, isTyping) {
      if (conversationId == widget.conversation.id) {
        setState(() {
          _isTyping = isTyping;
          _typingUserId = userId;
        });
      }
    };
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _chatService.signalRService.sendMessage(
      conversationId: widget.conversation.id,
      type: 'text',
      content: content,
    );

    _messageController.clear();
    _scrollToBottom();
  }

  void _onTyping() {
    _chatService.signalRService.userTyping(widget.conversation.id, true);

    _typingTimer?.cancel();
    _typingTimer = Timer(Duration(seconds: 2), () {
      _chatService.signalRService.userTyping(widget.conversation.id, false);
    });
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.conversation.displayAvatar),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.conversation.displayName),
                if (widget.conversation.type == 'private')
                  Text(
                    widget.conversation.otherUserOnline == true
                        ? 'Online'
                        : 'Offline',
                    style: TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return MessageBubble(
                        message: _messages[index],
                        onReact: (emoji) {
                          _chatService.signalRService.reactToMessage(
                            conversationId: widget.conversation.id,
                            messageId: _messages[index].id,
                            emoji: emoji,
                          );
                        },
                      );
                    },
                  ),
          ),
          if (_isTyping)
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Someone is typing...'),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Show attachment options
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              onChanged: (_) => _onTyping(),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _sendMessage,
            color: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }
}
```

## 🎯 Usage Example

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final chatService = ChatService(
    baseUrl: 'https://your-api.com',
    userId: 'current_user_id',
  );

  await chatService.connect();

  runApp(MyApp(chatService: chatService));
}

class MyApp extends StatelessWidget {
  final ChatService chatService;

  MyApp({required this.chatService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ConversationListScreen(),
    );
  }
}
```

---

Đây là code example hoàn chỉnh để integrate với backend. Bạn có thể customize UI theo design của Zalo!
