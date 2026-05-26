using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.dtos.Response.Feeds
{
    public class ViewersListResponse
    {
        public string FeedId { get; set; } = "";
        public int ViewCount { get; set; }
        public bool HasViewed { get; set; }
        public List<string> UserIds { get; set; } = new();
    }
}