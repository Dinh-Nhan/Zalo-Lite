using System.Collections.Generic;

namespace backend.dtos.Request
{
    public class CreateFeedRequest
    {
        public string Type { get; set; } = string.Empty;       // post | story

        public string Privacy { get; set; } = string.Empty;    // public | private | friends

        public CreateContentRequest? Content { get; set; }
    }
}