namespace backend.dtos.Response.Chat;

public class ConversationSettingsResponse
{
    public bool IsNotificationEnabled { get; set; }
    public string Theme { get; set; } = "default";
    public string? BackgroundUrl { get; set; }
    public string EmojiSet { get; set; } = "default";
    public bool AutoDownloadMedia { get; set; }
    public int? DisappearingMessagesDuration { get; set; }
}
