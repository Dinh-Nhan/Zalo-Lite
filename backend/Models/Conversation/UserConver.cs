using Google.Cloud.Firestore;

namespace backend.Models.Conversation;

[FirestoreData]
public class UserConver
{
    [FirestoreProperty("user_id")]
    public string UserId { get; set; } = null!;

    [FirestoreProperty("user_name")]
    public string UserName { get; set; } = null!;

    [FirestoreProperty("avatar")]
    public string Avatar { get; set; } = null!;

    [FirestoreProperty("role")]
    public string Role { get; set; } = "member"; // admin, member

    [FirestoreProperty("joined_at")]
    public DateTime JoinedAt { get; set; } = DateTime.UtcNow;

    [FirestoreProperty("last_seen")]
    public DateTime? LastSeen { get; set; }

    [FirestoreProperty("is_muted")]
    public bool IsMuted { get; set; } = false;

    [FirestoreProperty("is_pinned")]
    public bool IsPinned { get; set; } = false;

    [FirestoreProperty("unread_count")]
    public int UnreadCount { get; set; } = 0;

    [FirestoreProperty("last_read_message_id")]
    public string? LastReadMessageId { get; set; }

    [FirestoreProperty("nickname")]
    public string? Nickname { get; set; } // Custom nickname in this conversation
}
