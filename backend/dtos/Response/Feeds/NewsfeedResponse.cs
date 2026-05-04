using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.dtos.Response
{
    public class NewsfeedResponse
    {
        public List<FeedResponse> Stories { get; set; } = new();
        public List<FeedResponse> Posts { get; set; } = new();
    }
}