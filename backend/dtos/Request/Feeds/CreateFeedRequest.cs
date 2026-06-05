using System.Collections.Generic;

namespace backend.dtos.Request
{
    public class CreateFeedRequest
    {
        public string Type { get; set; } = string.Empty;       // post | story

        public string Privacy { get; set; } = string.Empty;    // public | friends | selected_friends | only_me

        public List<string>? AllowedUserIds { get; set; }

        public CreateContentRequest? Content { get; set; }
    }
}
