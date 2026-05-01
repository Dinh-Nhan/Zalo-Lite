using Google.Cloud.Firestore;

namespace backend.Models;

[FirestoreData]
public class Friendship
{
    [FirestoreDocumentId]
    public string Id { get; set; } = null!;

    [FirestoreProperty("sender_id")]
    public string SenderId { get; set; } = null!; // uid của người gửi lời mời

    [FirestoreProperty("addressee_id")]
    public string AddresseeId { get; set; } = null!; // uid của người nhận

    /// <summary>
    /// Trạng thái kết bạn:
    ///   "pending"  — đã gửi lời mời, chờ chấp nhận
    ///   "accepted" — đã là bạn bè
    ///   "declined" — bị từ chối
    ///   "blocked"  — bị chặn
    /// </summary>
    [FirestoreProperty("status")]
    public string Status { get; set; } = "pending";

    /// <summary>
    /// Nguồn kết bạn: "search", "phone_contact", "group", "qr_code"
    /// </summary>
    [FirestoreProperty("source_type")]
    public string SourceType { get; set; } = "search";

    [FirestoreProperty("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [FirestoreProperty("updated_at")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
