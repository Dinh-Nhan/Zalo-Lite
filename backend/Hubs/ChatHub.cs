using backend.dtos.Request.Chat;
using backend.dtos.Response.Chat;
using backend.Services;
using Microsoft.AspNetCore.SignalR;
using System.Collections.Concurrent;

namespace backend.Hubs;

public class ChatHub : Hub
{
    private readonly ChatService _chatService;
    private readonly ILogger<ChatHub> _logger;

    // Track online users: userId -> list of connectionIds
    private static readonly ConcurrentDictionary<string, HashSet<string>> _onlineUsers = new();

    // Track user connections: connectionId -> userId
    private static readonly ConcurrentDictionary<string, string> _connections = new();

    public ChatHub(ChatService chatService, ILogger<ChatHub> logger)
    {
        _chatService = chatService;
        _logger = logger;
    }

    #region Connection Management

    public override async Task OnConnectedAsync()
    {
        var userId = Context.GetHttpContext()?.Request.Query["userId"].ToString();

        if (!string.IsNullOrEmpty(userId))
        {
            var connectionId = Context.ConnectionId;

            // Add connection
            _connections[connectionId] = userId;

            if (!_onlineUsers.ContainsKey(userId))
            {
                _onlineUsers[userId] = new HashSet<string>();
            }
            _onlineUsers[userId].Add(connectionId);

            // Notify user's contacts that they are online
            await NotifyUserStatusChange(userId, true);

            _logger.LogInformation($"User {userId} connected with connection {connectionId}");
        }

        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var connectionId = Context.ConnectionId;

        if (_connections.TryRemove(connectionId, out var userId))
        {
            if (_onlineUsers.TryGetValue(userId, out var connections))
            {
                connections.Remove(connectionId);

                // If user has no more connections, mark as offline
                if (connections.Count == 0)
                {
                    _onlineUsers.TryRemove(userId, out _);
                    await NotifyUserStatusChange(userId, false);
                }
            }

            _logger.LogInformation($"User {userId} disconnected from connection {connectionId}");
        }

        await base.OnDisconnectedAsync(exception);
    }

