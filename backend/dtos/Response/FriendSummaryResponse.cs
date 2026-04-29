namespace backend.dtos.Response;

/// <summary>
/// Thông tin bạn bè kèm avatar/tên — dùng trong danh sách bạn bè
/// </summary>
public class FriendSummaryResponse
{
    public string FriendshipId { get; init; } = string.Empty;
    public string FriendId { get; init; } = string.Empty;
    public string FullName { get; init; } = string.Empty;
    public string Avatar { get; init; } = string.Empty;
    public DateTime FriendsSince { get; init; }
}
