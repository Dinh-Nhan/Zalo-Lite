using Google.Cloud.Firestore;

namespace backend.Models;

[FirestoreData]
public class MessageMetadata
{
    [FirestoreProperty("width")]
    public int? Width { get; set; }

    [FirestoreProperty("height")]
    public int? Height { get; set; }

    [FirestoreProperty("size")]
    public string? Size { get; set; }

    [FirestoreProperty("call_id")]
    public string? CallId { get; set; }

    [FirestoreProperty("call_type")]
    public string? CallType { get; set; }

    [FirestoreProperty("duration")]
    public int? Duration { get; set; } // in seconds

    [FirestoreProperty("status")]
    public string? Status { get; set; } // completed, missed, declined
}

[FirestoreData]
public class Message
{
    [FirestoreDocumentId]
    public string Id { get; set; } = null!;

    [FirestoreProperty("conversation_id")]
    public string ConversationId { get; set; } = string.Empty;

    [FirestoreProperty("sender_id")]
    public string SenderId { get; set; } = string.Empty;

    [FirestoreProperty("type")]
    public string Type { get; set; } = "text"; // text, image, audio, video, call_log

    [FirestoreProperty("content")]
    public string Content { get; set; } = string.Empty;

    [FirestoreProperty("status")]
    public string? Status { get; set; } = "sent"; // sending, sent, seen, failed

    [FirestoreProperty("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [FirestoreProperty("metadata")]
    public MessageMetadata? Metadata { get; set; }
}
