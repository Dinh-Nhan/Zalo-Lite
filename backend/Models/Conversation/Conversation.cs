using Google.Cloud.Firestore;

namespace backend.Models.Conversation;

public class Conversation
{
    [FirestoreDocumentId]
    private string Id {get; set;} = null!;

    /// <summary>
    /// private = chat rieng tu |
    /// group = nhom chat
    /// </summary>
    [FirestoreProperty("type")]
    private string Type {get; set;} = "private";

    [FirestoreProperty("participants")]
    private List<UserConver> UserConvers{get; set;} = null!;

    [FirestoreProperty("last_message")]
    private Message LastMessage {get; set;} = null!;

    [FirestoreProperty("settings")]
    private Settings SettingsMessage {get; set;} = null!;

    [FirestoreProperty("updated_at")]
    private DateTime UpdatedAt {get; set;} = DateTime.UtcNow;

    [FirestoreProperty("group_name")]
    private string GroupName {get; set;} = null!;

    [FirestoreProperty("group_avatar_url")]
    private string GroupAvatar {get; set;} = null!;

    [FirestoreProperty("pinned_message_id")]
    private string PinnedMessageId {get; set;} = null!;
}
