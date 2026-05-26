using Google.Cloud.Firestore;

namespace backend.Models.Conversation;

[FirestoreData]
public class Settings
{
    [FirestoreProperty("is_notification_enabled")]
    public bool IsNotificationEnabled { get; set; } = true;

    [FirestoreProperty("theme")]
    public string Theme { get; set; } = "default"; // default, dark, custom

    [FirestoreProperty("background_url")]
    public string? BackgroundUrl { get; set; }

    [FirestoreProperty("emoji_set")]
    public string EmojiSet { get; set; } = "default";

    [FirestoreProperty("auto_download_media")]
    public bool AutoDownloadMedia { get; set; } = true;

    [FirestoreProperty("disappearing_messages_duration")]
    public int? DisappearingMessagesDuration { get; set; } // in seconds, null = disabled
}
