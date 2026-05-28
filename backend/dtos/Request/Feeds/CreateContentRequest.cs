using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.dtos.Request
{
    public class CreateContentRequest
    {
        public string? Caption { get; set; }

        public List<CreateMediaRequest> Media { get; set; } = [];
    }
}