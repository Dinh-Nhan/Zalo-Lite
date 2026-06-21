namespace backend.dtos.Response
{
    public class ViewersListResponse
    {
        public string FeedId { get; set; } = "";
        public int ViewCount { get; set; }
        public bool HasViewed { get; set; }
        public List<string> ViewerIds { get; set; } = new();
    }
}
