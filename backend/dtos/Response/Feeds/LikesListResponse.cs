using System.Collections.Generic;

namespace backend.dtos.Response
{
    public class LikesListResponse
    {
        public string FeedId { get; set; } = "";
        public int LikeCount { get; set; }
        public int TotalLikes { get; set; }
        public bool IsLiked { get; set; }
        public List<string> UserIds { get; set; } = new();
    }
}