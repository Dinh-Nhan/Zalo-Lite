using System.Collections.Concurrent;
using backend.Attributes;
using backend.dtos.Request.Chat;
using backend.dtos.Response.Chat;
using backend.Enums;
using backend.Exceptions;
using backend.Hubs;
using backend.Models.Conversation;
using Google.Cloud.Firestore;
using Mapster;
using Microsoft.AspNetCore.SignalR;

namespace backend.Services;

[ScopedService]
public class ChatService
{
    private readonly FirestoreDb _db;
    private readonly ILogger<ChatService> _logger;
    private readonly RedisService _redis;
    private readonly IHubContext<ChatHub> _hub;

    // ── In-memory caches (static = shared across all scopes) ──────────
    private static readonly ConcurrentDictionary<string, (Conversation Conv, DateTime At)> _convCache = new();
    private static readonly ConcurrentDictionary<string, (Models.User User, DateTime At)> _userCache = new();
    private static readonly TimeSpan _convCacheTtl = TimeSpan.FromMinutes(5);
    private static readonly TimeSpan _userCacheTtl = TimeSpan.FromMinutes(5);

    public ChatService(
        FirestoreDb db,
        ILogger<ChatService> logger,
        RedisService redis,
        IHubContext<ChatHub> hub)
    {
        _db = db;
        _logger = logger;
        _redis = redis;
        _hub = hub;
    }

    #region Conversations

    public async Task<List<ConversationResponse>> GetUserConversationsAsync(string userId)
    {
        var query = _db.Collection("conversations").WhereArrayContains("participant_ids", userId);
        var snapshot = await query.GetSnapshotAsync();

        var conversations = new List<ConversationResponse>();
        foreach (var doc in snapshot.Documents)
        {
            var conversation = doc.ConvertTo<Conversation>();
            conversations.Add(await MapConversationToResponse(conversation, userId));
        }

        return conversations.OrderByDescending(c => c.UpdatedAt).ToList();
    }

    public async Task<ConversationResponse> GetConversationByIdAsync(string conversationId, string userId)
    {
        var snapshot = await _db.Collection("conversations").Document(conversationId).GetSnapshotAsync();
        if (!snapshot.Exists)
            throw new AppException(ErrorCode.CONVERSATION_NOT_FOUND);

        var conversation = snapshot.ConvertTo<Conversation>();
        if (!conversation.Participants.Any(p => p.UserId == userId))
            throw new AppException(ErrorCode.FORBIDDEN);

        return await MapConversationToResponse(conversation, userId);
    }

    public async Task<ConversationResponse> CreateConversationAsync(CreateConversationRequest request, string currentUserId)
    {
        if (request.Type == "private")
        {
            if (request.ParticipantIds.Count != 1)
                throw new AppException(ErrorCode.CANNOT_SELF_MESSAGE);

            var existing = await FindPrivateConversationAsync(currentUserId, request.ParticipantIds[0]);
            if (existing != null)
                return await MapConversationToResponse(existing, currentUserId);
        }

        var allIds = new List<string>(request.ParticipantIds) { currentUserId };
        var participants = new List<UserConver>();

        foreach (var uid in allIds.Distinct())
        {
            var userDoc = await _db.Collection("users").Document(uid).GetSnapshotAsync();
            if (!userDoc.Exists) throw new AppException(ErrorCode.USER_NOT_FOUND);

            var user = userDoc.ConvertTo<Models.User>();
            participants.Add(new UserConver
            {
                UserId = user.Id,
                UserName = ResolveDisplayName(user),
                Avatar = user.Avatar,
                Role = uid == currentUserId && request.Type == "group" ? "admin" : "member",
                JoinedAt = DateTime.UtcNow
            });
        }

        var conversation = new Conversation
        {
            Type = request.Type,
            Participants = participants,
            Settings = new Settings(),
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
            CreatedBy = currentUserId,
            GroupName = request.Type == "group" ? (request.GroupName ?? "New Group") : null,
            GroupAvatarUrl = request.GroupAvatarUrl,
            GroupDescription = request.GroupDescription
        };

        var docRef = await _db.Collection("conversations").AddAsync(conversation);
        conversation.Id = docRef.Id;
        await docRef.UpdateAsync("participant_ids", allIds.Distinct().ToList());

        var response = await MapConversationToResponse(conversation, currentUserId);

        // Broadcast cho tất cả participants để realtime update chat list
        foreach (var p in conversation.Participants)
        {
            var participantView = await MapConversationToResponse(conversation, p.UserId);
            await _hub.Clients.Group($"user_{p.UserId}")
                .SendAsync("ConversationCreated", participantView);
        }

        return response;
    }

