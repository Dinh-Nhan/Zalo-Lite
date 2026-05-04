using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.dtos.Response
{
    public class StatsResponse
    {
        public int ViewCount { get; set; }
        public int LikeCount { get; set; }
        public bool IsLiked { get; set; }
    }
}