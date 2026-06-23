namespace backend.dtos.Request;

public class SendFriendRequestDto
{
    /// <summary>UID của người nhận lời mời kết bạn</summary>
    public string AddresseeId { get; set; } = string.Empty;

    /// <summary>Nguồn kết bạn: "search" | "phone_contact" | "group" | "qr_code"</summary>
    public string SourceType { get; set; } = "search";
}
