# 🏗️ Architecture Diagram - Chat System

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          MOBILE APP (Flutter)                                     │
│                                                                      │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐       │
│  │ Conversation   │  │  Chat Screen   │  │  Group Info    │       │
│  │ List Screen    │  │                │  │  Screen        │       │
│  │                │  │  - Messages    │  │                │       │
│  │ - All Chats    │  │  - Input       │  │  - Members     │       │
│  │ - Groups       │  │  - Typing      │  │  - Settings    │       │
│  │ - Search       │  │  - Reactions   │  │  - Media       │       │
│  └────────────────┘  └────────────────┘  └────────────────┘       │
│           │                   │                    │                │
│           └───────────────────┴────────────────────┘                │
│                               │                                     │
└───────────────────────────────┼─────────────────────────────────────┘
                                │
                    ┌───────────┴───────────┐
                    │                       │
              HTTP REST API          SignalR WebSocket
                    │                       │
                    ▼                       ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      BACKEND (ASP.NET Core 8.0)                      │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                      API Layer                                │  │
│  │  ┌────────────────┐              ┌────────────────┐          │  │
│  │  │ ChatController │              │    ChatHub     │          │  │
│  │  │   (REST API)   │              │   (SignalR)    │          │  │
│  │  │                │              │                │          │  │
│  │  │ - GET /api/... │              │ - SendMessage  │          │  │
│  │  │ - POST /api/...│              │ - UserTyping   │          │  │
│  │  │ - PUT /api/... │              │ - MarkAsRead   │          │  │
│  │  │ - DELETE /...  │              │ - ReactToMsg   │          │  │
│  │  └────────────────┘              └────────────────┘          │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                               │                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    Business Logic Layer                       │  │
│  │  ┌────────────────────────────────────────────────────────┐  │  │
│  │  │                   ChatService                           │  │  │
│  │  │                                                         │  │  │
│  │  │  - GetConversations()                                  │  │  │
│  │  │  - GetMessages()                                       │  │  │
│  │  │  - SendMessage()                                       │  │  │
│  │  │  - CreateConversation()                                │  │  │
│  │  │  - AddParticipants()                                   │  │  │
│  │  │  - ReactToMessage()                                    │  │  │
│  │  │  - MarkAsRead()                                        │  │  │
│  │  │  - DeleteMessage()                                     │  │  │
│  │  └────────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                               │                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    Middleware Layer                           │  │
│  │  ┌──────────────────┐  ┌──────────────────┐                 │  │
│  │  │ Firebase Auth    │  │ Global Exception │                 │  │
│  │  │   Middleware     │  │     Handler      │                 │  │
│  │  └──────────────────┘  └──────────────────┘                 │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                               │                                     │
└───────────────────────────────┼─────────────────────────────────────┘
                                │
                    ┌───────────┴───────────┐
                    │                       │
              Firestore SDK            Redis Client
                    │                       │
                    ▼                       ▼
┌─────────────────────────────┐  ┌─────────────────────────────┐
│   FIRESTORE DATABASE        │  │      REDIS CACHE            │
│                             │  │                             │
│  conversations/             │  │  - User sessions            │
│    ├── {convId}/            │  │  - Online status            │
│    │   ├── data             │  │  - Cached data              │
│    │   └── messages/        │  │                             │
│    │       └── {msgId}      │  │                             │
│                             │  │                             │
│  users/                     │  │                             │
│    └── {userId}             │  │                             │
└─────────────────────────────┘  └─────────────────────────────┘
```

---

## Data Flow Diagrams

### 1. Send Message Flow

```
┌──────────┐                                                    ┌──────────┐
│  User A  │                                                    │  User B  │
└────┬─────┘                                                    └────┬─────┘
     │                                                                │
     │ 1. Type message                                               │
     │ "Hello!"                                                      │
     │                                                                │
     │ 2. Send via SignalR                                           │
     ├──────────────────────────────────────────┐                   │
     │                                           │                   │
     │                                           ▼                   │
     │                                  ┌────────────────┐           │
     │                                  │   ChatHub      │           │
     │                                  │  (SignalR)     │           │
     │                                  └────────┬───────┘           │
     │                                           │                   │
     │                                           │ 3. Invoke         │
     │                                           │    SendMessage    │
     │                                           ▼                   │
     │                                  ┌────────────────┐           │
     │                                  │  ChatService   │           │
     │                                  └────────┬───────┘           │
     │                                           │                   │
     │                                           │ 4. Save to        │
     │                                           │    Firestore      │
     │                                           ▼                   │
     │                                  ┌────────────────┐           │
     │                                  │   Firestore    │           │
     │                                  │   Database     │           │
     │                                  └────────┬───────┘           │
     │                                           │                   │
     │ 5. MessageSent (confirmation)             │                   │
     │◄──────────────────────────────────────────┤                   │
     │                                           │                   │
     │                                           │ 6. ReceiveMessage │
     │                                           ├──────────────────►│
     │                                           │                   │
     │                                           │ 7. MarkAsDelivered│
     │                                           │◄──────────────────┤
     │                                           │                   │
     │                                           │ 8. User reads msg │
     │                                           │                   │
     │                                           │ 9. MarkAsRead     │
     │                                           │◄──────────────────┤
     │                                           │                   │
     │ 10. MessageRead (notification)            │                   │
     │◄──────────────────────────────────────────┤                   │
     │                                                                │
