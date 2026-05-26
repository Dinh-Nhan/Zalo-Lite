using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.dtos.Response.Feeds
{
    public class ViewResponse
    {
        public int ViewCount { get; set; }
        public bool HasViewed { get; set; }
    }
}