    public async Task<ConversationResponse> UpdateGroupAsync(UpdateGroupRequest request, string userId)
    {
        var (docRef, conversation) = await GetGroupConversationAsync(request.ConversationId, userId);

        var participant = RequireParticipant(conversation, userId);
        if (conversation.OnlyAdminCanEditInfo && participant.Role != "admin")
            throw new AppException(ErrorCode.FORBIDDEN);

        var updates = new Dictionary<string, object> { { "updated_at", DateTime.UtcNow } };
        if (request.GroupName != null) { updates["group_name"] = request.GroupName; conversation.GroupName = request.GroupName; }
        if (request.GroupAvatarUrl != null) { updates["group_avatar_url"] = request.GroupAvatarUrl; conversation.GroupAvatarUrl = request.GroupAvatarUrl; }
        if (request.GroupDescription != null) { updates["group_description"] = request.GroupDescription; conversation.GroupDescription = request.GroupDescription; }

        await docRef.UpdateAsync(updates);
        InvalidateConversationCache(request.ConversationId);
        return await MapConversationToResponse(conversation, userId);
    }

    public async Task<ConversationResponse> AddParticipantsAsync(AddParticipantsRequest request, string userId)
    {
        var (docRef, conversation) = await GetGroupConversationAsync(request.ConversationId, userId);
        RequireParticipant(conversation, userId);

        var newParticipants = new List<UserConver>();
        foreach (var newUid in request.UserIds)
        {
            if (conversation.Participants.Any(p => p.UserId == newUid)) continue;
            var userDoc = await _db.Collection("users").Document(newUid).GetSnapshotAsync();
            if (!userDoc.Exists) continue;
            var user = userDoc.ConvertTo<Models.User>();
            newParticipants.Add(new UserConver
            {
                UserId = user.Id,
                UserName = ResolveDisplayName(user),
                Avatar = user.Avatar,
                Role = "member",
                JoinedAt = DateTime.UtcNow
            });
        }

        if (newParticipants.Any())
        {
            conversation.Participants.AddRange(newParticipants);
            await docRef.UpdateAsync(new Dictionary<string, object>
            {
                { "participants", conversation.Participants },
                { "participant_ids", conversation.Participants.Select(p => p.UserId).ToList() },
                { "updated_at", DateTime.UtcNow }
            });
            InvalidateConversationCache(request.ConversationId);
        }

        return await MapConversationToResponse(conversation, userId);
    }

    public async Task RemoveParticipantAsync(string conversationId, string userIdToRemove, string currentUserId)
    {
        var (docRef, conversation) = await GetGroupConversationAsync(conversationId, currentUserId);

        var currentParticipant = RequireParticipant(conversation, currentUserId);
        if (userIdToRemove != currentUserId && currentParticipant.Role != "admin")
            throw new AppException(ErrorCode.FORBIDDEN);

        conversation.Participants.RemoveAll(p => p.UserId == userIdToRemove);
        await docRef.UpdateAsync(new Dictionary<string, object>
        {
            { "participants", conversation.Participants },
            { "participant_ids", conversation.Participants.Select(p => p.UserId).ToList() },
            { "updated_at", DateTime.UtcNow }
        });
        InvalidateConversationCache(conversationId);
    }

    public async Task DeleteConversationAsync(string conversationId, string userId)
    {
        await RemoveParticipantAsync(conversationId, userId, userId);
    }

    #endregion

    #region Messages

    public async Task<List<MessageResponse>> GetMessagesAsync(
        string conversationId, string userId, int limit = 50, string? beforeMessageId = null)
    {
        var convDoc = await _db.Collection("conversations").Document(conversationId).GetSnapshotAsync();
        if (!convDoc.Exists) throw new AppException(ErrorCode.CONVERSATION_NOT_FOUND);

        var conversation = convDoc.ConvertTo<Conversation>();
        if (!conversation.Participants.Any(p => p.UserId == userId))
            throw new AppException(ErrorCode.FORBIDDEN);

        var messagesRef = _db.Collection("conversations").Document(conversationId).Collection("messages");
        Query query = messagesRef.OrderByDescending("created_at").Limit(limit);

        if (beforeMessageId != null)
        {
            var beforeDoc = await messagesRef.Document(beforeMessageId).GetSnapshotAsync();
            if (beforeDoc.Exists) query = query.StartAfter(beforeDoc);
        }

        var snapshot = await query.GetSnapshotAsync();
        return snapshot.Documents
            .Select(doc => doc.ConvertTo<Message>())
            .Where(m => m.HiddenFor == null || !m.HiddenFor.Contains(userId))
            .Select(m => MapMessageToResponse(m, userId))
            .OrderBy(m => m.CreatedAt)
            .ToList();
    }

    /// <summary>Ẩn tin nhắn chỉ ở phía userId — người kia vẫn thấy bình thường.</summary>
    public async Task HideMessageForMeAsync(string conversationId, string messageId, string userId)
    {
        var messageRef = _db.Collection("conversations")
            .Document(conversationId).Collection("messages").Document(messageId);

        // ArrayUnion tự tạo field nếu chưa có và không thêm trùng
        await messageRef.UpdateAsync("hidden_for", FieldValue.ArrayUnion(userId));
    }

