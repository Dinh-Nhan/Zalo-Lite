using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.dtos.Response
{
    public class UserResponse
    {
        public string Id { get; init; } = string.Empty;
        public string Role { get; init; } = string.Empty;
        public string FullName { get; init; } = string.Empty;
        public string Email { get; init; } = string.Empty;
        public string Avatar { get; init; } = string.Empty;
        public DateOnly DateOfBirth { get; init; }
        public string Bio { get; init; } = string.Empty;
        public bool Status { get; init; }
        public DateTime CreateAt { get; init; }
        public DateTime UpdateAt { get; set; }
    }
}