namespace backend.dtos.Request.Chat;

public class ReactToMessageRequest
{
    public string MessageId { get; set; } = null!;
    public string ConversationId { get; set; } = null!;

    /// <summary>
    /// Emoji: like, love, haha, wow, sad, angry, or custom emoji
    /// </summary>
    public string Emoji { get; set; } = null!;
}
