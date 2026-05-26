namespace backend.dtos.Request.Chat;

public class AddParticipantsRequest
{
    public string ConversationId { get; set; } = null!;
    public List<string> UserIds { get; set; } = new();
}
