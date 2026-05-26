using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.dtos.Response.Feeds
{
    public class AuthorResponse
    {
        public string UserId {get; set;} = null!;

        public string Name {get; set;} = null!;

        public string? AvatarUrl {get; set;}
    }
}