    public async Task<MessageResponse> SendMessageAsync(SendMessageRequest request, string senderId)
    {
        // ── 1. Parallel reads (cache-first) ───────────────────
        var convTask        = GetConversationCachedAsync(request.ConversationId);
        var senderUserTask  = GetUserCachedAsync(senderId);

        Task<DocumentSnapshot>? replyTask = request.ReplyToMessageId != null
            ? _db.Collection("conversations").Document(request.ConversationId)
                  .Collection("messages").Document(request.ReplyToMessageId).GetSnapshotAsync()
            : null;

        var waitList = new List<Task> { convTask, senderUserTask };
        if (replyTask != null) waitList.Add(replyTask);
        await Task.WhenAll(waitList);

        var conversation = await convTask;
        var participant  = RequireParticipant(conversation, senderId);

        if (conversation.OnlyAdminCanSend && participant.Role != "admin")
            throw new AppException(ErrorCode.FORBIDDEN);

        // Luôn lấy tên từ Firestore user document — không tin client
        var sender       = await senderUserTask;
        var senderName   = ResolveDisplayName(sender);
        var senderAvatar = sender.Avatar;

        // ── 2. Build message ───────────────────────────────────
        var now = DateTime.UtcNow;
        var message = new Message
        {
            ConversationId  = request.ConversationId,
            SenderId        = senderId,
            SenderName   = senderName,
            SenderAvatar = senderAvatar,
            Type            = request.Type,
            Content         = request.Content,
            MediaUrl        = request.MediaUrl,
            ThumbnailUrl    = request.ThumbnailUrl,
            FileName        = request.FileName,
            FileSize        = request.FileSize,
            Duration        = request.Duration,
            ReplyToMessageId = request.ReplyToMessageId,
            IsForwarded     = request.IsForwarded,
            CreatedAt       = now,
            UpdatedAt       = now,
            DeliveredTo     = new Dictionary<string, DateTime>(),
            ReadBy          = new Dictionary<string, DateTime>()
        };

        if (conversation.Settings?.DisappearingMessagesDuration > 0)
            message.ExpiresAt = now.AddSeconds(conversation.Settings.DisappearingMessagesDuration.Value);

        if (replyTask != null && replyTask.Result.Exists)
        {
            var replyMsg = replyTask.Result.ConvertTo<Message>();
            message.ReplyToContent    = replyMsg.Content;
            message.ReplyToSenderName = replyMsg.SenderName;
        }

        // ── 3. Single batch: message + lastMsg + unread counts ─
        var messageRef = _db.Collection("conversations")
            .Document(request.ConversationId).Collection("messages").Document();
        message.Id = messageRef.Id;

        foreach (var p in conversation.Participants)
        {
            if (p.UserId == senderId)
            {
                p.LastReadMessageId = message.Id;
                p.UnreadCount = 0;
            }
            else
            {
                p.UnreadCount++;
            }
        }

        var convRef = _db.Collection("conversations").Document(request.ConversationId);
        var batch = _db.StartBatch();
        batch.Create(messageRef, message);
        batch.Update(convRef, new Dictionary<string, object>
        {
            { "last_message", message },
            { "updated_at",   now },
            { "participants", conversation.Participants }
        });
        await batch.CommitAsync();

        // Cập nhật cache với conversation mới nhất
        _convCache[request.ConversationId] = (conversation, DateTime.UtcNow);

        var response = MapMessageToResponse(message, senderId);
        response.ParticipantIds = conversation.Participants.Select(p => p.UserId).ToList();
        response.IsGroupConversation = conversation.Type == "group";
        response.NotificationTitle = response.IsGroupConversation
            ? (conversation.GroupName ?? "Nhóm chat")
            : response.SenderName;
        return response;
    }

    public async Task<MessageResponse> UpdateMessageAsync(UpdateMessageRequest request, string userId)
    {
        var messageRef = _db.Collection("conversations")
            .Document(request.ConversationId).Collection("messages").Document(request.MessageId);
        var snapshot = await messageRef.GetSnapshotAsync();
        if (!snapshot.Exists) throw new AppException(ErrorCode.MESSAGE_NOT_FOUND);

        var message = snapshot.ConvertTo<Message>();
        if (message.SenderId != userId) throw new AppException(ErrorCode.FORBIDDEN);

        await messageRef.UpdateAsync(new Dictionary<string, object>
        {
            { "content", request.NewContent },
            { "is_edited", true },
            { "edited_at", DateTime.UtcNow },
            { "updated_at", DateTime.UtcNow }
        });

        message.Content = request.NewContent;
        message.IsEdited = true;
        message.EditedAt = DateTime.UtcNow;
        return MapMessageToResponse(message, userId);
    }

