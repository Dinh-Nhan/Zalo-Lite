using Google.Cloud.Firestore;
using System.ComponentModel.DataAnnotations;

namespace backend.Models;

[FirestoreData]
public class ConversationParticipant
{
    [FirestoreProperty("user_id")]
    public string UserId { get; set; } = string.Empty;

    [FirestoreProperty("role")]
    public string Role { get; set; } = "member"; // admin or member
}

[FirestoreData]
public class LastMessage
{
    [FirestoreProperty("message_id")]
    public string MessageId { get; set; } = string.Empty;

    [FirestoreProperty("content")]
    public string Content { get; set; } = string.Empty;

    [FirestoreProperty("type")]
    public string Type { get; set; } = "text"; // text, image, call_log, etc.

    [FirestoreProperty("sender_id")]
    public string SenderId { get; set; } = string.Empty;

    [FirestoreProperty("sent_at")]
    public DateTime SentAt { get; set; } = DateTime.UtcNow;
}

[FirestoreData]
public class ConversationSettings
{
    [FirestoreProperty("is_muted")]
    public bool IsMuted { get; set; } = false;

    [FirestoreProperty("theme")]
    public string Theme { get; set; } = "classic";
}

[FirestoreData]
public class Conversation
{
    [FirestoreDocumentId]
    public string Id { get; set; } = null!;

    [FirestoreProperty("type")]
    public string Type { get; set; } = "private"; // private or group

    [FirestoreProperty("participants")]
    public List<ConversationParticipant> Participants { get; set; } = [];

    [FirestoreProperty("last_message")]
    public LastMessage? LastMessage { get; set; }

    [FirestoreProperty("settings")]
    public ConversationSettings Settings { get; set; } = new();

    [FirestoreProperty("updated_at")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
