using backend.Utils;

namespace backend.Models;

/// <summary>
/// User response DTO with formatted dates
/// </summary>
public class UserResponse
{
    public string Id { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Avatar { get; set; } = string.Empty;
    public string DateOfBirth { get; set; } = string.Empty; // Format: dd-MM-yyyy
    public string Bio { get; set; } = string.Empty;
    public bool Status { get; set; }
    public string CreateAt { get; set; } = string.Empty; // Format: dd-MM-yyyy HH:mm:ss
    public string UpdateAt { get; set; } = string.Empty; // Format: dd-MM-yyyy HH:mm:ss

    /// <summary>
    /// Convert User entity to UserResponse DTO
    /// </summary>
    public static UserResponse FromUser(User user)
    {
        return new UserResponse
        {
            Id = user.Id,
            Role = user.Role,
            FirstName = user.FirstName,
            LastName = user.LastName,
            Email = user.Email,
            Avatar = user.Avatar,
            DateOfBirth = user.DateOfBirth != DateOnly.MinValue 
                ? user.DateOfBirth.ToFormattedString() 
                : string.Empty,
            Bio = user.Bio,
            Status = user.Status,
            CreateAt = user.CreateAt.ToFormattedString(),
            UpdateAt = user.UpdateAt.ToFormattedString()
        };
    }

    /// <summary>
    /// Convert list of User entities to list of UserResponse DTOs
    /// </summary>
    public static IEnumerable<UserResponse> FromUsers(IEnumerable<User> users)
    {
        return users.Select(FromUser);
    }
}
