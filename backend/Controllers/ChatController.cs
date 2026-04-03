using backend.Models;
using backend.Services;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ChatController : ControllerBase
{
    private readonly FirebaseService _firebaseService;

    public ChatController(FirebaseService firebaseService)
    {
        _firebaseService = firebaseService;
    }

    [HttpPost("send")]
    public async Task<IActionResult> Send([FromBody] ChatSendRequest request)
    {
        if (request == null || string.IsNullOrWhiteSpace(request.SenderId) || string.IsNullOrWhiteSpace(request.RecipientId) || string.IsNullOrWhiteSpace(request.Content))
        {
            return BadRequest(new { error = "senderId, recipientId, and content are required." });
        }

        await _firebaseService.EnsureUserExistsAsync(request.SenderId.Trim(), request.SenderId.Trim());
        await _firebaseService.EnsureUserExistsAsync(request.RecipientId.Trim(), request.RecipientId.Trim());

        var conversationId = string.IsNullOrWhiteSpace(request.ConversationId)
            ? FirebaseService.GetConversationId(request.SenderId, request.RecipientId)
            : request.ConversationId.Trim();

        var message = new ChatMessage
        {
            SenderId = request.SenderId,
            RecipientId = request.RecipientId,
            Content = request.Content,
            Timestamp = DateTime.UtcNow
        };

        var messageId = await _firebaseService.SendChatMessageAsync(conversationId, message);
        return Ok(new { conversationId, messageId });
    }

    [HttpGet("{conversationId}/messages")]
    public async Task<IActionResult> GetMessages(string conversationId)
    {
        if (string.IsNullOrWhiteSpace(conversationId))
        {
            return BadRequest(new { error = "conversationId is required." });
        }

        var messages = await _firebaseService.GetChatMessagesAsync(conversationId);
        return Ok(messages);
    }

    [HttpGet("conversationId/{userA}/{userB}")]
    public IActionResult GetConversationId(string userA, string userB)
    {
        if (string.IsNullOrWhiteSpace(userA) || string.IsNullOrWhiteSpace(userB))
        {
            return BadRequest(new { error = "Both userA and userB are required." });
        }

        var conversationId = FirebaseService.GetConversationId(userA, userB);
        return Ok(new { conversationId });
    }
}
