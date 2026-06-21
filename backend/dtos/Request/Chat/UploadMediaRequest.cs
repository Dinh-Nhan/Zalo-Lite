using Microsoft.AspNetCore.Http;

namespace backend.dtos.Request.Chat;

public class UploadMediaRequest
{
    public string ConversationId { get; set; } = null!;
    public IFormFile File { get; set; } = null!;
}
