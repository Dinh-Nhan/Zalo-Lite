using Microsoft.AspNetCore.SignalR;
using FirebaseAdmin.Auth;

namespace backend.Hubs;

/// <summary>
/// SignalR Hub cho realtime kết bạn.
///
/// Client kết nối bằng cách gửi token Firebase qua query string:
///   ?access_token=<firebase_id_token>
///
/// Mỗi user được join vào group riêng tên "user_{uid}" để nhận push.
/// </summary>
public class FriendHub : Hub
{
    private readonly ILogger<FriendHub> _logger;

    public FriendHub(ILogger<FriendHub> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Khi client kết nối → xác thực token → join group cá nhân.
    /// Token được gửi qua query param "access_token" (vì SignalR WebSocket
    /// không support custom headers tiêu chuẩn).
    /// </summary>
    public override async Task OnConnectedAsync()
    {
        var token = Context.GetHttpContext()?.Request.Query["access_token"].ToString();

        if (string.IsNullOrWhiteSpace(token))
        {
            _logger.LogWarning("FriendHub: connection rejected — no token. ConnectionId={Id}", Context.ConnectionId);
            Context.Abort();
            return;
        }

        try
        {
            var decoded = await FirebaseAuth.DefaultInstance.VerifyIdTokenAsync(token, true);
            var uid = decoded.Uid;

            // Lưu uid vào context để dùng khi disconnect
            Context.Items["uid"] = uid;

            // Join group cá nhân
            await Groups.AddToGroupAsync(Context.ConnectionId, GroupName(uid));

            _logger.LogInformation("FriendHub: {Uid} connected [{ConnectionId}]", uid, Context.ConnectionId);
        }
        catch (Exception ex)
        {
            _logger.LogWarning("FriendHub: invalid token — {Msg}", ex.Message);
            Context.Abort();
            return;
        }

        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        if (Context.Items.TryGetValue("uid", out var uid) && uid is string uidStr)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, GroupName(uidStr));
            _logger.LogInformation("FriendHub: {Uid} disconnected", uidStr);
        }
        await base.OnDisconnectedAsync(exception);
    }

    /// <summary>Tên group SignalR của một user</summary>
    public static string GroupName(string uid) => $"user_{uid}";
}