    public async Task DeleteMessageAsync(string conversationId, string messageId, string userId)
    {
        var messageRef = _db.Collection("conversations")
            .Document(conversationId).Collection("messages").Document(messageId);
        var snapshot = await messageRef.GetSnapshotAsync();
        if (!snapshot.Exists) throw new AppException(ErrorCode.MESSAGE_NOT_FOUND);

        var message = snapshot.ConvertTo<Message>();
        if (message.SenderId != userId) throw new AppException(ErrorCode.FORBIDDEN);

        await messageRef.UpdateAsync(new Dictionary<string, object>
        {
            { "is_deleted", true },
            { "deleted_at", DateTime.UtcNow },
            { "content", "Message has been deleted" },
            { "updated_at", DateTime.UtcNow }
        });
    }

    public async Task<MessageResponse> ReactToMessageAsync(ReactToMessageRequest request, string userId)
    {
        var messageRef = _db.Collection("conversations")
            .Document(request.ConversationId).Collection("messages").Document(request.MessageId);
        var snapshot = await messageRef.GetSnapshotAsync();
        if (!snapshot.Exists) throw new AppException(ErrorCode.MESSAGE_NOT_FOUND);

        var message = snapshot.ConvertTo<Message>();
        message.Reactions ??= new Dictionary<string, List<string>>();

        if (message.Reactions.TryGetValue(request.Emoji, out var reactors))
        {
            if (reactors.Contains(userId)) reactors.Remove(userId);
            else reactors.Add(userId);
            if (reactors.Count == 0) message.Reactions.Remove(request.Emoji);
        }
        else
        {
            message.Reactions[request.Emoji] = new List<string> { userId };
        }

        await messageRef.UpdateAsync(new Dictionary<string, object>
        {
            { "reactions", message.Reactions },
            { "updated_at", DateTime.UtcNow }
        });

        return MapMessageToResponse(message, userId);
    }

    /// <summary>Returns senderId of the message (for hub to notify).</summary>
    public async Task<string?> MarkAsReadAsync(string conversationId, string messageId, string userId)
    {
        var messageRef = _db.Collection("conversations")
            .Document(conversationId).Collection("messages").Document(messageId);
        var snapshot = await messageRef.GetSnapshotAsync();
        if (!snapshot.Exists) return null;

        var message = snapshot.ConvertTo<Message>();
        message.ReadBy ??= new Dictionary<string, DateTime>();
        if (!message.ReadBy.ContainsKey(userId))
        {
            message.ReadBy[userId] = DateTime.UtcNow;
            await messageRef.UpdateAsync("read_by", message.ReadBy);
        }

        // Reset unread count cho người đọc
        var convRef = _db.Collection("conversations").Document(conversationId);
        var convSnapshot = await convRef.GetSnapshotAsync();
        if (convSnapshot.Exists)
        {
            var conversation = convSnapshot.ConvertTo<Conversation>();
            var participant = conversation.Participants.FirstOrDefault(p => p.UserId == userId);
            if (participant != null)
            {
                participant.UnreadCount = 0;
                participant.LastReadMessageId = messageId;
                await convRef.UpdateAsync("participants", conversation.Participants);
            }
        }

        // Invalidate cache — SendMessageAsync dùng cache để tính UnreadCount,
        // nếu không xóa thì lần gửi tiếp theo sẽ dùng giá trị cũ (trước khi đọc).
        InvalidateConversationCache(conversationId);

        return message.SenderId;
    }

    /// <summary>Returns senderId of the message (for hub to notify).</summary>
    public async Task<string?> MarkAsDeliveredAsync(string conversationId, string messageId, string userId)
    {
        var messageRef = _db.Collection("conversations")
            .Document(conversationId).Collection("messages").Document(messageId);
        var snapshot = await messageRef.GetSnapshotAsync();
        if (!snapshot.Exists) return null;

        var message = snapshot.ConvertTo<Message>();
        message.DeliveredTo ??= new Dictionary<string, DateTime>();
        if (!message.DeliveredTo.ContainsKey(userId))
        {
            message.DeliveredTo[userId] = DateTime.UtcNow;
            await messageRef.UpdateAsync("delivered_to", message.DeliveredTo);
        }

        return message.SenderId;
    }

    #endregion

    #region Pin Message

    public async Task<ConversationResponse> PinMessageAsync(string conversationId, string messageId, string userId)
    {
        var convDoc = await _db.Collection("conversations").Document(conversationId).GetSnapshotAsync();
        if (!convDoc.Exists) throw new AppException(ErrorCode.CONVERSATION_NOT_FOUND);

        var conversation = convDoc.ConvertTo<Conversation>();
        var participant = RequireParticipant(conversation, userId);
        if (conversation.OnlyAdminCanEditInfo && participant.Role != "admin")
            throw new AppException(ErrorCode.FORBIDDEN);

        var msgDoc = await _db.Collection("conversations")
            .Document(conversationId).Collection("messages").Document(messageId).GetSnapshotAsync();
        if (!msgDoc.Exists) throw new AppException(ErrorCode.MESSAGE_NOT_FOUND);

        var msg = msgDoc.ConvertTo<Message>();

        await _db.Collection("conversations").Document(conversationId).UpdateAsync(
            new Dictionary<string, object>
            {
                { "pinned_message_id", messageId },
                { "pinned_message_content", msg.Content },
                { "updated_at", DateTime.UtcNow }
            });

        conversation.PinnedMessageId = messageId;
        conversation.PinnedMessageContent = msg.Content;

        await BroadcastToConversationAsync(conversation, "MessagePinned", new
        {
            ConversationId = conversationId,
            MessageId = messageId,
            Content = msg.Content,
            PinnedBy = userId
        });

        return await MapConversationToResponse(conversation, userId);
    }

