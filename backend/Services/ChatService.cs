using backend.Attributes;
using backend.dtos.Request.Chat;
using backend.dtos.Response.Chat;
using backend.Enums;
using backend.Exceptions;
using backend.Models.Conversation;
using Google.Cloud.Firestore;
using Mapster;

namespace backend.Services;

[ScopedService]
public class ChatService
{
    private readonly FirestoreDb _db;
    private readonly ILogger<ChatService> _logger;

    public ChatService(FirestoreDb db, ILogger<ChatService> logger)
    {
        _db = db;
        _logger = logger;
    }

    #region Conversations

    /// <summary>
    /// Get all conversations for a user
    /// </summary>
    public async Task<List<ConversationResponse>> GetUserConversationsAsync(string userId)
    {
        var conversationsRef = _db.Collection("conversations");
        var query = conversationsRef.WhereArrayContains("participant_ids", userId);
        var snapshot = await query.GetSnapshotAsync();

        var conversations = new List<ConversationResponse>();

        foreach (var doc in snapshot.Documents)
        {
            var conversation = doc.ConvertTo<Conversation>();
            var response = await MapConversationToResponse(conversation, userId);
            conversations.Add(response);
        }

        return conversations.OrderByDescending(c => c.UpdatedAt).ToList();
    }

    /// <summary>
    /// Get conversation by ID
    /// </summary>
    public async Task<ConversationResponse> GetConversationByIdAsync(string conversationId, string userId)
    {
        var docRef = _db.Collection("conversations").Document(conversationId);
        var snapshot = await docRef.GetSnapshotAsync();

        if (!snapshot.Exists)
        {
            throw new AppException(ErrorCode.CONVERSATION_NOT_FOUND);
        }

        var conversation = snapshot.ConvertTo<Conversation>();

        // Check if user is participant
        if (!conversation.Participants.Any(p => p.UserId == userId))
        {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        return await MapConversationToResponse(conversation, userId);
    }

    /// <summary>
    /// Create new conversation (private or group)
    /// </summary>
    public async Task<ConversationResponse> CreateConversationAsync(CreateConversationRequest request, string currentUserId)
    {
        // For private chat, check if conversation already exists
        if (request.Type == "private")
        {
            if (request.ParticipantIds.Count != 1)
            {
                throw new AppException(ErrorCode.CANNOT_SELF_MESSAGE);
            }

            var otherUserId = request.ParticipantIds[0];
            var existing = await FindPrivateConversationAsync(currentUserId, otherUserId);
            if (existing != null)
            {
                return await MapConversationToResponse(existing, currentUserId);
            }
        }

        // Get user info for all participants
        var allParticipantIds = new List<string>(request.ParticipantIds) { currentUserId };
        var participants = new List<UserConver>();

        foreach (var userId in allParticipantIds.Distinct())
        {
            var userDoc = await _db.Collection("users").Document(userId).GetSnapshotAsync();
            if (!userDoc.Exists)
            {
                throw new AppException(ErrorCode.USER_NOT_FOUND);
            }

            var user = userDoc.ConvertTo<Models.User>();
            participants.Add(new UserConver
            {
                UserId = user.Id,
                UserName = $"{user.FirstName} {user.LastName}".Trim(),
                Avatar = user.Avatar,
                Role = userId == currentUserId && request.Type == "group" ? "admin" : "member",
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
            CreatedBy = currentUserId
        };

        if (request.Type == "group")
        {
            conversation.GroupName = request.GroupName ?? "New Group";
            conversation.GroupAvatarUrl = request.GroupAvatarUrl;
            conversation.GroupDescription = request.GroupDescription;
        }

        var docRef = await _db.Collection("conversations").AddAsync(conversation);
        conversation.Id = docRef.Id;

        // Update document with participant_ids array for querying
        await docRef.UpdateAsync("participant_ids", allParticipantIds.Distinct().ToList());

        return await MapConversationToResponse(conversation, currentUserId);
    }

    /// <summary>
    /// Update group info
    /// </summary>
    public async Task<ConversationResponse> UpdateGroupAsync(UpdateGroupRequest request, string userId)
    {
        var docRef = _db.Collection("conversations").Document(request.ConversationId);
        var snapshot = await docRef.GetSnapshotAsync();

        if (!snapshot.Exists)
        {
            throw new AppException(ErrorCode.CONVERSATION_NOT_FOUND);
        }

        var conversation = snapshot.ConvertTo<Conversation>();

        if (conversation.Type != "group")
        {
            throw new AppException(ErrorCode.CANNOT_SELF_MESSAGE);
        }

        var participant = conversation.Participants.FirstOrDefault(p => p.UserId == userId);
        if (participant == null)
        {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        if (conversation.OnlyAdminCanEditInfo && participant.Role != "admin")
        {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        var updates = new Dictionary<string, object>
        {
            { "updated_at", DateTime.UtcNow }
        };

        if (request.GroupName != null)
        {
            updates["group_name"] = request.GroupName;
            conversation.GroupName = request.GroupName;
        }

        if (request.GroupAvatarUrl != null)
        {
            updates["group_avatar_url"] = request.GroupAvatarUrl;
            conversation.GroupAvatarUrl = request.GroupAvatarUrl;
        }

        if (request.GroupDescription != null)
        {
            updates["group_description"] = request.GroupDescription;
            conversation.GroupDescription = request.GroupDescription;
        }

        await docRef.UpdateAsync(updates);

        return await MapConversationToResponse(conversation, userId);
    }

    /// <summary>
    /// Add participants to group
    /// </summary>
    public async Task<ConversationResponse> AddParticipantsAsync(AddParticipantsRequest request, string userId)
    {
        var docRef = _db.Collection("conversations").Document(request.ConversationId);
        var snapshot = await docRef.GetSnapshotAsync();

        if (!snapshot.Exists)
        {
            throw new AppException(ErrorCode.CONVERSATION_NOT_FOUND);
        }

        var conversation = snapshot.ConvertTo<Conversation>();

        if (conversation.Type != "group")
        {
            throw new AppException(ErrorCode.CANNOT_SELF_MESSAGE);
        }

        var currentParticipant = conversation.Participants.FirstOrDefault(p => p.UserId == userId);
        if (currentParticipant == null)
        {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        // Get new participants info
        var newParticipants = new List<UserConver>();
        foreach (var newUserId in request.UserIds)
        {
            if (conversation.Participants.Any(p => p.UserId == newUserId))
            {
                continue; // Already a participant
            }

            var userDoc = await _db.Collection("users").Document(newUserId).GetSnapshotAsync();
            if (!userDoc.Exists) continue;

            var user = userDoc.ConvertTo<Models.User>();
            newParticipants.Add(new UserConver
            {
                UserId = user.Id,
                UserName = $"{user.FirstName} {user.LastName}".Trim(),
                Avatar = user.Avatar,
                Role = "member",
                JoinedAt = DateTime.UtcNow
            });
        }

        if (newParticipants.Any())
        {
            conversation.Participants.AddRange(newParticipants);
            var allParticipantIds = conversation.Participants.Select(p => p.UserId).ToList();

            await docRef.UpdateAsync(new Dictionary<string, object>
            {
                { "participants", conversation.Participants },
                { "participant_ids", allParticipantIds },
                { "updated_at", DateTime.UtcNow }
            });
        }

        return await MapConversationToResponse(conversation, userId);
    }

    /// <summary>
    /// Remove participant from group
    /// </summary>
    public async Task RemoveParticipantAsync(string conversationId, string userIdToRemove, string currentUserId)
    {
        var docRef = _db.Collection("conversations").Document(conversationId);
        var snapshot = await docRef.GetSnapshotAsync();

        if (!snapshot.Exists)
        {
            throw new AppException(ErrorCode.CONVERSATION_NOT_FOUND);
        }

        var conversation = snapshot.ConvertTo<Conversation>();

        if (conversation.Type != "group")
        {
            throw new AppException(ErrorCode.CANNOT_SELF_MESSAGE);
        }

        var currentParticipant = conversation.Participants.FirstOrDefault(p => p.UserId == currentUserId);
        if (currentParticipant == null)
        {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        // Can remove yourself or if you're admin
        if (userIdToRemove != currentUserId && currentParticipant.Role != "admin")
        {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        conversation.Participants.RemoveAll(p => p.UserId == userIdToRemove);
        var allParticipantIds = conversation.Participants.Select(p => p.UserId).ToList();

        await docRef.UpdateAsync(new Dictionary<string, object>
        {
            { "participants", conversation.Participants },
            { "participant_ids", allParticipantIds },
            { "updated_at", DateTime.UtcNow }
        });
    }

    /// <summary>
    /// Delete conversation (leave for user)
    /// </summary>
    public async Task DeleteConversationAsync(string conversationId, string userId)
    {
        var docRef = _db.Collection("conversations").Document(conversationId);
        var snapshot = await docRef.GetSnapshotAsync();

        if (!snapshot.Exists)
        {
            throw new AppException(ErrorCode.CONVERSATION_NOT_FOUND);
        }

        var conversation = snapshot.ConvertTo<Conversation>();

        if (!conversation.Participants.Any(p => p.UserId == userId))
        {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        // For private chat or if user is leaving group
        await RemoveParticipantAsync(conversationId, userId, userId);
    }

    #endregion

    #region Messages

    /// <summary>
    /// Get messages in a conversation
    /// </summary>
    public async Task<List<MessageResponse>> GetMessagesAsync(string conversationId, string userId, int limit = 50, string? beforeMessageId = null)
    {
        // Verify user is participant
        var convDoc = await _db.Collection("conversations").Document(conversationId).GetSnapshotAsync();
        if (!convDoc.Exists)
        {
            throw new AppException(ErrorCode.CONVERSATION_NOT_FOUND);
        }

        var conversation = convDoc.ConvertTo<Conversation>();
        if (!conversation.Participants.Any(p => p.UserId == userId))
        {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        var messagesRef = _db.Collection("conversations").Document(conversationId).Collection("messages");
        Query query = messagesRef.OrderByDescending("created_at").Limit(limit);

        if (beforeMessageId != null)
        {
            var beforeDoc = await messagesRef.Document(beforeMessageId).GetSnapshotAsync();
            if (beforeDoc.Exists)
            {
                query = query.StartAfter(beforeDoc);
            }
        }

        var snapshot = await query.GetSnapshotAsync();
        var messages = new List<MessageResponse>();

        foreach (var doc in snapshot.Documents)
        {
            var message = doc.ConvertTo<Message>();
            var response = MapMessageToResponse(message, userId);
            messages.Add(response);
        }

        return messages.OrderBy(m => m.CreatedAt).ToList();
    }

    /// <summary>
    /// Send a message
    /// </summary>
    public async Task<MessageResponse> SendMessageAsync(SendMessageRequest request, string senderId)
    {
        // Verify conversation exists and user is participant
        var convDoc = await _db.Collection("conversations").Document(request.ConversationId).GetSnapshotAsync();
        if (!convDoc.Exists)
        {
            throw new AppException(ErrorCode.CONVERSATION_NOT_FOUND);
        }

        var conversation = convDoc.ConvertTo<Conversation>();
        var participant = conversation.Participants.FirstOrDefault(p => p.UserId == senderId);

        if (participant == null)
        {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        if (conversation.OnlyAdminCanSend && participant.Role != "admin")
        {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        // Get sender info
        var senderDoc = await _db.Collection("users").Document(senderId).GetSnapshotAsync();
        var sender = senderDoc.ConvertTo<Models.User>();

        var message = new Message
        {
            ConversationId = request.ConversationId,
            SenderId = senderId,
            SenderName = $"{sender.FirstName} {sender.LastName}".Trim(),
            SenderAvatar = sender.Avatar,
            Type = request.Type,
            Content = request.Content,
            MediaUrl = request.MediaUrl,
            ThumbnailUrl = request.ThumbnailUrl,
            FileName = request.FileName,
            FileSize = request.FileSize,
            Duration = request.Duration,
            ReplyToMessageId = request.ReplyToMessageId,
            IsForwarded = request.IsForwarded,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
            DeliveredTo = new Dictionary<string, DateTime>(),
            ReadBy = new Dictionary<string, DateTime>()
        };

        // If replying, get reply info
        if (request.ReplyToMessageId != null)
        {
            var replyDoc = await _db.Collection("conversations")
                .Document(request.ConversationId)
                .Collection("messages")
                .Document(request.ReplyToMessageId)
                .GetSnapshotAsync();

            if (replyDoc.Exists)
            {
                var replyMsg = replyDoc.ConvertTo<Message>();
                message.ReplyToContent = replyMsg.Content;
                message.ReplyToSenderName = replyMsg.SenderName;
            }
        }

        // Save message
        var messageRef = await _db.Collection("conversations")
            .Document(request.ConversationId)
            .Collection("messages")
            .AddAsync(message);

        message.Id = messageRef.Id;

        // Update conversation last message
        await _db.Collection("conversations").Document(request.ConversationId).UpdateAsync(new Dictionary<string, object>
        {
            { "last_message", message },
            { "updated_at", DateTime.UtcNow }
        });

        // Update unread count for other participants
        foreach (var p in conversation.Participants.Where(p => p.UserId != senderId))
        {
            p.UnreadCount++;
        }

        await _db.Collection("conversations").Document(request.ConversationId).UpdateAsync(
            "participants", conversation.Participants
        );

        return MapMessageToResponse(message, senderId);
    }

    /// <summary>
    /// Update/Edit a message
    /// </summary>
    public async Task<MessageResponse> UpdateMessageAsync(UpdateMessageRequest request, string userId)
    {
        var messageRef = _db.Collection("conversations")
            .Document(request.ConversationId)
            .Collection("messages")
            .Document(request.MessageId);

        var snapshot = await messageRef.GetSnapshotAsync();
        if (!snapshot.Exists)
        {
            throw new AppException(ErrorCode.CONVERSATION_NOT_FOUND);
        }

        var message = snapshot.ConvertTo<Message>();

        if (message.SenderId != userId)
        {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

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

    /// <summary>
    /// Delete a message
    /// </summary>
    public async Task DeleteMessageAsync(string conversationId, string messageId, string userId)
    {
        var messageRef = _db.Collection("conversations")
            .Document(conversationId)
            .Collection("messages")
            .Document(messageId);

        var snapshot = await messageRef.GetSnapshotAsync();
        if (!snapshot.Exists)
        {
            throw new AppException(ErrorCode.CONVERSATION_NOT_FOUND);
        }

        var message = snapshot.ConvertTo<Message>();

        if (message.SenderId != userId)
        {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        await messageRef.UpdateAsync(new Dictionary<string, object>
        {
            { "is_deleted", true },
            { "deleted_at", DateTime.UtcNow },
            { "content", "Message has been deleted" },
            { "updated_at", DateTime.UtcNow }
        });
    }

    /// <summary>
    /// React to a message
    /// </summary>
    public async Task<MessageResponse> ReactToMessageAsync(ReactToMessageRequest request, string userId)
    {
        var messageRef = _db.Collection("conversations")
            .Document(request.ConversationId)
            .Collection("messages")
            .Document(request.MessageId);

        var snapshot = await messageRef.GetSnapshotAsync();
        if (!snapshot.Exists)
        {
            throw new AppException(ErrorCode.CONVERSATION_NOT_FOUND);
        }

        var message = snapshot.ConvertTo<Message>();
        message.Reactions ??= new Dictionary<string, List<string>>();

        // Toggle reaction
        if (message.Reactions.ContainsKey(request.Emoji))
        {
            if (message.Reactions[request.Emoji].Contains(userId))
            {
                message.Reactions[request.Emoji].Remove(userId);
                if (message.Reactions[request.Emoji].Count == 0)
                {
                    message.Reactions.Remove(request.Emoji);
                }
            }
            else
            {
                message.Reactions[request.Emoji].Add(userId);
            }
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

    /// <summary>
    /// Mark messages as read
    /// </summary>
    public async Task MarkAsReadAsync(string conversationId, string messageId, string userId)
    {
        var messageRef = _db.Collection("conversations")
            .Document(conversationId)
            .Collection("messages")
            .Document(messageId);

        var snapshot = await messageRef.GetSnapshotAsync();
        if (!snapshot.Exists) return;

        var message = snapshot.ConvertTo<Message>();
        message.ReadBy ??= new Dictionary<string, DateTime>();

        if (!message.ReadBy.ContainsKey(userId))
        {
            message.ReadBy[userId] = DateTime.UtcNow;
            await messageRef.UpdateAsync("read_by", message.ReadBy);
        }

        // Update unread count in conversation
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
    }

    /// <summary>
    /// Mark message as delivered
    /// </summary>
    public async Task MarkAsDeliveredAsync(string conversationId, string messageId, string userId)
    {
        var messageRef = _db.Collection("conversations")
            .Document(conversationId)
            .Collection("messages")
            .Document(messageId);

        var snapshot = await messageRef.GetSnapshotAsync();
        if (!snapshot.Exists) return;

        var message = snapshot.ConvertTo<Message>();
        message.DeliveredTo ??= new Dictionary<string, DateTime>();

        if (!message.DeliveredTo.ContainsKey(userId))
        {
            message.DeliveredTo[userId] = DateTime.UtcNow;
            await messageRef.UpdateAsync("delivered_to", message.DeliveredTo);
        }
    }

    #endregion

    #region Helper Methods

    private async Task<Conversation?> FindPrivateConversationAsync(string userId1, string userId2)
    {
        var query = _db.Collection("conversations")
            .WhereEqualTo("type", "private")
            .WhereArrayContains("participant_ids", userId1);

        var snapshot = await query.GetSnapshotAsync();

        foreach (var doc in snapshot.Documents)
        {
            var conv = doc.ConvertTo<Conversation>();
            var participantIds = conv.Participants.Select(p => p.UserId).ToList();

            if (participantIds.Contains(userId2) && participantIds.Count == 2)
            {
                return conv;
            }
        }

        return null;
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

        // For private chat, set other user info
        if (conversation.Type == "private")
        {
            var otherParticipant = conversation.Participants.FirstOrDefault(p => p.UserId != currentUserId);
            if (otherParticipant != null)
            {
                response.OtherUserId = otherParticipant.UserId;
                response.OtherUserName = otherParticipant.UserName;
                response.OtherUserAvatar = otherParticipant.Avatar;
                response.OtherUserLastSeen = otherParticipant.LastSeen;

                // Check online status from Redis or other real-time source
                response.OtherUserOnline = await IsUserOnlineAsync(otherParticipant.UserId);
            }
        }

        // Map participants with online status
        response.Participants = new List<ParticipantResponse>();
        foreach (var p in conversation.Participants)
        {
            var participantResponse = p.Adapt<ParticipantResponse>();
            participantResponse.IsOnline = await IsUserOnlineAsync(p.UserId);
            response.Participants.Add(participantResponse);
        }

        if (conversation.LastMessage != null)
        {
            response.LastMessage = MapMessageToResponse(conversation.LastMessage, currentUserId);
        }

        return response;
    }

    private MessageResponse MapMessageToResponse(Message message, string currentUserId)
    {
        var response = message.Adapt<MessageResponse>();
        response.IsMine = message.SenderId == currentUserId;
        response.TotalReactions = message.Reactions?.Sum(r => r.Value.Count) ?? 0;

        // Determine message status
        if (message.ReadBy != null && message.ReadBy.Any())
        {
            response.Status = "read";
        }
        else if (message.DeliveredTo != null && message.DeliveredTo.Any())
        {
            response.Status = "delivered";
        }
        else
        {
            response.Status = "sent";
        }

        return response;
    }

    private Task<bool> IsUserOnlineAsync(string userId)
    {
        // TODO: Implement with Redis or SignalR connection tracking
        // For now, return false
        return Task.FromResult(false);
    }

    #endregion
}
