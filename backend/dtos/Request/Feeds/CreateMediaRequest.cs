using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.dtos.Request
{
    public class CreateMediaRequest
    {
        public IFormFile File { get; set; } = null!;
        
    }
}