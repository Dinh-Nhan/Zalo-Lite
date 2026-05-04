using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.dtos.Request
{
    public class CreateMediaRequest
    {
        public string Url { get; set; } = null!;

        public string Type { get; set; } = null!;  // image | video
    }
}