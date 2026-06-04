namespace backend.dtos.Response.Chat;

public class OnlineStatusResponse
{
    public string UserId { get; set; } = null!;
    public bool IsOnline { get; set; }
    public DateTime? LastSeen { get; set; }
}
