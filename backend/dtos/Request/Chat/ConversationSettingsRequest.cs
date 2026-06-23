namespace backend.dtos.Request.Chat;

public class ConversationSettingsRequest
{
    public bool? IsNotificationEnabled { get; set; }
    public string? Theme { get; set; }
    public string? BackgroundUrl { get; set; }
    public string? EmojiSet { get; set; }
    public bool? AutoDownloadMedia { get; set; }
}
