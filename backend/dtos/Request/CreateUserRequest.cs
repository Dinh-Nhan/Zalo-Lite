using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.dtos.Request
{
    public class CreateUserRequest
    {
    public string? Id { get; set; }  // ← Optional: dùng cho register flow (khi chưa có token)
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public DateOnly DateOfBirth { get; set; }
    public string Bio { get; set; } = string.Empty;
    }
}