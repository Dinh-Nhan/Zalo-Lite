using System.Collections.Generic;

namespace backend.dtos.Response
{
    public record LikesListResponse
    {
        public int TotalLikes { get; init; }
        public List<string> UserIds { get; init; } = new();
    }
}
