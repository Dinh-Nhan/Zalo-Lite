namespace backend.dtos.Response
{
    public record ViewResponse
    {
        public int ViewCount { get; init; }
        public bool HasViewed { get; init; }
    }
}