    public async Task<ConversationResponse> UnpinMessageAsync(string conversationId, string userId)
    {
        var convDoc = await _db.Collection("conversations").Document(conversationId).GetSnapshotAsync();
        if (!convDoc.Exists) throw new AppException(ErrorCode.CONVERSATION_NOT_FOUND);

        var conversation = convDoc.ConvertTo<Conversation>();
        var participant = RequireParticipant(conversation, userId);
        if (conversation.OnlyAdminCanEditInfo && participant.Role != "admin")
            throw new AppException(ErrorCode.FORBIDDEN);

        if (conversation.PinnedMessageId == null)
            throw new AppException(ErrorCode.NO_PINNED_MESSAGE);

        await _db.Collection("conversations").Document(conversationId).UpdateAsync(
            new Dictionary<string, object>
            {
                { "pinned_message_id", FieldValue.Delete },
                { "pinned_message_content", FieldValue.Delete },
                { "updated_at", DateTime.UtcNow }
            });

        conversation.PinnedMessageId = null;
        conversation.PinnedMessageContent = null;

        await BroadcastToConversationAsync(conversation, "MessageUnpinned", new
        {
            ConversationId = conversationId,
            UnpinnedBy = userId
        });

        return await MapConversationToResponse(conversation, userId);
    }

    #endregion

    #region Disappearing Messages

    public async Task<ConversationSettingsResponse> SetDisappearingDurationAsync(
        string conversationId, DisappearingSettingRequest request, string userId)
    {
        var convDoc = await _db.Collection("conversations").Document(conversationId).GetSnapshotAsync();
        if (!convDoc.Exists) throw new AppException(ErrorCode.CONVERSATION_NOT_FOUND);

        var conversation = convDoc.ConvertTo<Conversation>();
        var participant = RequireParticipant(conversation, userId);

        // Only admin can change disappearing message settings in a group; either user in private chat
        if (conversation.Type == "group" && participant.Role != "admin")
            throw new AppException(ErrorCode.FORBIDDEN);

        int? newDuration = request.DurationSeconds > 0 ? request.DurationSeconds : null;
        await _db.Collection("conversations").Document(conversationId).UpdateAsync(
            "settings.disappearing_messages_duration", newDuration as object ?? FieldValue.Delete);

        conversation.Settings ??= new Models.Conversation.Settings();
        conversation.Settings.DisappearingMessagesDuration = newDuration;

        await BroadcastToConversationAsync(conversation, "DisappearingSettingChanged", new
        {
            ConversationId = conversationId,
            DurationSeconds = request.DurationSeconds,
            ChangedBy = userId
        });

        return MapSettingsToResponse(conversation.Settings);
    }

    #endregion

    #region Conversation Settings

    public async Task<ConversationSettingsResponse> GetConversationSettingsAsync(
        string conversationId, string userId)
    {
        var convDoc = await _db.Collection("conversations").Document(conversationId).GetSnapshotAsync();
        if (!convDoc.Exists) throw new AppException(ErrorCode.CONVERSATION_NOT_FOUND);

        var conversation = convDoc.ConvertTo<Conversation>();
        RequireParticipant(conversation, userId);

        return MapSettingsToResponse(conversation.Settings ?? new Models.Conversation.Settings());
    }

    public async Task<ConversationSettingsResponse> UpdateConversationSettingsAsync(
        string conversationId, ConversationSettingsRequest request, string userId)
    {
        var convDoc = await _db.Collection("conversations").Document(conversationId).GetSnapshotAsync();
        if (!convDoc.Exists) throw new AppException(ErrorCode.CONVERSATION_NOT_FOUND);

        var conversation = convDoc.ConvertTo<Conversation>();
        RequireParticipant(conversation, userId);

        var updates = new Dictionary<string, object>();
        var settings = conversation.Settings ?? new Models.Conversation.Settings();

        if (request.IsNotificationEnabled.HasValue)
        {
            updates["settings.is_notification_enabled"] = request.IsNotificationEnabled.Value;
            settings.IsNotificationEnabled = request.IsNotificationEnabled.Value;
        }
        if (request.Theme != null)
        {
            updates["settings.theme"] = request.Theme;
            settings.Theme = request.Theme;
        }
        if (request.BackgroundUrl != null)
        {
            updates["settings.background_url"] = request.BackgroundUrl;
            settings.BackgroundUrl = request.BackgroundUrl;
        }
        if (request.EmojiSet != null)
        {
            updates["settings.emoji_set"] = request.EmojiSet;
            settings.EmojiSet = request.EmojiSet;
        }
        if (request.AutoDownloadMedia.HasValue)
        {
            updates["settings.auto_download_media"] = request.AutoDownloadMedia.Value;
            settings.AutoDownloadMedia = request.AutoDownloadMedia.Value;
        }

        if (updates.Count > 0)
        {
            updates["updated_at"] = DateTime.UtcNow;
            await _db.Collection("conversations").Document(conversationId).UpdateAsync(updates);
        }

        return MapSettingsToResponse(settings);
    }