```

### 2. Create Group Flow

```
┌──────────┐
│  User A  │
│ (Creator)│
└────┬─────┘
     │
     │ 1. Select participants
     │    [User B, User C, User D]
     │
     │ 2. Enter group name
     │    "Team Project"
     │
     │ 3. POST /api/chat/conversations
     ├──────────────────────────────────┐
     │                                  │
     │                                  ▼
     │                         ┌────────────────┐
     │                         │ChatController  │
     │                         └────────┬───────┘
     │                                  │
     │                                  ▼
     │                         ┌────────────────┐
     │                         │  ChatService   │
     │                         │                │
     │                         │ 1. Validate    │
     │                         │ 2. Get user    │
     │                         │    info        │
     │                         │ 3. Create conv │
     │                         └────────┬───────┘
     │                                  │
     │                                  ▼
     │                         ┌────────────────┐
     │                         │   Firestore    │
     │                         │                │
     │                         │ conversations/ │
     │                         │   └─ {newId}   │
     │                         └────────┬───────┘
     │                                  │
     │ 4. ConversationCreated           │
     │◄─────────────────────────────────┤
     │                                  │
     │                                  │ 5. Notify all
     │                                  │    participants
     │                                  │
     ├──────────────────────────────────┼──────────┐
     │                                  │          │
     ▼                                  ▼          ▼
┌──────────┐                    ┌──────────┐  ┌──────────┐
│  User B  │                    │  User C  │  │  User D  │
│          │                    │          │  │          │
│ Receives │                    │ Receives │  │ Receives │
│ ConvCreated                   │ ConvCreated │ ConvCreated
└──────────┘                    └──────────┘  └──────────┘
```

### 3. Real-time Typing Indicator Flow

```
┌──────────┐                                                    ┌──────────┐
│  User A  │                                                    │  User B  │
└────┬─────┘                                                    └────┬─────┘
     │                                                                │
     │ 1. Start typing                                               │
     │    "H"                                                        │
     │                                                                │
     │ 2. UserTyping(convId, userId, true)                           │
     ├──────────────────────────────────────────┐                   │
     │                                           │                   │
     │                                           ▼                   │
     │                                  ┌────────────────┐           │
     │                                  │   ChatHub      │           │
     │                                  └────────┬───────┘           │
     │                                           │                   │
     │                                           │ 3. Broadcast      │
     │                                           │    to others      │
     │                                           ├──────────────────►│
     │                                           │                   │
     │                                           │ 4. Show "typing..." │
     │                                           │                   │
     │ 5. Continue typing                        │                   │
     │    "He"                                   │                   │
     │                                           │                   │
     │ 6. Debounce timer (2s)                    │                   │
     │    No more typing                         │                   │
     │                                           │                   │
     │ 7. UserTyping(convId, userId, false)      │                   │
     ├──────────────────────────────────────────►│                   │
     │                                           │                   │
     │                                           │ 8. Hide "typing..." │
     │                                           ├──────────────────►│
     │                                                                │
```

---

## Component Interaction Diagram

### Flutter App Components

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter App                               │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                      Screens Layer                          │ │
│  │                                                             │ │
│  │  ConversationListScreen ──► ChatScreen ──► GroupInfoScreen│ │
│  │           │                      │                │        │ │
│  │           │                      │                │        │ │
│  │           ▼                      ▼                ▼        │ │
│  │  ┌──────────────┐      ┌──────────────┐  ┌──────────────┐│ │
│  │  │ConversationTile      │MessageBubble │  │ParticipantTile││ │
│  │  │              │      │              │  │              ││ │
│  │  │TypingIndicator      │ReplyPreview  │  │MemberActions ││ │
│  │  └──────────────┘      └──────────────┘  └──────────────┘│ │
│  └────────────────────────────────────────────────────────────┘ │
│                               │                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                      Services Layer                         │ │
│  │                                                             │ │
│  │  ┌──────────────┐              ┌──────────────┐           │ │
│  │  │ ChatService  │              │SignalRService│           │ │
│  │  │              │              │              │           │ │
│  │  │ - HTTP calls │              │ - WebSocket  │           │ │
│  │  │ - REST API   │              │ - Real-time  │           │ │
│  │  └──────────────┘              └──────────────┘           │ │
│  └────────────────────────────────────────────────────────────┘ │
│                               │                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                      Models Layer                           │ │
│  │                                                             │ │
│  │  Conversation ◄──► Message ◄──► Participant                │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## Database Schema Visualization

```
Firestore Database
│
├── users/
│   └── {userId}
│       ├── id: string
│       ├── first_name: string
│       ├── last_name: string
│       ├── email: string
│       ├── avatar: string
│       ├── status: boolean
│       └── created_at: timestamp
│
└── conversations/
    └── {conversationId}
        ├── id: string
        ├── type: "private" | "group"
        ├── participants: array
        │   └── [
        │       {
        │         user_id: string,
        │         user_name: string,
        │         avatar: string,
        │         role: "admin" | "member",
        │         unread_count: number,
        │         is_muted: boolean,
        │         is_pinned: boolean
        │       }
        │     ]
        ├── participant_ids: array [userId1, userId2, ...]
        ├── last_message: object
        ├── group_name: string (if group)
        ├── group_avatar_url: string (if group)
        ├── created_at: timestamp
        ├── updated_at: timestamp
        │
        └── messages/ (sub-collection)
            └── {messageId}
                ├── id: string
                ├── conversation_id: string
                ├── sender_id: string
                ├── sender_name: string
                ├── type: "text" | "image" | "video" | ...
                ├── content: string
                ├── media_url: string (optional)
                ├── reply_to_message_id: string (optional)
                ├── reactions: map
                │   └── {
                │       "❤️": [userId1, userId2],
                │       "👍": [userId3]
                │     }
                ├── read_by: map
                │   └── {
                │       userId1: timestamp,
                │       userId2: timestamp
                │     }
                ├── delivered_to: map
                ├── is_deleted: boolean
                ├── is_edited: boolean
                ├── created_at: timestamp
                └── updated_at: timestamp
