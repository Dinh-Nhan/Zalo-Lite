using System.ComponentModel.DataAnnotations;

namespace backend.dtos.Request;

public class RespondFriendRequestDto
{
    /// <summary>true = chấp nhận, false = từ chối</summary>
    [Required]
    public bool Accept { get; set; }
}
