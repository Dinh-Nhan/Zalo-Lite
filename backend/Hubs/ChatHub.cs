using backend.dtos.Request.Chat;
using backend.dtos.Response.Chat;
using backend.Services;
using Microsoft.AspNetCore.SignalR;
using System.Collections.Concurrent;

namespace backend.Hubs;

public class ChatHub : Hub
{
    private readonly ChatService _chatService;
    private readonly RedisService _redis;
    private readonly ILogger<ChatHub> _logger;
    private readonly IHubContext<ChatHub> _hubContext;
    private readonly FcmService _fcm;
    private readonly UserService _userService;

    private static readonly ConcurrentDictionary<string, HashSet<string>> _onlineUsers = new();
    private static readonly ConcurrentDictionary<string, string> _connections = new();

    public ChatHub(ChatService chatService, RedisService redis, ILogger<ChatHub> logger,
        IHubContext<ChatHub> hubContext, FcmService fcm, UserService userService)
    {
        _chatService = chatService;
        _redis = redis;
        _logger = logger;
        _hubContext = hubContext;
        _fcm = fcm;
        _userService = userService;
    }

    #region Connection Management

    public override async Task OnConnectedAsync()
    {
        var userId = Context.GetHttpContext()?.Request.Query["userId"].ToString();

        if (!string.IsNullOrEmpty(userId))
        {
            var connectionId = Context.ConnectionId;
            _connections[connectionId] = userId;

            if (!_onlineUsers.ContainsKey(userId))
                _onlineUsers[userId] = new HashSet<string>();
            _onlineUsers[userId].Add(connectionId);

            // Join a per-user group so IHubContext<ChatHub> can target this user
            await Groups.AddToGroupAsync(connectionId, $"user_{userId}");

            // Persist online status in Redis
            await _redis.SetOnlineAsync(userId);

            await NotifyUserStatusChange(userId, isOnline: true);
            _logger.LogInformation("User {UserId} connected ({ConnectionId})", userId, connectionId);
        }

        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var connectionId = Context.ConnectionId;

        if (_connections.TryRemove(connectionId, out var userId))
        {
            await Groups.RemoveFromGroupAsync(connectionId, $"user_{userId}");

            if (_onlineUsers.TryGetValue(userId, out var connections))
            {
                connections.Remove(connectionId);

                if (connections.Count == 0)
                {
                    _onlineUsers.TryRemove(userId, out _);
                    await _redis.SetOfflineAsync(userId);
                    await NotifyUserStatusChange(userId, isOnline: false);
                }
            }

            _logger.LogInformation("User {UserId} disconnected ({ConnectionId})", userId, connectionId);
        }

        await base.OnDisconnectedAsync(exception);
    }

    /// <summary>Client calls this periodically to keep the online TTL alive.</summary>
    public async Task Heartbeat(string userId)
    {
        await _redis.RefreshOnlineTtlAsync(userId);
    }

    /// <summary>App came to foreground — mark user online.</summary>
    public async Task SetOnline(string userId)
    {
        await _redis.SetOnlineAsync(userId);
        await NotifyUserStatusChange(userId, isOnline: true);
    }

    /// <summary>App went to background — mark user offline.</summary>
    public async Task SetOffline(string userId)
    {
        await _redis.SetOfflineAsync(userId);
        await NotifyUserStatusChange(userId, isOnline: false);
    }