    #endregion

    #region Nickname

    public async Task<ParticipantResponse> SetNicknameAsync(
        string conversationId, string targetUserId, SetNicknameRequest request, string currentUserId)
    {
        var convDoc = await _db.Collection("conversations").Document(conversationId).GetSnapshotAsync();
        if (!convDoc.Exists) throw new AppException(ErrorCode.CONVERSATION_NOT_FOUND);

        var conversation = convDoc.ConvertTo<Conversation>();
        var currentParticipant = RequireParticipant(conversation, currentUserId);

        // Only the target user themselves or an admin can set the nickname
        if (targetUserId != currentUserId && currentParticipant.Role != "admin")
            throw new AppException(ErrorCode.FORBIDDEN);

        var target = conversation.Participants.FirstOrDefault(p => p.UserId == targetUserId)
            ?? throw new AppException(ErrorCode.USER_NOT_FOUND);

        var nickname = string.IsNullOrWhiteSpace(request.Nickname) ? null : request.Nickname.Trim();
        target.Nickname = nickname;

        await _db.Collection("conversations").Document(conversationId).UpdateAsync(
            new Dictionary<string, object>
            {
                { "participants", conversation.Participants },
                { "updated_at", DateTime.UtcNow }
            });

        await BroadcastToConversationAsync(conversation, "NicknameChanged", new
        {
            ConversationId = conversationId,
            UserId = targetUserId,
            Nickname = nickname,
            ChangedBy = currentUserId
        });

        var response = target.Adapt<ParticipantResponse>();
        response.IsOnline = await IsUserOnlineAsync(targetUserId);
        return response;
    }

    #endregion

    #region Group Settings

    public async Task<ConversationResponse> UpdateGroupSettingsAsync(
        string conversationId, GroupSettingsRequest request, string userId)
    {
        var (docRef, conversation) = await GetGroupConversationAsync(conversationId, userId);
        var participant = RequireParticipant(conversation, userId);
        if (participant.Role != "admin") throw new AppException(ErrorCode.FORBIDDEN);

        var updates = new Dictionary<string, object> { { "updated_at", DateTime.UtcNow } };

        if (request.OnlyAdminCanSend.HasValue)
        {
            updates["only_admin_can_send"] = request.OnlyAdminCanSend.Value;
            conversation.OnlyAdminCanSend = request.OnlyAdminCanSend.Value;
        }
        if (request.OnlyAdminCanEditInfo.HasValue)
        {
            updates["only_admin_can_edit_info"] = request.OnlyAdminCanEditInfo.Value;
            conversation.OnlyAdminCanEditInfo = request.OnlyAdminCanEditInfo.Value;
        }
        if (request.ApprovalRequiredToJoin.HasValue)
        {
            updates["approval_required_to_join"] = request.ApprovalRequiredToJoin.Value;
            conversation.ApprovalRequiredToJoin = request.ApprovalRequiredToJoin.Value;
        }

        await docRef.UpdateAsync(updates);

        await BroadcastToConversationAsync(conversation, "GroupSettingsChanged", new
        {
            ConversationId = conversationId,
            OnlyAdminCanSend = conversation.OnlyAdminCanSend,
            OnlyAdminCanEditInfo = conversation.OnlyAdminCanEditInfo,
            ApprovalRequiredToJoin = conversation.ApprovalRequiredToJoin,
            ChangedBy = userId
        });

        return await MapConversationToResponse(conversation, userId);
    }

    #endregion

    #region Join Requests

