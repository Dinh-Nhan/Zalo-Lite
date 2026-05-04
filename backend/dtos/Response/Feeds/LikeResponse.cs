using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.dtos.Response
{
    public class LikeResponse
    {
        public bool IsLiked { get; set; }
        public int LikeCount { get; set; }
    }
}