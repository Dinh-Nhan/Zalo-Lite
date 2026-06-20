namespace backend.dtos.Response.Chat;

public class JoinRequestResponse
{
    public string Id { get; set; } = null!;
    public string ConversationId { get; set; } = null!;
    public string UserId { get; set; } = null!;
    public string UserName { get; set; } = null!;
    public string Avatar { get; set; } = null!;
    public string Status { get; set; } = null!;
    public string? ReviewedBy { get; set; }
    public DateTime? ReviewedAt { get; set; }
    public DateTime CreatedAt { get; set; }
}
