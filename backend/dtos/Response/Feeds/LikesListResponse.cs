using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.dtos.Response
{
    public class LikesListResponse
    {
        public string FeedId { get; set; } = "";
        public int LikeCount { get; set; }
        public bool IsLiked { get; set; }
        public List<string> UserIds { get; set; } = new();
    }
}