    public async Task<JoinRequestResponse> CreateJoinRequestAsync(string conversationId, string userId)
    {
        var convDoc = await _db.Collection("conversations").Document(conversationId).GetSnapshotAsync();
        if (!convDoc.Exists) throw new AppException(ErrorCode.CONVERSATION_NOT_FOUND);

        var conversation = convDoc.ConvertTo<Conversation>();

        if (!conversation.ApprovalRequiredToJoin)
            throw new AppException(ErrorCode.FORBIDDEN);

        if (conversation.Participants.Any(p => p.UserId == userId))
            throw new AppException(ErrorCode.ALREADY_PARTICIPANT);

        // Check for existing pending request
        var existingSnap = await _db.Collection("conversations").Document(conversationId)
            .Collection("join_requests")
            .WhereEqualTo("user_id", userId)
            .WhereEqualTo("status", "pending")
            .Limit(1)
            .GetSnapshotAsync();

        if (existingSnap.Count > 0)
            throw new AppException(ErrorCode.JOIN_REQUEST_ALREADY_EXISTS);

        var userDoc = await _db.Collection("users").Document(userId).GetSnapshotAsync();
        if (!userDoc.Exists) throw new AppException(ErrorCode.USER_NOT_FOUND);
        var user = userDoc.ConvertTo<Models.User>();

        var joinRequest = new JoinRequest
        {
            ConversationId = conversationId,
            UserId = userId,
            UserName = $"{user.FirstName} {user.LastName}".Trim(),
            Avatar = user.Avatar,
            CreatedAt = DateTime.UtcNow
        };

        var docRef = await _db.Collection("conversations").Document(conversationId)
            .Collection("join_requests").AddAsync(joinRequest);
        joinRequest.Id = docRef.Id;

        // Notify admins
        var admins = conversation.Participants.Where(p => p.Role == "admin");
        foreach (var admin in admins)
        {
            await _hub.Clients.Group($"user_{admin.UserId}").SendAsync("JoinRequestCreated", new
            {
                ConversationId = conversationId,
                Request = joinRequest.Adapt<JoinRequestResponse>()
            });
        }

        return joinRequest.Adapt<JoinRequestResponse>();
    }

    public async Task<List<JoinRequestResponse>> GetJoinRequestsAsync(string conversationId, string userId)
    {
        var (_, conversation) = await GetGroupConversationAsync(conversationId, userId);
        var participant = RequireParticipant(conversation, userId);
        if (participant.Role != "admin") throw new AppException(ErrorCode.FORBIDDEN);

        var snapshot = await _db.Collection("conversations").Document(conversationId)
            .Collection("join_requests")
            .WhereEqualTo("status", "pending")
            .GetSnapshotAsync();

        return snapshot.Documents
            .Select(doc => doc.ConvertTo<JoinRequest>().Adapt<JoinRequestResponse>())
            .ToList();
    }

    public async Task ReviewJoinRequestAsync(
        string conversationId, string requestUserId, bool approve, string adminUserId)
    {
        var (_, conversation) = await GetGroupConversationAsync(conversationId, adminUserId);
        var admin = RequireParticipant(conversation, adminUserId);
        if (admin.Role != "admin") throw new AppException(ErrorCode.FORBIDDEN);

        var reqSnap = await _db.Collection("conversations").Document(conversationId)
            .Collection("join_requests")
            .WhereEqualTo("user_id", requestUserId)
            .WhereEqualTo("status", "pending")
            .Limit(1)
            .GetSnapshotAsync();

        if (reqSnap.Count == 0) throw new AppException(ErrorCode.JOIN_REQUEST_NOT_FOUND);

        var reqDoc = reqSnap.Documents[0];
        await reqDoc.Reference.UpdateAsync(new Dictionary<string, object>
        {
            { "status", approve ? "approved" : "rejected" },
            { "reviewed_by", adminUserId },
            { "reviewed_at", DateTime.UtcNow }
        });

        if (approve)
        {
            await AddParticipantsAsync(
                new AddParticipantsRequest { ConversationId = conversationId, UserIds = new List<string> { requestUserId } },
                adminUserId);
        }

        await _hub.Clients.Group($"user_{requestUserId}").SendAsync("JoinRequestReviewed", new
        {
            ConversationId = conversationId,
            Approved = approve,
            ReviewedBy = adminUserId
        });
    }

    #endregion

    #region Online Status

    public async Task<bool> IsUserOnlineAsync(string userId) =>
        await _redis.IsOnlineAsync(userId);

    public async Task<OnlineStatusResponse> GetOnlineStatusAsync(string userId)
    {
        var isOnline = await _redis.IsOnlineAsync(userId);
        var lastSeen = isOnline ? null : await _redis.GetLastSeenAsync(userId);
        return new OnlineStatusResponse { UserId = userId, IsOnline = isOnline, LastSeen = lastSeen };
    }

    #endregion

    #region Helper Methods

    private static string ResolveDisplayName(Models.User user)
    {
        var full = $"{user.FirstName} {user.LastName}".Trim();
        if (!string.IsNullOrWhiteSpace(full)) return full;
        if (!string.IsNullOrWhiteSpace(user.Email))
            return user.Email.Split('@')[0];
        return user.Id;
    }

