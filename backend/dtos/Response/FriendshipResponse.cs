namespace backend.dtos.Response;

public class FriendshipResponse
{
    public string Id { get; init; } = string.Empty;
    public string SenderId { get; init; } = string.Empty;
    public string AddresseeId { get; init; } = string.Empty;

    /// <summary>"pending" | "accepted" | "declined" | "blocked"</summary>
    public string Status { get; init; } = string.Empty;

    /// <summary>"search" | "phone_contact" | "group" | "qr_code"</summary>
    public string SourceType { get; init; } = string.Empty;

    public DateTime CreatedAt { get; init; }
    public DateTime UpdatedAt { get; init; }

    // ── Enriched fields (populated khi cần hiển thị UI) ───────────
    /// <summary>Tên hiển thị của người gửi lời mời (nullable — chỉ có trong received requests)</summary>
    public string? SenderName { get; init; }

    /// <summary>Avatar URL của người gửi lời mời (nullable)</summary>
    public string? SenderAvatar { get; init; }
}
