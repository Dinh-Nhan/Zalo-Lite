using backend.common;
using backend.dtos.Request.Chat;
using backend.Extensions;
using backend.Services;
using backend.Utils;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

[ApiController]
[Route("api/[controller]")]
[FirebaseAuthorize]
public class ChatController : ControllerBase
{
    private readonly ChatService _chatService;
    private readonly ILogger<ChatController> _logger;

    public ChatController(ChatService chatService, ILogger<ChatController> logger)
    {
        _chatService = chatService;
        _logger = logger;
    }

    #region Conversations

    /// <summary>
    /// Get all conversations for current user
    /// </summary>
    [HttpGet("conversations")]
    public async Task<IActionResult> GetConversations()
    {
        var userId = User.GetUid();
        var conversations = await _chatService.GetUserConversationsAsync(userId);

        return Ok(ApiResponse<object>.SuccessResponse(conversations, "Conversations retrieved successfully"));
    }

    /// <summary>
    /// Get conversation by ID
    /// </summary>
    [HttpGet("conversations/{conversationId}")]
    public async Task<IActionResult> GetConversation(string conversationId)
    {
        var userId = User.GetUid();
        var conversation = await _chatService.GetConversationByIdAsync(conversationId, userId);

        return Ok(ApiResponse<object>.SuccessResponse(conversation, "Conversation retrieved successfully"));
    }

    /// <summary>
    /// Create new conversation (private or group)
    /// </summary>
    [HttpPost("conversations")]
    public async Task<IActionResult> CreateConversation([FromBody] CreateConversationRequest request)
    {
        var userId = User.GetUid();
        var conversation = await _chatService.CreateConversationAsync(request, userId);

        return Ok(ApiResponse<object>.SuccessResponse(conversation, "Conversation created successfully"));
    }

    /// <summary>
    /// Update group information
    /// </summary>
    [HttpPut("conversations/group")]
    public async Task<IActionResult> UpdateGroup([FromBody] UpdateGroupRequest request)
    {
        var userId = User.GetUid();
        var conversation = await _chatService.UpdateGroupAsync(request, userId);

        return Ok(ApiResponse<object>.SuccessResponse(conversation, "Group updated successfully"));
    }

    /// <summary>
    /// Add participants to group
    /// </summary>
    [HttpPost("conversations/participants")]
    public async Task<IActionResult> AddParticipants([FromBody] AddParticipantsRequest request)
    {
        var userId = User.GetUid();
        var conversation = await _chatService.AddParticipantsAsync(request, userId);

        return Ok(ApiResponse<object>.SuccessResponse(conversation, "Participants added successfully"));
    }

    /// <summary>
    /// Remove participant from group
    /// </summary>
    [HttpDelete("conversations/{conversationId}/participants/{userIdToRemove}")]
    public async Task<IActionResult> RemoveParticipant(string conversationId, string userIdToRemove)
    {
        var userId = User.GetUid();
        await _chatService.RemoveParticipantAsync(conversationId, userIdToRemove, userId);

        return Ok(ApiResponse<object>.SuccessResponse(null, "Participant removed successfully"));
    }

    /// <summary>
    /// Delete/Leave conversation
    /// </summary>
    [HttpDelete("conversations/{conversationId}")]
    public async Task<IActionResult> DeleteConversation(string conversationId)
    {
        var userId = User.GetUid();
        await _chatService.DeleteConversationAsync(conversationId, userId);

        return Ok(ApiResponse<object>.SuccessResponse(null, "Conversation deleted successfully"));
    }

    #endregion

    #region Messages

    /// <summary>
    /// Get messages in a conversation
    /// </summary>
    [HttpGet("conversations/{conversationId}/messages")]
    public async Task<IActionResult> GetMessages(
        string conversationId,
        [FromQuery] int limit = 50,
        [FromQuery] string? beforeMessageId = null)
    {
        var userId = User.GetUid();
        var messages = await _chatService.GetMessagesAsync(conversationId, userId, limit, beforeMessageId);

        return Ok(ApiResponse<object>.SuccessResponse(messages, "Messages retrieved successfully"));
    }

    /// <summary>
    /// Send a message
    /// </summary>
    [HttpPost("messages")]
    public async Task<IActionResult> SendMessage([FromBody] SendMessageRequest request)
    {
        var userId = User.GetUid();
        var message = await _chatService.SendMessageAsync(request, userId);

        return Ok(ApiResponse<object>.SuccessResponse(message, "Message sent successfully"));
    }

    /// <summary>
    /// Update/Edit a message
    /// </summary>
    [HttpPut("messages")]
    public async Task<IActionResult> UpdateMessage([FromBody] UpdateMessageRequest request)
    {
        var userId = User.GetUid();
        var message = await _chatService.UpdateMessageAsync(request, userId);

        return Ok(ApiResponse<object>.SuccessResponse(message, "Message updated successfully"));
    }

    /// <summary>
    /// Delete a message
    /// </summary>
    [HttpDelete("conversations/{conversationId}/messages/{messageId}")]
    public async Task<IActionResult> DeleteMessage(string conversationId, string messageId)
    {
        var userId = User.GetUid();
        await _chatService.DeleteMessageAsync(conversationId, messageId, userId);

        return Ok(ApiResponse<object>.SuccessResponse(null, "Message deleted successfully"));
    }

    /// <summary>
    /// React to a message
    /// </summary>
    [HttpPost("messages/react")]
    public async Task<IActionResult> ReactToMessage([FromBody] ReactToMessageRequest request)
    {
        var userId = User.GetUid();
        var message = await _chatService.ReactToMessageAsync(request, userId);

        return Ok(ApiResponse<object>.SuccessResponse(message, "Reaction added successfully"));
    }

    /// <summary>
    /// Mark message as read
    /// </summary>
    [HttpPost("conversations/{conversationId}/messages/{messageId}/read")]
    public async Task<IActionResult> MarkAsRead(string conversationId, string messageId)
    {
        var userId = User.GetUid();
        await _chatService.MarkAsReadAsync(conversationId, messageId, userId);

        return Ok(ApiResponse<object>.SuccessResponse(null, "Message marked as read"));
    }

    /// <summary>
    /// Mark message as delivered
    /// </summary>
    [HttpPost("conversations/{conversationId}/messages/{messageId}/delivered")]
    public async Task<IActionResult> MarkAsDelivered(string conversationId, string messageId)
    {
        var userId = User.GetUid();
        await _chatService.MarkAsDeliveredAsync(conversationId, messageId, userId);

        return Ok(ApiResponse<object>.SuccessResponse(null, "Message marked as delivered"));
    }

    #endregion
}
