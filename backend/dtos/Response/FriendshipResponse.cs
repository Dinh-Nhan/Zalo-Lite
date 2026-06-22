namespace backend.dtos.Response;

public class FriendshipResponse
{
    public string Id { get; set; } = string.Empty;
    public string SenderId { get; set; } = string.Empty;
    public string AddresseeId { get; set; } = string.Empty;

    /// <summary>"pending" | "accepted" | "declined" | "blocked"</summary>
    public string Status { get; set; } = string.Empty;

    /// <summary>"search" | "phone_contact" | "group" | "qr_code"</summary>
    public string SourceType { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    // ── Enriched fields (populated khi cần hiển thị UI) ───────────
    /// <summary>Tên hiển thị của người gửi lời mời (nullable — chỉ có trong received requests)</summary>
    public string? SenderName { get; set; }

    /// <summary>Avatar URL của người gửi lời mời (nullable)</summary>
    public string? SenderAvatar { get; set; }

    /// <summary>Tên của người nhận lời mời (nullable)</summary>
    public string? AddresseeName { get; set; }
}
