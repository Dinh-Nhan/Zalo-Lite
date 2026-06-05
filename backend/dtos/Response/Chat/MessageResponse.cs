namespace backend.dtos.Response.Chat;

public class MessageResponse
{
    public string Id { get; set; } = null!;
    public string ConversationId { get; set; } = null!;
    public string SenderId { get; set; } = null!;
    public string SenderName { get; set; } = null!;
    public string SenderAvatar { get; set; } = null!;
    public string Type { get; set; } = null!;
    public string Content { get; set; } = null!;

    // Media
    public string? MediaUrl { get; set; }
    public string? ThumbnailUrl { get; set; }
    public string? FileName { get; set; }
    public long? FileSize { get; set; }
    public int? Duration { get; set; }

    // Reply
    public string? ReplyToMessageId { get; set; }
    public string? ReplyToContent { get; set; }
    public string? ReplyToSenderName { get; set; }

    public bool IsForwarded { get; set; }

    // Reactions
    public Dictionary<string, List<string>>? Reactions { get; set; }
    public int TotalReactions { get; set; }

    // Status
    public bool IsDeleted { get; set; }
    public DateTime? DeletedAt { get; set; }
    public bool IsEdited { get; set; }
    public DateTime? EditedAt { get; set; }

    // Read receipts
    public Dictionary<string, DateTime>? ReadBy { get; set; }
    public Dictionary<string, DateTime>? DeliveredTo { get; set; }
    public string Status { get; set; } = "sent"; // sent, delivered, read

    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public DateTime? ExpiresAt { get; set; }

    public bool IsMine { get; set; }

    // Internal: dùng trong Hub để broadcast, không serialize ra client
    [System.Text.Json.Serialization.JsonIgnore]
    public List<string>? ParticipantIds { get; set; }

    [System.Text.Json.Serialization.JsonIgnore]
    public string? NotificationTitle { get; set; }  // tên nhóm (group) hoặc tên người gửi (private)

    [System.Text.Json.Serialization.JsonIgnore]
    public bool IsGroupConversation { get; set; }
}
