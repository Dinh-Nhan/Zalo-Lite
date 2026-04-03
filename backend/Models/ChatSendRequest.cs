namespace backend.Models;

public class ChatSendRequest
{
    public string SenderId { get; set; } = null!;
    public string RecipientId { get; set; } = null!;
    public string Content { get; set; } = null!;
    public string? ConversationId { get; set; }
}
