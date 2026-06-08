using System.Collections.Generic;
using Microsoft.AspNetCore.Http;

namespace backend.dtos.Request
{
    public class CreateMediaRequest
    {
        public IFormFile? File { get; set; }
    }
}
