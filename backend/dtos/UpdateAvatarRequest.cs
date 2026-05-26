using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.dtos
{
    public class UpdateAvatarRequest
    {
        public IFormFile File { get; set; } = null!;
    }
}