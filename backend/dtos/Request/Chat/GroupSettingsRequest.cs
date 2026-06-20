namespace backend.dtos.Request.Chat;

public class GroupSettingsRequest
{
    public bool? OnlyAdminCanSend { get; set; }
    public bool? OnlyAdminCanEditInfo { get; set; }
    public bool? ApprovalRequiredToJoin { get; set; }
}
