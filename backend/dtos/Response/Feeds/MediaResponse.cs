using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.dtos.Response
{
    public class MediaResponse
    {
        public string Url { get; init; } = null!;

        public string Type { get; init; } = null!;
    }
}