    private async Task NotifyUserStatusChange(string userId, bool isOnline)
    {
        // Get user's conversations to notify participants
        try
        {
            var conversations = await _chatService.GetUserConversationsAsync(userId);
            var notifiedUsers = new HashSet<string>();

            foreach (var conversation in conversations)
            {
                foreach (var participant in conversation.Participants)
                {
                    if (participant.UserId != userId && !notifiedUsers.Contains(participant.UserId))
                    {
                        await SendToUser(participant.UserId, "UserStatusChanged", new
                        {
                            UserId = userId,
                            IsOnline = isOnline,
                            LastSeen = DateTime.UtcNow
                        });
                        notifiedUsers.Add(participant.UserId);
                    }
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error notifying user status change for {userId}");
        }
    }

    #endregion

    #region Messaging

    /// <summary>
    /// Send a message to a conversation
    /// </summary>
    public async Task SendMessage(SendMessageRequest request, string senderId)
    {
        try
        {
            var message = await _chatService.SendMessageAsync(request, senderId);

            // Get conversation to find recipients
            var conversation = await _chatService.GetConversationByIdAsync(request.ConversationId, senderId);

            // Send to all participants except sender
            foreach (var participant in conversation.Participants)
            {
                if (participant.UserId != senderId)
                {
                    await SendToUser(participant.UserId, "ReceiveMessage", message);

                    // Mark as delivered if user is online
                    if (IsUserOnline(participant.UserId))
                    {
                        await _chatService.MarkAsDeliveredAsync(request.ConversationId, message.Id, participant.UserId);
                    }
                }
            }

            // Send confirmation to sender
            await Clients.Caller.SendAsync("MessageSent", message);

            _logger.LogInformation($"Message {message.Id} sent in conversation {request.ConversationId}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending message");
            await Clients.Caller.SendAsync("Error", new { Message = ex.Message });
        }
    }

    /// <summary>
    /// User is typing indicator
    /// </summary>
    public async Task UserTyping(string conversationId, string userId, bool isTyping)
    {
        try
        {
            var conversation = await _chatService.GetConversationByIdAsync(conversationId, userId);

            // Notify other participants
            foreach (var participant in conversation.Participants)
            {
                if (participant.UserId != userId)
                {
                    await SendToUser(participant.UserId, "UserTyping", new
                    {
                        ConversationId = conversationId,
                        UserId = userId,
                        UserName = participant.UserName,
                        IsTyping = isTyping
                    });
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in UserTyping");
        }
    }

    /// <summary>
    /// Mark message as read
    /// </summary>
    public async Task MarkAsRead(string conversationId, string messageId, string userId)
    {
        try
        {
            await _chatService.MarkAsReadAsync(conversationId, messageId, userId);

            var conversation = await _chatService.GetConversationByIdAsync(conversationId, userId);

            // Notify sender about read receipt
            var message = (await _chatService.GetMessagesAsync(conversationId, userId, 1))
                .FirstOrDefault(m => m.Id == messageId);

            if (message != null)
            {
                await SendToUser(message.SenderId, "MessageRead", new
                {
                    ConversationId = conversationId,
                    MessageId = messageId,
                    ReadBy = userId,
                    ReadAt = DateTime.UtcNow
                });
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error marking message as read");
        }
    }

    /// <summary>
    /// Mark message as delivered
    /// </summary>
    public async Task MarkAsDelivered(string conversationId, string messageId, string userId)
    {
        try
        {
            await _chatService.MarkAsDeliveredAsync(conversationId, messageId, userId);

            var message = (await _chatService.GetMessagesAsync(conversationId, userId, 1))
                .FirstOrDefault(m => m.Id == messageId);

            if (message != null)
            {
                await SendToUser(message.SenderId, "MessageDelivered", new
                {
                    ConversationId = conversationId,
                    MessageId = messageId,
                    DeliveredTo = userId,
                    DeliveredAt = DateTime.UtcNow
                });
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error marking message as delivered");
        }
    }

    /// <summary>
    /// React to a message
    /// </summary>
    public async Task ReactToMessage(ReactToMessageRequest request, string userId)
    {
        try
        {
            var message = await _chatService.ReactToMessageAsync(request, userId);
            var conversation = await _chatService.GetConversationByIdAsync(request.ConversationId, userId);

            // Notify all participants
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

    /// <summary>
    /// Delete a message
    /// </summary>
    public async Task DeleteMessage(string conversationId, string messageId, string userId)
    {
        try
        {
            await _chatService.DeleteMessageAsync(conversationId, messageId, userId);
            var conversation = await _chatService.GetConversationByIdAsync(conversationId, userId);

            // Notify all participants
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

    /// <summary>
    /// Update/Edit a message
    /// </summary>
    public async Task UpdateMessage(UpdateMessageRequest request, string userId)
    {
        try
        {
            var message = await _chatService.UpdateMessageAsync(request, userId);
            var conversation = await _chatService.GetConversationByIdAsync(request.ConversationId, userId);

            // Notify all participants
            foreach (var participant in conversation.Participants)
            {
                await SendToUser(participant.UserId, "MessageUpdated", message);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating message");
            await Clients.Caller.SendAsync("Error", new { Message = ex.Message });
        }
    }

    #endregion

    #region Group Management

    /// <summary>
    /// Create a new conversation
    /// </summary>
    public async Task CreateConversation(CreateConversationRequest request, string userId)
    {
        try
        {
            var conversation = await _chatService.CreateConversationAsync(request, userId);

            // Notify all participants
            foreach (var participant in conversation.Participants)
            {
                await SendToUser(participant.UserId, "ConversationCreated", conversation);
            }

            await Clients.Caller.SendAsync("ConversationCreated", conversation);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating conversation");
            await Clients.Caller.SendAsync("Error", new { Message = ex.Message });
        }
    }

    /// <summary>
    /// Add participants to group
    /// </summary>
    public async Task AddParticipants(AddParticipantsRequest request, string userId)
    {
        try
        {
            var conversation = await _chatService.AddParticipantsAsync(request, userId);

            // Notify all participants including new ones
            foreach (var participant in conversation.Participants)
            {
                await SendToUser(participant.UserId, "ParticipantsAdded", new
                {
                    ConversationId = request.ConversationId,
                    AddedBy = userId,
                    NewParticipants = conversation.Participants.Where(p => request.UserIds.Contains(p.UserId)).ToList(),
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

    /// <summary>
    /// Remove participant from group
    /// </summary>
    public async Task RemoveParticipant(string conversationId, string userIdToRemove, string currentUserId)
    {
        try
        {
            await _chatService.RemoveParticipantAsync(conversationId, userIdToRemove, currentUserId);
            var conversation = await _chatService.GetConversationByIdAsync(conversationId, currentUserId);

            // Notify removed user
            await SendToUser(userIdToRemove, "RemovedFromConversation", new
            {
                ConversationId = conversationId,
                RemovedBy = currentUserId
            });

            // Notify remaining participants
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

    /// <summary>
    /// Update group info
    /// </summary>
    public async Task UpdateGroup(UpdateGroupRequest request, string userId)
    {
        try
        {
            var conversation = await _chatService.UpdateGroupAsync(request, userId);

            // Notify all participants
            foreach (var participant in conversation.Participants)
            {
                await SendToUser(participant.UserId, "GroupUpdated", conversation);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating group");
            await Clients.Caller.SendAsync("Error", new { Message = ex.Message });
        }
    }

    #endregion

    #region Helper Methods

    private async Task SendToUser(string userId, string method, object data)
    {
        if (_onlineUsers.TryGetValue(userId, out var connections))
        {
            foreach (var connectionId in connections)
            {
                await Clients.Client(connectionId).SendAsync(method, data);
            }
        }
    }

    private bool IsUserOnline(string userId)
    {
        return _onlineUsers.ContainsKey(userId) && _onlineUsers[userId].Count > 0;
    }

    public Task<List<string>> GetOnlineUsers(List<string> userIds)
    {
        return Task.FromResult(userIds.Where(IsUserOnline).ToList());
    }

    #endregion
}
