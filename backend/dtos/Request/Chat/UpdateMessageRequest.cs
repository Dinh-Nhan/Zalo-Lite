namespace backend.dtos.Request.Chat;

public class UpdateMessageRequest
{
    public string MessageId { get; set; } = null!;
    public string ConversationId { get; set; } = null!;
    public string NewContent { get; set; } = null!;
}
