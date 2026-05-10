namespace backend.dtos.Request.Chat;

public class UpdateGroupRequest
{
    public string ConversationId { get; set; } = null!;
    public string? GroupName { get; set; }
    public string? GroupAvatarUrl { get; set; }
    public string? GroupDescription { get; set; }
}
