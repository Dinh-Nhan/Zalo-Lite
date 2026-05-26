using System.Collections.Generic;

namespace backend.dtos.Response
{
    public record NewsfeedResponse
    {
        public List<FeedResponse> Stories { get; init; } = new();
        public List<FeedResponse> Posts { get; init; } = new();
    }
}
