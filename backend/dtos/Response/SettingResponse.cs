using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.dtos.Response
{
    public class SettingResponse
    {
        public bool IsExpired { get; set; }

        public DateTime? ExpiresAt { get; set; }
    }
}