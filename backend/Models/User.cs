using Google.Cloud.Firestore;

namespace backend.Models;

[FirestoreData]
public class User
{
    [FirestoreDocumentId]
    public string Id { get; set; } = null!;

    [FirestoreProperty("displayName")]
    public string DisplayName { get; set; } = null!;

    [FirestoreProperty("createdAt")]
    public DateTime CreatedAt { get; set; }
}
