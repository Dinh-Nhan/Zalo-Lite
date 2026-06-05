using Google.Cloud.Firestore;

namespace backend.Models.Conversation;

[FirestoreData]
public class JoinRequest
{
    [FirestoreDocumentId]
    public string Id { get; set; } = null!;

    [FirestoreProperty("conversation_id")]
    public string ConversationId { get; set; } = null!;

    [FirestoreProperty("user_id")]
    public string UserId { get; set; } = null!;

    [FirestoreProperty("user_name")]
    public string UserName { get; set; } = null!;

    [FirestoreProperty("avatar")]
    public string Avatar { get; set; } = null!;

    /// <summary>pending | approved | rejected</summary>
    [FirestoreProperty("status")]
    public string Status { get; set; } = "pending";

    [FirestoreProperty("reviewed_by")]
    public string? ReviewedBy { get; set; }

    [FirestoreProperty("reviewed_at")]
    public DateTime? ReviewedAt { get; set; }

    [FirestoreProperty("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
