using Google.Cloud.Firestore;

namespace backend.Models.Conversation;

[FirestoreData]
public class Message
{
    [FirestoreDocumentId]
    public string Id { get; set; } = null!;

    [FirestoreProperty("conversation_id")]
    public string ConversationId { get; set; } = null!;

    [FirestoreProperty("sender_id")]
    public string SenderId { get; set; } = null!;

    [FirestoreProperty("sender_name")]
    public string SenderName { get; set; } = null!;

    [FirestoreProperty("sender_avatar")]
    public string SenderAvatar { get; set; } = null!;

    /// <summary>
    /// text, image, video, audio, file, sticker, location, contact, call
    /// </summary>
    [FirestoreProperty("type")]
    public string Type { get; set; } = "text";

    [FirestoreProperty("content")]
    public string Content { get; set; } = null!;

    /// <summary>
    /// For media messages (image, video, audio, file)
    /// </summary>
    [FirestoreProperty("media_url")]
    public string? MediaUrl { get; set; }

    [FirestoreProperty("thumbnail_url")]
    public string? ThumbnailUrl { get; set; }

    [FirestoreProperty("file_name")]
    public string? FileName { get; set; }

    [FirestoreProperty("file_size")]
    public long? FileSize { get; set; }

    [FirestoreProperty("duration")]
    public int? Duration { get; set; } // For audio/video in seconds

    /// <summary>
    /// Reply to another message
    /// </summary>
    [FirestoreProperty("reply_to_message_id")]
    public string? ReplyToMessageId { get; set; }

    [FirestoreProperty("reply_to_content")]
    public string? ReplyToContent { get; set; }

    [FirestoreProperty("reply_to_sender_name")]
    public string? ReplyToSenderName { get; set; }

    /// <summary>
    /// Forward from another conversation
    /// </summary>
    [FirestoreProperty("is_forwarded")]
    public bool IsForwarded { get; set; } = false;

    /// <summary>
    /// Reactions: like, love, haha, wow, sad, angry
    /// </summary>
    [FirestoreProperty("reactions")]
    public Dictionary<string, List<string>>? Reactions { get; set; } // {emoji: [userId1, userId2]}

    /// <summary>
    /// Message status
    /// </summary>
    [FirestoreProperty("is_deleted")]
    public bool IsDeleted { get; set; } = false;

    [FirestoreProperty("deleted_at")]
    public DateTime? DeletedAt { get; set; }

    [FirestoreProperty("is_edited")]
    public bool IsEdited { get; set; } = false;

    [FirestoreProperty("edited_at")]
    public DateTime? EditedAt { get; set; }

    /// <summary>
    /// Read receipts: userId -> timestamp
    /// </summary>
    [FirestoreProperty("read_by")]
    public Dictionary<string, DateTime>? ReadBy { get; set; }

    /// <summary>
    /// Delivered receipts: userId -> timestamp
    /// </summary>
    [FirestoreProperty("delivered_to")]
    public Dictionary<string, DateTime>? DeliveredTo { get; set; }

    [FirestoreProperty("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [FirestoreProperty("updated_at")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
