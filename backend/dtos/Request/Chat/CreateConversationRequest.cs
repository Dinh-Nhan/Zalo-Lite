namespace backend.dtos.Request.Chat;

public class CreateConversationRequest
{
    /// <summary>
    /// private or group
    /// </summary>
    public string Type { get; set; } = "private";

    /// <summary>
    /// List of user IDs to add to conversation
    /// </summary>
    public List<string> ParticipantIds { get; set; } = new();

    /// <summary>
    /// For group chat
    /// </summary>
    public string? GroupName { get; set; }

    public string? GroupAvatarUrl { get; set; }

    public string? GroupDescription { get; set; }
}
