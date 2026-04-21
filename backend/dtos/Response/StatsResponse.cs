using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.dtos.Response
{
    public class StatsResponse
    {
        public int ViewCount { get; init; }
        public int LikeCount { get; init; }
        public bool IsLiked { get; init; }
    }
}