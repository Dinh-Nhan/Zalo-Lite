namespace backend.dtos.Response
{
    public record LikeResponse
    {
        public int LikeCount { get; init; }
        public bool IsLiked { get; init; }
    }
}
