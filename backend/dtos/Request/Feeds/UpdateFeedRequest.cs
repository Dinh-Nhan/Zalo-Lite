using System.Collections.Generic;

namespace backend.dtos.Request
{
    public class UpdateFeedRequest
    {
        public string? Caption { get; set; }
        public List<CreateMediaRequest>? Media { get; set; }
        public string? Privacy { get; set; }
        public List<string>? AllowedUserIds { get; set; }
    }
}