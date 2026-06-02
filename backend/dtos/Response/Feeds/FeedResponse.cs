using backend.dtos.Response.Feeds;

namespace backend.dtos.Response
{
    public class FeedResponse
    {
        public string Id { get; init; } = string.Empty;
        public string Type { get; init; } = string.Empty;
        public string Privacy { get; init; } = string.Empty;
        public StatsResponse Stats { get; set; } = null!;
        public SettingResponse? Settings { get; init; }
        public AuthorResponse Author { get; set; } = null!;
        public ContentResponse Content { get; init; } = null!;
        public DateTime CreatedAt { get; init; }
        public DateTime? DeletedAt { get; init; }
    }
}