    private async Task<Conversation> GetConversationCachedAsync(string conversationId)
    {
        if (_convCache.TryGetValue(conversationId, out var cached) &&
            DateTime.UtcNow - cached.At < _convCacheTtl)
            return cached.Conv;

        var doc = await _db.Collection("conversations").Document(conversationId).GetSnapshotAsync();
        if (!doc.Exists) throw new AppException(ErrorCode.CONVERSATION_NOT_FOUND);
        var conv = doc.ConvertTo<Conversation>();
        _convCache[conversationId] = (conv, DateTime.UtcNow);
        return conv;
    }

    private async Task<Models.User> GetUserCachedAsync(string userId)
    {
        if (_userCache.TryGetValue(userId, out var cached) &&
            DateTime.UtcNow - cached.At < _userCacheTtl)
            return cached.User;

        var doc = await _db.Collection("users").Document(userId).GetSnapshotAsync();
        var user = doc.ConvertTo<Models.User>();
        _userCache[userId] = (user, DateTime.UtcNow);
        return user;
    }

    public static void InvalidateConversationCache(string conversationId) =>
        _convCache.TryRemove(conversationId, out _);

    public static void InvalidateUserCache(string userId) =>
        _userCache.TryRemove(userId, out _);

    public static void ClearAllUserCache() => _userCache.Clear();

    private async Task<Conversation?> FindPrivateConversationAsync(string userId1, string userId2)
    {
        var query = _db.Collection("conversations")
            .WhereEqualTo("type", "private")
            .WhereArrayContains("participant_ids", userId1);

        var snapshot = await query.GetSnapshotAsync();
        foreach (var doc in snapshot.Documents)
        {
            var conv = doc.ConvertTo<Conversation>();
            var ids = conv.Participants.Select(p => p.UserId).ToList();
            if (ids.Contains(userId2) && ids.Count == 2)
                return conv;
        }
        return null;
    }

    private async Task<(DocumentReference docRef, Conversation conversation)> GetGroupConversationAsync(
        string conversationId, string userId)
    {
        var docRef = _db.Collection("conversations").Document(conversationId);
        var snapshot = await docRef.GetSnapshotAsync();
        if (!snapshot.Exists) throw new AppException(ErrorCode.CONVERSATION_NOT_FOUND);

        var conversation = snapshot.ConvertTo<Conversation>();
        if (conversation.Type != "group") throw new AppException(ErrorCode.NOT_A_GROUP);

        return (docRef, conversation);
    }

    private static UserConver RequireParticipant(Conversation conversation, string userId)
    {
        var p = conversation.Participants.FirstOrDefault(p => p.UserId == userId);
        if (p == null) throw new AppException(ErrorCode.FORBIDDEN);
        return p;
    }

    private async Task<ConversationResponse> MapConversationToResponse(Conversation conversation, string currentUserId)
    {
        var response = conversation.Adapt<ConversationResponse>();

        var currentParticipant = conversation.Participants.FirstOrDefault(p => p.UserId == currentUserId);
        if (currentParticipant != null)
        {
            response.IsMuted = currentParticipant.IsMuted;
            response.IsPinned = currentParticipant.IsPinned;
            response.UnreadCount = currentParticipant.UnreadCount;
        }

        if (conversation.Type == "private")
        {
            var other = conversation.Participants.FirstOrDefault(p => p.UserId != currentUserId);
            if (other != null)
            {
                response.OtherUserId = other.UserId;
                response.OtherUserName = string.IsNullOrWhiteSpace(other.UserName)
                    ? other.UserId
                    : other.UserName;
                // UserName đã được set từ ResolveDisplayName khi tạo conversation
                response.OtherUserAvatar = other.Avatar;
                response.OtherUserLastSeen = other.LastSeen;
                response.OtherUserOnline = await IsUserOnlineAsync(other.UserId);
            }
        }

        response.Participants = new List<ParticipantResponse>();
        foreach (var p in conversation.Participants)
        {
            var pr = p.Adapt<ParticipantResponse>();
            pr.IsOnline = await IsUserOnlineAsync(p.UserId);
            response.Participants.Add(pr);
        }

        if (conversation.LastMessage != null)
            response.LastMessage = MapMessageToResponse(conversation.LastMessage, currentUserId);

        return response;
    }

    private static MessageResponse MapMessageToResponse(Message message, string currentUserId)
    {
        var response = message.Adapt<MessageResponse>();
        response.IsMine = message.SenderId == currentUserId;
        response.TotalReactions = message.Reactions?.Sum(r => r.Value.Count) ?? 0;
        response.Status = message.ReadBy?.Any() == true ? "read"
            : message.DeliveredTo?.Any() == true ? "delivered"
            : "sent";
        return response;
    }

    private static ConversationSettingsResponse MapSettingsToResponse(Models.Conversation.Settings settings) =>
        settings.Adapt<ConversationSettingsResponse>();

    private async Task BroadcastToConversationAsync(Conversation conversation, string eventName, object payload)
    {
        foreach (var p in conversation.Participants)
            await _hub.Clients.Group($"user_{p.UserId}").SendAsync(eventName, payload);
    }

    #endregion
}
