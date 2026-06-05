using backend.common;
using backend.dtos.Request.Chat;
using backend.Extensions;
using backend.Hubs;
using backend.Services;
using backend.Utils;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;

namespace backend.Controllers;

[ApiController]
[Route("api/[controller]")]
[FirebaseAuthorize]
public class ChatController : ControllerBase
{
    private readonly ChatService _chatService;
    private readonly ILogger<ChatController> _logger;
    private readonly IHubContext<ChatHub> _hubContext;
    private readonly FcmService _fcm;
    private readonly UserService _userService;

    public ChatController(ChatService chatService, ILogger<ChatController> logger,
        IHubContext<ChatHub> hubContext, FcmService fcm, UserService userService)
    {
        _chatService = chatService;
        _logger = logger;
        _hubContext = hubContext;
        _fcm = fcm;
        _userService = userService;
    }

    #region Conversations

    /// <summary>Get all conversations for current user</summary>
    [HttpGet("conversations")]
    public async Task<IActionResult> GetConversations()
    {
        var conversations = await _chatService.GetUserConversationsAsync(User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(conversations, "Conversations retrieved successfully"));
    }

    /// <summary>Get conversation by ID</summary>
    [HttpGet("conversations/{conversationId}")]
    public async Task<IActionResult> GetConversation(string conversationId)
    {
        var conversation = await _chatService.GetConversationByIdAsync(conversationId, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(conversation, "Conversation retrieved successfully"));
    }

    /// <summary>Create new conversation (private or group)</summary>
    [HttpPost("conversations")]
    public async Task<IActionResult> CreateConversation([FromBody] CreateConversationRequest request)
    {
        var conversation = await _chatService.CreateConversationAsync(request, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(conversation, "Conversation created successfully"));
    }

    /// <summary>Update group information (name, avatar, description)</summary>
    [HttpPut("conversations/group")]
    public async Task<IActionResult> UpdateGroup([FromBody] UpdateGroupRequest request)
    {
        var conversation = await _chatService.UpdateGroupAsync(request, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(conversation, "Group updated successfully"));
    }

    /// <summary>Add participants to group</summary>
    [HttpPost("conversations/participants")]
    public async Task<IActionResult> AddParticipants([FromBody] AddParticipantsRequest request)
    {
        var conversation = await _chatService.AddParticipantsAsync(request, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(conversation, "Participants added successfully"));
    }

    /// <summary>Remove participant from group (or leave if removing self)</summary>
    [HttpDelete("conversations/{conversationId}/participants/{userIdToRemove}")]
    public async Task<IActionResult> RemoveParticipant(string conversationId, string userIdToRemove)
    {
        await _chatService.RemoveParticipantAsync(conversationId, userIdToRemove, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(null, "Participant removed successfully"));
    }

    /// <summary>Leave / delete conversation</summary>
    [HttpDelete("conversations/{conversationId}")]
    public async Task<IActionResult> DeleteConversation(string conversationId)
    {
        await _chatService.DeleteConversationAsync(conversationId, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(null, "Conversation deleted successfully"));
    }

    #endregion

    #region Pin Message

    /// <summary>Pin a message in a conversation</summary>
    [HttpPost("conversations/{conversationId}/pin/{messageId}")]
    public async Task<IActionResult> PinMessage(string conversationId, string messageId)
    {
        var conversation = await _chatService.PinMessageAsync(conversationId, messageId, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(conversation, "Message pinned successfully"));
    }

    /// <summary>Unpin the current pinned message</summary>
    [HttpDelete("conversations/{conversationId}/pin")]
    public async Task<IActionResult> UnpinMessage(string conversationId)
    {
        var conversation = await _chatService.UnpinMessageAsync(conversationId, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(conversation, "Message unpinned successfully"));
    }

    #endregion

    #region Conversation Settings

    /// <summary>Get conversation settings (theme, background, emoji set, auto-download, disappearing)</summary>
    [HttpGet("conversations/{conversationId}/settings")]
    public async Task<IActionResult> GetConversationSettings(string conversationId)
    {
        var settings = await _chatService.GetConversationSettingsAsync(conversationId, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(settings, "Settings retrieved successfully"));
    }

    /// <summary>Update conversation settings (theme, background, emoji set, auto-download)</summary>
    [HttpPut("conversations/{conversationId}/settings")]
    public async Task<IActionResult> UpdateConversationSettings(
        string conversationId, [FromBody] ConversationSettingsRequest request)
    {
        var settings = await _chatService.UpdateConversationSettingsAsync(conversationId, request, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(settings, "Settings updated successfully"));
    }

    /// <summary>Set disappearing messages duration (0 = disabled, >0 = seconds)</summary>
    [HttpPut("conversations/{conversationId}/settings/disappearing")]
    public async Task<IActionResult> SetDisappearingDuration(
        string conversationId, [FromBody] DisappearingSettingRequest request)
    {
        var settings = await _chatService.SetDisappearingDurationAsync(conversationId, request, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(settings, "Disappearing messages setting updated"));
    }

    #endregion

    #region Nickname

    /// <summary>Set or clear a participant's nickname in the conversation</summary>
    [HttpPut("conversations/{conversationId}/members/{userId}/nickname")]
    public async Task<IActionResult> SetNickname(
        string conversationId, string userId, [FromBody] SetNicknameRequest request)
    {
        var participant = await _chatService.SetNicknameAsync(conversationId, userId, request, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(participant, "Nickname updated successfully"));
    }

    #endregion

    #region Group Settings

    /// <summary>Update group permission settings (admin only)</summary>
    [HttpPut("conversations/{conversationId}/group-settings")]
    public async Task<IActionResult> UpdateGroupSettings(
        string conversationId, [FromBody] GroupSettingsRequest request)
    {
        var conversation = await _chatService.UpdateGroupSettingsAsync(conversationId, request, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(conversation, "Group settings updated successfully"));
    }

