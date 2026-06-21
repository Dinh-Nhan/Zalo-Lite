namespace backend.dtos.Request.Chat;

public class SendMessageRequest
{
    public string ConversationId { get; set; } = null!;

    /// <summary>
    /// text, image, video, audio, file, sticker, location, contact
    /// </summary>
    public string Type { get; set; } = "text";

    public string Content { get; set; } = null!;

    public string? MediaUrl { get; set; }

    public string? ThumbnailUrl { get; set; }

    public string? FileName { get; set; }

    public long? FileSize { get; set; }

    public int? Duration { get; set; }

    /// <summary>
    /// Reply to message ID
    /// </summary>
    public string? ReplyToMessageId { get; set; }

    public bool IsForwarded { get; set; } = false;

    /// <summary>
    /// ID tạm do client sinh ra để khớp optimistic message với message thật khi server confirm.
    /// Không lưu vào Firestore, chỉ pass-through qua response.
    /// </summary>
    public string? ClientTempId { get; set; }

    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string? Address { get; set; }
}