    private async Task NotifyUserStatusChange(string userId, bool isOnline)
    {
        try
        {
            var conversations = await _chatService.GetUserConversationsAsync(userId);
            var notified = new HashSet<string>();

            foreach (var conversation in conversations)
            {
                foreach (var participant in conversation.Participants)
                {
                    if (participant.UserId != userId && notified.Add(participant.UserId))
                    {
                        await SendToUser(participant.UserId, "UserStatusChanged", new
                        {
                            UserId = userId,
                            IsOnline = isOnline,
                            LastSeen = DateTime.UtcNow
                        });
                    }
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error notifying user status change for {UserId}", userId);
        }
    }

    #endregion

    #region Messaging

    public async Task SendMessage(SendMessageRequest request, string senderId)
    {
        try
        {
            var message = await _chatService.SendMessageAsync(request, senderId);

            // ParticipantIds được đính kèm từ SendMessageAsync — không cần query thêm
            var participantIds = message.ParticipantIds ?? new List<string>();

            // Broadcast + MessageSent song song, không chờ nhau
            var broadcastTasks = participantIds
                .Where(id => id != senderId)
                .Select(id => _hubContext.Clients.Group($"user_{id}").SendAsync("ReceiveMessage", message))
                .ToList();

            broadcastTasks.Add(Clients.Caller.SendAsync("MessageSent", message));
            await Task.WhenAll(broadcastTasks);

            // Mark delivered — fire and forget
            _ = Task.WhenAll(participantIds
                .Where(id => id != senderId && IsUserOnline(id))
                .Select(id => _chatService.MarkAsDeliveredAsync(request.ConversationId, message.Id, id)));

            // FCM cho user offline — fire and forget
            _ = Task.Run(async () =>
            {
                var body = message.Type switch
                {
                    "image"   => "Đã gửi một ảnh",
                    "video"   => "Đã gửi một video",
                    "audio"   => "Đã gửi một tin nhắn thoại",
                    "file"    => $"Đã gửi file: {message.FileName ?? "tệp đính kèm"}",
                    "sticker" => "Đã gửi nhãn dán",
                    "call"    => message.Content,
                    _         => message.Content,
                };
                var offlineIds = participantIds.Where(id => id != senderId && !IsUserOnline(id));
                foreach (var id in offlineIds)
                {
                    var token = await _userService.GetFcmTokenAsync(id);
                    if (!string.IsNullOrEmpty(token))
                        await _fcm.SendMessageNotificationAsync(
                            token,
                            message.NotificationTitle ?? message.SenderName,
                            body,
                            request.ConversationId,
                            message.SenderName,
                            message.IsGroupConversation);
                }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending message");
            await Clients.Caller.SendAsync("Error", new { Message = ex.Message });
        }
    }

    public async Task UserTyping(string conversationId, string userId, bool isTyping)
    {
        try
        {
            var conversation = await _chatService.GetConversationByIdAsync(conversationId, userId);
            foreach (var participant in conversation.Participants)
            {
                if (participant.UserId != userId)
                    await SendToUser(participant.UserId, "UserTyping", new
                    {
                        ConversationId = conversationId,
                        UserId = userId,
                        IsTyping = isTyping
                    });
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in UserTyping");
        }
    }

    public async Task MarkAsRead(string conversationId, string messageId, string userId)
    {
        try
        {
            var senderId = await _chatService.MarkAsReadAsync(conversationId, messageId, userId);
            if (senderId != null && senderId != userId)
            {
                await _hubContext.Clients.Group($"user_{senderId}").SendAsync("MessageRead", new
                {
                    conversation_id = conversationId,
                    message_id = messageId,
                    read_by = userId,
                    read_at = DateTime.UtcNow
                });
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error marking message as read");
        }
    }

    public async Task MarkAsDelivered(string conversationId, string messageId, string userId)
    {
        try
        {
            var senderId = await _chatService.MarkAsDeliveredAsync(conversationId, messageId, userId);
            if (senderId != null && senderId != userId)
            {
                await _hubContext.Clients.Group($"user_{senderId}").SendAsync("MessageDelivered", new
                {
                    conversation_id = conversationId,
                    message_id = messageId,
                    delivered_to = userId,
                    delivered_at = DateTime.UtcNow
                });
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error marking message as delivered");
        }
    }

    public async Task ReactToMessage(ReactToMessageRequest request, string userId)
    {
        try
        {
            var message = await _chatService.ReactToMessageAsync(request, userId);
            var conversation = await _chatService.GetConversationByIdAsync(request.ConversationId, userId);

            foreach (var participant in conversation.Participants)
            {
                await SendToUser(participant.UserId, "MessageReactionUpdated", new
                {
                    ConversationId = request.ConversationId,
                    MessageId = request.MessageId,
                    Reactions = message.Reactions,
                    UpdatedBy = userId
                });
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error reacting to message");
            await Clients.Caller.SendAsync("Error", new { Message = ex.Message });
        }
    }

    public async Task DeleteMessage(string conversationId, string messageId, string userId)
    {
        try
        {
            await _chatService.DeleteMessageAsync(conversationId, messageId, userId);
            var conversation = await _chatService.GetConversationByIdAsync(conversationId, userId);

            foreach (var participant in conversation.Participants)
            {
                await SendToUser(participant.UserId, "MessageDeleted", new
                {
                    ConversationId = conversationId,
                    MessageId = messageId,
                    DeletedBy = userId,
                    DeletedAt = DateTime.UtcNow
                });
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting message");
            await Clients.Caller.SendAsync("Error", new { Message = ex.Message });
        }
    }

    public async Task UpdateMessage(UpdateMessageRequest request, string userId)
    {
        try
        {
            var message = await _chatService.UpdateMessageAsync(request, userId);
            var conversation = await _chatService.GetConversationByIdAsync(request.ConversationId, userId);

            foreach (var participant in conversation.Participants)
                await SendToUser(participant.UserId, "MessageUpdated", message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating message");
            await Clients.Caller.SendAsync("Error", new { Message = ex.Message });
        }
    }

    #endregion

    #region Group Management

    public async Task CreateConversation(CreateConversationRequest request, string userId)
    {
        try
        {
            var conversation = await _chatService.CreateConversationAsync(request, userId);
            foreach (var participant in conversation.Participants)
                await SendToUser(participant.UserId, "ConversationCreated", conversation);

            await Clients.Caller.SendAsync("ConversationCreated", conversation);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating conversation");
            await Clients.Caller.SendAsync("Error", new { Message = ex.Message });
        }
    }

    public async Task AddParticipants(AddParticipantsRequest request, string userId)
    {
        try
        {
            var conversation = await _chatService.AddParticipantsAsync(request, userId);
            foreach (var participant in conversation.Participants)
            {
                await SendToUser(participant.UserId, "ParticipantsAdded", new
                {
                    ConversationId = request.ConversationId,
                    AddedBy = userId,
                    NewParticipants = conversation.Participants
                        .Where(p => request.UserIds.Contains(p.UserId)).ToList(),
                    Conversation = conversation
                });
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error adding participants");
            await Clients.Caller.SendAsync("Error", new { Message = ex.Message });
        }
    }

    public async Task RemoveParticipant(string conversationId, string userIdToRemove, string currentUserId)
    {
        try
        {
            await _chatService.RemoveParticipantAsync(conversationId, userIdToRemove, currentUserId);
            var conversation = await _chatService.GetConversationByIdAsync(conversationId, currentUserId);

            await SendToUser(userIdToRemove, "RemovedFromConversation", new
            {
                ConversationId = conversationId,
                RemovedBy = currentUserId
            });

            foreach (var participant in conversation.Participants)
            {
                await SendToUser(participant.UserId, "ParticipantRemoved", new
                {
                    ConversationId = conversationId,
                    RemovedUserId = userIdToRemove,
                    RemovedBy = currentUserId
                });
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error removing participant");
            await Clients.Caller.SendAsync("Error", new { Message = ex.Message });
        }
    }

    public async Task UpdateGroup(UpdateGroupRequest request, string userId)
    {
        try
        {
            var conversation = await _chatService.UpdateGroupAsync(request, userId);
            foreach (var participant in conversation.Participants)
                await SendToUser(participant.UserId, "GroupUpdated", conversation);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating group");
            await Clients.Caller.SendAsync("Error", new { Message = ex.Message });
        }
    }

    #endregion

    #region Call Signaling

    public async Task InitiateCall(string conversationId, string calleeId,
        string callType, string callerId, string callerName, string callerAvatar)
    {
        // 1. SignalR cho app đang mở
        await _hubContext.Clients.Group($"user_{calleeId}").SendAsync("IncomingCall", new
        {
            conversation_id = conversationId,
            caller_id       = callerId,
            caller_name     = callerName,
            caller_avatar   = callerAvatar,
            call_type       = callType
        });

        // 2. FCM cho app tắt/background — fire and forget
        _ = Task.Run(async () =>
        {
            var fcmToken = await _userService.GetFcmTokenAsync(calleeId);
            if (!string.IsNullOrEmpty(fcmToken))
            {
                await _fcm.SendCallNotificationAsync(
                    fcmToken, conversationId, callerId, callerName, callerAvatar, callType);
            }
        });
    }

    public async Task AcceptCall(string conversationId, string callerId)
    {
        await _hubContext.Clients.Group($"user_{callerId}").SendAsync("CallAccepted", new
        {
            conversation_id = conversationId
        });
    }

    public async Task RejectCall(string conversationId, string callerId, string reason = "rejected")
    {
        await _hubContext.Clients.Group($"user_{callerId}").SendAsync("CallRejected", new
        {
            conversation_id = conversationId,
            reason
        });
    }

    public async Task EndCall(string conversationId, string otherUserId)
    {
        await _hubContext.Clients.Group($"user_{otherUserId}").SendAsync("CallEnded", new
        {
            conversation_id = conversationId
        });
    }

    #endregion

    #region Helper Methods

    private async Task SendToUser(string userId, string method, object data)
    {
        if (_onlineUsers.TryGetValue(userId, out var connections))
        {
            foreach (var connectionId in connections)
                await Clients.Client(connectionId).SendAsync(method, data);
        }
    }

    private bool IsUserOnline(string userId) =>
        _onlineUsers.TryGetValue(userId, out var conns) && conns.Count > 0;

    public Task<List<string>> GetOnlineUsers(List<string> userIds) =>
        Task.FromResult(userIds.Where(IsUserOnline).ToList());

    public static bool IsUserOnlineStatic(string userId) =>
        _onlineUsers.TryGetValue(userId, out var conns) && conns.Count > 0;

    #endregion
}
