namespace backend.dtos.Request.Chat;

public class SetNicknameRequest
{
    /// <summary>null or empty string clears the nickname.</summary>
    public string? Nickname { get; set; }
}
