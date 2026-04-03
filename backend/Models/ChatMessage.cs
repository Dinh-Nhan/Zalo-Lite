using Google.Cloud.Firestore;

namespace backend.Models;

[FirestoreData]
public class ChatMessage
{
    [FirestoreDocumentId]
    public string Id { get; set; } = null!;

    [FirestoreProperty("senderId")]
    public string SenderId { get; set; } = null!;

    [FirestoreProperty("recipientId")]
    public string RecipientId { get; set; } = null!;

    [FirestoreProperty("content")]
    public string Content { get; set; } = null!;

    [FirestoreProperty("timestamp")]
    public DateTime Timestamp { get; set; }
}
