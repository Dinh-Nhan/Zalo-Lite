using System.Collections.Generic;

namespace backend.dtos.Response
{
    public record ViewersListResponse
    {
        public string FeedId { get; init; } = "";
        public int ViewCount { get; init; }
        public bool HasViewed { get; init; }
        public List<string> ViewerIds { get; init; } = new();
    }
}
