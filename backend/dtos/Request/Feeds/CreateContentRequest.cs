using System.Collections.Generic;

namespace backend.dtos.Request
{
    public class CreateContentRequest
    {
        public string? Caption { get; set; }
        public List<CreateMediaRequest> Media { get; set; } = [];
    }
}