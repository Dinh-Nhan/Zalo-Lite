using Google.Cloud.Firestore;

namespace backend.Models.Conversation;

[FirestoreData]
public class Conversation
{
    [FirestoreDocumentId]
    public string Id { get; set; } = null!;

    /// <summary>
    /// private = chat rieng tu |
    /// group = nhom chat
    /// </summary>
    [FirestoreProperty("type")]
    public string Type { get; set; } = "private";

    [FirestoreProperty("participants")]
    public List<UserConver> Participants { get; set; } = new();

    [FirestoreProperty("last_message")]
    public Message? LastMessage { get; set; }

    [FirestoreProperty("settings")]
    public Settings Settings { get; set; } = new();

    [FirestoreProperty("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [FirestoreProperty("updated_at")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Group specific fields
    [FirestoreProperty("group_name")]
    public string? GroupName { get; set; }

    [FirestoreProperty("group_avatar_url")]
    public string? GroupAvatarUrl { get; set; }

    [FirestoreProperty("group_description")]
    public string? GroupDescription { get; set; }

    [FirestoreProperty("created_by")]
    public string? CreatedBy { get; set; }

    // Pinned message
    [FirestoreProperty("pinned_message_id")]
    public string? PinnedMessageId { get; set; }

    [FirestoreProperty("pinned_message_content")]
    public string? PinnedMessageContent { get; set; }

    // Group settings
    [FirestoreProperty("only_admin_can_send")]
    public bool OnlyAdminCanSend { get; set; } = false;

    [FirestoreProperty("only_admin_can_edit_info")]
    public bool OnlyAdminCanEditInfo { get; set; } = true;

    [FirestoreProperty("approval_required_to_join")]
    public bool ApprovalRequiredToJoin { get; set; } = false;

    [FirestoreProperty("is_archived")]
    public bool IsArchived { get; set; } = false;
}
