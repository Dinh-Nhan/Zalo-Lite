using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.dtos.Request
{
    public class CreateFeedRequest
    {
        public string Type { get; set; } = string.Empty; // post | story

        public CreateContentRequest Content { get; set; } = null!;

        public string Privacy { get; set; } = string.Empty;
    }
}