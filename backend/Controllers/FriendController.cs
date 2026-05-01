using backend.dtos.Request;
using backend.dtos.Response;
using backend.Services;
using FirebaseAdmin.Auth;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

/// <summary>
/// Friend Controller — quản lý kết bạn
///
/// Tất cả endpoint đều yêu cầu Firebase JWT (FirebaseAuthorize).
/// UID của người đang đăng nhập được lấy từ context.Items["User"].
/// </summary>
[ApiController]
[Route("api/friends")]
[FirebaseAuthorize]
public class FriendController(FriendshipService friendshipService) : ControllerBase
{
    private string CurrentUid =>
        (HttpContext.Items["User"] as FirebaseToken)?.Uid
        ?? throw new UnauthorizedAccessException("Unauthenticated");

    // ── GET /api/friends ─────────────────────────────────────────
    /// <summary>Lấy danh sách bạn bè của bản thân</summary>
    [HttpGet]
    public async Task<IActionResult> GetFriends() =>
        Ok(new ApiResponse<List<FriendSummaryResponse>>
        {
            Code   = 200,
            Result = await friendshipService.GetFriendsAsync(CurrentUid)
        });

    // ── GET /api/friends/requests/received ───────────────────────
    /// <summary>Lấy danh sách lời mời kết bạn đã NHẬN (đang pending)</summary>
    [HttpGet("requests/received")]
    public async Task<IActionResult> GetPendingReceived() =>
        Ok(new ApiResponse<List<FriendshipResponse>>
        {
            Code   = 200,
            Result = await friendshipService.GetPendingReceivedAsync(CurrentUid)
        });

    // ── GET /api/friends/requests/sent ───────────────────────────
    /// <summary>Lấy danh sách lời mời kết bạn đã GỬI (đang pending)</summary>
    [HttpGet("requests/sent")]
    public async Task<IActionResult> GetPendingSent() =>
        Ok(new ApiResponse<List<FriendshipResponse>>
        {
            Code   = 200,
            Result = await friendshipService.GetPendingSentAsync(CurrentUid)
        });

    // ── GET /api/friends/blocked ─────────────────────────────────
    /// <summary>Lấy danh sách người dùng đang bị block</summary>
    [HttpGet("blocked")]
    public async Task<IActionResult> GetBlocked() =>
        Ok(new ApiResponse<List<FriendshipResponse>>
        {
            Code   = 200,
            Result = await friendshipService.GetBlockedUsersAsync(CurrentUid)
        });

    // ── GET /api/friends/status/{targetUserId} ───────────────────
    /// <summary>Lấy trạng thái quan hệ với một user cụ thể</summary>
    [HttpGet("status/{targetUserId}")]
    public async Task<IActionResult> GetStatus(string targetUserId) =>
        Ok(new ApiResponse<FriendshipResponse?>
        {
            Code   = 200,
            Result = await friendshipService.GetRelationshipStatusAsync(CurrentUid, targetUserId)
        });

    // ── POST /api/friends/requests ───────────────────────────────
    /// <summary>Gửi lời mời kết bạn</summary>
    [HttpPost("requests")]
    public async Task<IActionResult> SendRequest([FromBody] SendFriendRequestDto dto)
    {
        var result = await friendshipService.SendRequestAsync(CurrentUid, dto);
        return StatusCode(201, new ApiResponse<FriendshipResponse>
        {
            Code   = 201,
            Result = result
        });
    }

    // ── PATCH /api/friends/requests/{friendshipId} ───────────────
    /// <summary>Chấp nhận hoặc từ chối lời mời kết bạn</summary>
    [HttpPatch("requests/{friendshipId}")]
    public async Task<IActionResult> Respond(string friendshipId, [FromBody] RespondFriendRequestDto dto) =>
        Ok(new ApiResponse<FriendshipResponse>
        {
            Code   = 200,
            Result = await friendshipService.RespondAsync(CurrentUid, friendshipId, dto)
        });

    // ── DELETE /api/friends/requests/{friendshipId} ──────────────
    /// <summary>Huỷ lời mời kết bạn đã gửi</summary>
    [HttpDelete("requests/{friendshipId}")]
    public async Task<IActionResult> CancelRequest(string friendshipId)
    {
        await friendshipService.CancelRequestAsync(CurrentUid, friendshipId);
        return Ok(new ApiResponse<object> { Code = 200 });
    }

    // ── DELETE /api/friends/{targetUserId} ───────────────────────
    /// <summary>Huỷ kết bạn</summary>
    [HttpDelete("{targetUserId}")]
    public async Task<IActionResult> Unfriend(string targetUserId)
    {
        await friendshipService.UnfriendAsync(CurrentUid, targetUserId);
        return Ok(new ApiResponse<object> { Code = 200 });
    }

    // ── POST /api/friends/block/{targetUserId} ───────────────────
    /// <summary>Block người dùng</summary>
    [HttpPost("block/{targetUserId}")]
    public async Task<IActionResult> Block(string targetUserId)
    {
        var result = await friendshipService.BlockAsync(CurrentUid, targetUserId);
        return Ok(new ApiResponse<FriendshipResponse>
        {
            Code   = 200,
            Result = result
        });
    }

    // ── DELETE /api/friends/block/{targetUserId} ─────────────────
    /// <summary>Bỏ block người dùng</summary>
    [HttpDelete("block/{targetUserId}")]
    public async Task<IActionResult> Unblock(string targetUserId)
    {
        await friendshipService.UnblockAsync(CurrentUid, targetUserId);
        return Ok(new ApiResponse<object> { Code = 200 });
    }
}
