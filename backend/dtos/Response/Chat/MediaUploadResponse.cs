namespace backend.dtos.Response.Chat;

public class MediaUploadResponse
{
    public string MediaUrl { get; set; } = null!;
    public string MediaType { get; set; } = null!; // image, video
    public string FileName { get; set; } = null!;
    public long FileSize { get; set; }
}