```

---

## SignalR Connection Flow

```
┌──────────────┐
│ Mobile App   │
└──────┬───────┘
       │
       │ 1. Connect with userId
       │    wss://api.com/hubs/chat?userId=user_123
       │
       ▼
┌──────────────────────────────────────┐
│         SignalR Hub                  │
│                                      │
│  OnConnectedAsync()                  │
│    ├─ Store connectionId            │
│    ├─ Add to online users map       │
│    └─ Notify contacts (online)      │
│                                      │
│  Event Handlers:                     │
│    ├─ SendMessage                    │
│    ├─ UserTyping                     │
│    ├─ MarkAsRead                     │
│    ├─ ReactToMessage                 │
│    └─ ...                            │
│                                      │
│  OnDisconnectedAsync()               │
│    ├─ Remove connectionId            │
│    ├─ Remove from online users      │
│    └─ Notify contacts (offline)     │
└──────────────────────────────────────┘
       │
       │ 2. Broadcast events to clients
       │
       ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  Client 1    │  │  Client 2    │  │  Client 3    │
│              │  │              │  │              │
│ ReceiveMsg   │  │ ReceiveMsg   │  │ ReceiveMsg   │
│ UserTyping   │  │ UserTyping   │  │ UserTyping   │
│ MessageRead  │  │ MessageRead  │  │ MessageRead  │
└──────────────┘  └──────────────┘  └──────────────┘
```

---

## Security Flow

```
┌──────────────┐
│ Mobile App   │
└──────┬───────┘
       │
       │ 1. Login with Firebase
       │
       ▼
┌──────────────────────────────────────┐
│      Firebase Authentication         │
└──────────┬───────────────────────────┘
           │
           │ 2. Get ID Token
           │
           ▼
┌──────────────┐
│ Mobile App   │
└──────┬───────┘
       │
       │ 3. API Request
       │    Authorization: Bearer {token}
       │
       ▼
┌──────────────────────────────────────┐
│      Backend API                     │
│                                      │
│  FirebaseAuthMiddleware              │
│    ├─ Verify token                  │
│    ├─ Extract user claims           │
│    └─ Set User.Identity              │
│                                      │
│  [FirebaseAuthorize] Attribute       │
│    └─ Check authentication           │
│                                      │
│  ChatController / ChatHub            │
│    ├─ Get userId from claims        │
│    ├─ Verify permissions            │
│    └─ Execute action                 │
└──────────────────────────────────────┘
```

---

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Production Environment                  │
│                                                              │
│  ┌────────────────┐         ┌────────────────┐             │
│  │  Load Balancer │────────►│  App Server 1  │             │
│  │   (Nginx)      │         │  (ASP.NET)     │             │
│  └────────┬───────┘         └────────────────┘             │
│           │                                                  │
│           │                 ┌────────────────┐             │
│           └────────────────►│  App Server 2  │             │
│                             │  (ASP.NET)     │             │
│                             └────────────────┘             │
│                                      │                      │
│                                      │                      │
│           ┌──────────────────────────┼──────────────────┐  │
│           │                          │                  │  │
│           ▼                          ▼                  ▼  │
│  ┌────────────────┐      ┌────────────────┐  ┌────────────────┐
│  │   Firestore    │      │     Redis      │  │   Firebase     │
│  │   Database     │      │     Cache      │  │     Auth       │
│  └────────────────┘      └────────────────┘  └────────────────┘
│                                                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS
                              │
                              ▼
                    ┌────────────────┐
                    │  Mobile Apps   │
                    │   (Flutter)    │
                    └────────────────┘
```

---

**Hệ thống được thiết kế để scale và maintain dễ dàng!** 🚀
