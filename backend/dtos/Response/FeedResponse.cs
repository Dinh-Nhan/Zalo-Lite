namespace backend.dtos.Response
{
    public class ViewResponse
    {
        public int ViewCount { get; set; }
        public bool HasViewed { get; set; }
    }

    public class ViewersListResponse
    {
        public string FeedId { get; set; } = string.Empty;
        public int ViewCount { get; set; }
        public bool HasViewed { get; set; }
        public List<string> ViewerIds { get; set; } = new();
    }

    public class HideResponse
    {
        public bool IsHidden { get; set; }
    }
}
