namespace backend.dtos.Response.Feeds
{
    public class ViewersListResponse
    {
        public string FeedId { get; set; } = string.Empty;
        public int ViewCount { get; set; }
        public bool HasViewed { get; set; }
        public List<string> ViewerIds { get; set; } = new();
    }
}
