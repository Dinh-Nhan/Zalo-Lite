using System;

namespace backend.dtos.Response
{
    public class CommentResponse
    {
        public string Id { get; set; } = null!;
        public string FeedId { get; set; } = string.Empty;
        public string UserId { get; set; } = string.Empty;
        public string UserName { get; set; } = string.Empty;
        public string UserAvatar { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public string ImageUrl { get; set; } = string.Empty;
        public int LikeCount { get; set; }
        public bool IsLiked { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
