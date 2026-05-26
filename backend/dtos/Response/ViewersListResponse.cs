using System.Collections.Generic;

namespace backend.dtos.Response
{
    public record ViewersListResponse
    {
        public int ViewerCount { get; init; }
        public List<string> ViewerIds { get; init; } = new();
    }
}