    /// <summary>Request to join a conversation that requires approval</summary>
    [HttpPost("conversations/{conversationId}/join-requests")]
    public async Task<IActionResult> CreateJoinRequest(string conversationId)
    {
        var joinRequest = await _chatService.CreateJoinRequestAsync(conversationId, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(joinRequest, "Join request submitted successfully"));
    }

    /// <summary>List pending join requests (admin only)</summary>
    [HttpGet("conversations/{conversationId}/join-requests")]
    public async Task<IActionResult> GetJoinRequests(string conversationId)
    {
        var requests = await _chatService.GetJoinRequestsAsync(conversationId, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(requests, "Join requests retrieved successfully"));
    }

    /// <summary>Approve a join request (admin only)</summary>
    [HttpPost("conversations/{conversationId}/join-requests/{userId}/approve")]
    public async Task<IActionResult> ApproveJoinRequest(string conversationId, string userId)
    {
        await _chatService.ReviewJoinRequestAsync(conversationId, userId, approve: true, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(null, "Join request approved"));
    }

    /// <summary>Reject a join request (admin only)</summary>
    [HttpPost("conversations/{conversationId}/join-requests/{userId}/reject")]
    public async Task<IActionResult> RejectJoinRequest(string conversationId, string userId)
    {
        await _chatService.ReviewJoinRequestAsync(conversationId, userId, approve: false, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(null, "Join request rejected"));
    }

    #endregion

    #region Messages

    /// <summary>Get messages in a conversation (cursor pagination via beforeMessageId)</summary>
    [HttpGet("conversations/{conversationId}/messages")]
    public async Task<IActionResult> GetMessages(
        string conversationId,
        [FromQuery] int limit = 50,
        [FromQuery] string? beforeMessageId = null)
    {
        var messages = await _chatService.GetMessagesAsync(conversationId, User.GetUid(), limit, beforeMessageId);
        return Ok(ApiResponse<object>.SuccessResponse(messages, "Messages retrieved successfully"));
    }

    /// <summary>Send a message</summary>
    [HttpPost("messages")]
    public async Task<IActionResult> SendMessage([FromBody] SendMessageRequest request)
    {
        var userId = User.GetUid();
        var message = await _chatService.SendMessageAsync(request, userId);

        // Broadcast to other participants so they receive the message in real-time
        var participantIds = message.ParticipantIds ?? new List<string>();
        var broadcastTasks = participantIds
            .Where(id => id != userId)
            .Select(id => _hubContext.Clients.Group($"user_{id}").SendAsync("ReceiveMessage", message))
            .ToList();
        if (broadcastTasks.Count > 0)
            await Task.WhenAll(broadcastTasks);

        // FCM for offline participants — fire and forget
        _ = Task.Run(async () =>
        {
            var body = message.Type == "call" ? message.Content : message.Content;
            var offlineIds = participantIds.Where(id => id != userId && !ChatHub.IsUserOnlineStatic(id));
            foreach (var id in offlineIds)
            {
                var token = await _userService.GetFcmTokenAsync(id);
                if (!string.IsNullOrEmpty(token))
                    await _fcm.SendMessageNotificationAsync(
                        token,
                        message.NotificationTitle ?? message.SenderName,
                        body,
                        message.ConversationId,
                        message.SenderName,
                        message.IsGroupConversation);
            }
        });

        return Ok(ApiResponse<object>.SuccessResponse(message, "Message sent successfully"));
    }

    /// <summary>Edit a message (sender only)</summary>
    [HttpPut("messages")]
    public async Task<IActionResult> UpdateMessage([FromBody] UpdateMessageRequest request)
    {
        var message = await _chatService.UpdateMessageAsync(request, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(message, "Message updated successfully"));
    }

    /// <summary>Gỡ tin nhắn cho tất cả (sender only) — hiện "Tin nhắn đã bị gỡ"</summary>
    [HttpDelete("conversations/{conversationId}/messages/{messageId}")]
    public async Task<IActionResult> DeleteMessage(string conversationId, string messageId)
    {
        await _chatService.DeleteMessageAsync(conversationId, messageId, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(null, "Message deleted successfully"));
    }

    /// <summary>Ẩn tin nhắn chỉ ở phía mình — người kia vẫn thấy bình thường</summary>
    [HttpPost("conversations/{conversationId}/messages/{messageId}/hide")]
    public async Task<IActionResult> HideMessageForMe(string conversationId, string messageId)
    {
        await _chatService.HideMessageForMeAsync(conversationId, messageId, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(null, "Message hidden"));
    }

    /// <summary>React / un-react to a message (toggle)</summary>
    [HttpPost("messages/react")]
    public async Task<IActionResult> ReactToMessage([FromBody] ReactToMessageRequest request)
    {
        var message = await _chatService.ReactToMessageAsync(request, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(message, "Reaction updated successfully"));
    }

    /// <summary>Mark message as read</summary>
    [HttpPost("conversations/{conversationId}/messages/{messageId}/read")]
    public async Task<IActionResult> MarkAsRead(string conversationId, string messageId)
    {
        await _chatService.MarkAsReadAsync(conversationId, messageId, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(null, "Message marked as read"));
    }

    /// <summary>Mark message as delivered</summary>
    [HttpPost("conversations/{conversationId}/messages/{messageId}/delivered")]
    public async Task<IActionResult> MarkAsDelivered(string conversationId, string messageId)
    {
        await _chatService.MarkAsDeliveredAsync(conversationId, messageId, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(null, "Message marked as delivered"));
    }

    #endregion
}
