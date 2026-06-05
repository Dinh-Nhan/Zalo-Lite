namespace backend.dtos.Request.Chat;

public class DisappearingSettingRequest
{
    /// <summary>Duration in seconds. 0 = disabled.</summary>
    public int DurationSeconds { get; set; }
}
