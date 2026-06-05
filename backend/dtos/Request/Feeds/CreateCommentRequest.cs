using Microsoft.AspNetCore.Http;

namespace backend.dtos.Request
{
    public class CreateCommentRequest
    {
        public string Content { get; set; } = string.Empty;
        public IFormFile? File { get; set; }
    }

    public class CreateCommentJsonRequest
    {
        public string Content { get; set; } = string.Empty;
    }
}
