using backend.common;
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
    /// <summary>
    /// Lấy danh sách bạn bè của người dùng hiện tại.
    /// </summary>
    /// <returns>Danh sách tóm tắt bạn bè (FriendSummaryResponse)</returns>
    /// <response code="200">Lấy danh sách bạn bè thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<FriendSummaryResponse>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetFriends() =>
        Ok(ApiResponse<List<FriendSummaryResponse>>.SuccessResponse(
            await friendshipService.GetFriendsAsync(CurrentUid)));

    // ── GET /api/friends/user/{userId} ─────────────────────────
    /// <summary>
    /// Lấy danh sách bạn bè của một người dùng cụ thể (thông tin công khai).
    /// </summary>
    /// <param name="userId">UID của người dùng cần lấy danh sách bạn bè</param>
    /// <returns>Danh sách bạn bè của người dùng đó</returns>
    /// <response code="200">Lấy danh sách bạn bè thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="404">Không tìm thấy người dùng</response>
    [HttpGet("user/{userId}")]
    [ProducesResponseType(typeof(ApiResponse<List<FriendSummaryResponse>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetUserFriends(string userId) =>
        Ok(ApiResponse<List<FriendSummaryResponse>>.SuccessResponse(
            await friendshipService.GetFriendsAsync(userId)));

    // ── GET /api/friends/requests/received ───────────────────────
    /// <summary>
    /// Lấy danh sách các lời mời kết bạn đang chờ (Pending) gửi TỚI người dùng hiện tại.
    /// </summary>
    /// <returns>Danh sách lời mời kết bạn đã nhận</returns>
    /// <response code="200">Lấy danh sách thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    [HttpGet("requests/received")]
    [ProducesResponseType(typeof(ApiResponse<List<FriendshipResponse>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetPendingReceived() =>
        Ok(ApiResponse<List<FriendshipResponse>>.SuccessResponse(
            await friendshipService.GetPendingReceivedAsync(CurrentUid)));

    // ── GET /api/friends/requests/sent ───────────────────────────
    /// <summary>
    /// Lấy danh sách các lời mời kết bạn đang chờ (Pending) do người dùng hiện tại GỬI ĐI.
    /// </summary>
    /// <returns>Danh sách lời mời kết bạn đã gửi</returns>
    /// <response code="200">Lấy danh sách thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    [HttpGet("requests/sent")]
    [ProducesResponseType(typeof(ApiResponse<List<FriendshipResponse>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetPendingSent() =>
        Ok(ApiResponse<List<FriendshipResponse>>.SuccessResponse(
            await friendshipService.GetPendingSentAsync(CurrentUid)));

    // ── GET /api/friends/blocked ─────────────────────────────────
    /// <summary>
    /// Lấy danh sách người dùng đang bị người dùng hiện tại chặn (Block).
    /// </summary>
    /// <returns>Danh sách những người dùng bị block</returns>
    /// <response code="200">Lấy danh sách thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    [HttpGet("blocked")]
    [ProducesResponseType(typeof(ApiResponse<List<FriendshipResponse>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetBlocked() =>
        Ok(ApiResponse<List<FriendshipResponse>>.SuccessResponse(
            await friendshipService.GetBlockedUsersAsync(CurrentUid)));

    // ── GET /api/friends/status/{targetUserId} ───────────────────
    /// <summary>
    /// Lấy thông tin chi tiết về mối quan hệ hiện tại giữa người dùng hiện tại và một người dùng khác.
    /// </summary>
    /// <param name="targetUserId">UID của người dùng đối phương</param>
    /// <returns>Chi tiết mối quan hệ (FriendshipResponse) hoặc null nếu chưa có quan hệ</returns>
    /// <response code="200">Lấy trạng thái thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    [HttpGet("status/{targetUserId}")]
    [ProducesResponseType(typeof(ApiResponse<FriendshipResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetStatus(string targetUserId) =>
        Ok(ApiResponse<FriendshipResponse?>.SuccessResponse(
            await friendshipService.GetRelationshipStatusAsync(CurrentUid, targetUserId)));

    // ── POST /api/friends/requests ───────────────────────────────
    /// <summary>
    /// Gửi lời mời kết bạn tới người dùng khác.
    /// </summary>
    /// <param name="dto">Dữ liệu yêu cầu kết bạn gồm UID đối phương và nguồn kết bạn</param>
    /// <returns>Chi tiết lời mời kết bạn vừa được tạo</returns>
    /// <response code="201">Gửi lời mời kết bạn thành công</response>
    /// <response code="400">Yêu cầu không hợp lệ (ví dụ gửi cho chính mình, block nhau, đã là bạn bè...)</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="422">Dữ liệu đầu vào sai định dạng</response>
    [HttpPost("requests")]
    [ProducesResponseType(typeof(ApiResponse<FriendshipResponse>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status422UnprocessableEntity)]
    public async Task<IActionResult> SendRequest([FromBody] SendFriendRequestDto dto)
    {
        var result = await friendshipService.SendRequestAsync(CurrentUid, dto);
        return StatusCode(201, ApiResponse<FriendshipResponse>.SuccessResponse(result));
    }

    // ── PATCH /api/friends/requests/{friendshipId} ───────────────
    /// <summary>
    /// Phản hồi lời mời kết bạn (Chấp nhận hoặc Từ chối).
    /// </summary>
    /// <param name="friendshipId">ID của lời mời kết bạn (Friendship ID)</param>
    /// <param name="dto">Lựa chọn chấp nhận (Accept = true) hoặc từ chối (Accept = false)</param>
    /// <returns>Thông tin quan hệ sau khi được phản hồi</returns>
    /// <response code="200">Phản hồi thành công</response>
    /// <response code="400">Lời mời kết bạn không hợp lệ hoặc đã phản hồi trước đó</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="403">Người dùng hiện tại không phải người nhận của lời mời kết bạn này</response>
    /// <response code="422">Dữ liệu đầu vào sai định dạng</response>
    [HttpPatch("requests/{friendshipId}")]
    [ProducesResponseType(typeof(ApiResponse<FriendshipResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status422UnprocessableEntity)]
    public async Task<IActionResult> Respond(string friendshipId, [FromBody] RespondFriendRequestDto dto) =>
        Ok(ApiResponse<FriendshipResponse>.SuccessResponse(
            await friendshipService.RespondAsync(CurrentUid, friendshipId, dto)));

    // ── DELETE /api/friends/requests/{friendshipId} ──────────────
    /// <summary>
    /// Hủy bỏ lời mời kết bạn đã gửi đi (khi đối phương chưa phản hồi).
    /// </summary>
    /// <param name="friendshipId">ID của lời mời kết bạn cần hủy</param>
    /// <returns>Kết quả hủy thành công</returns>
    /// <response code="200">Hủy lời mời kết bạn thành công</response>
    /// <response code="400">Lời mời kết bạn không còn ở trạng thái Pending hoặc không tìm thấy</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="403">Người dùng hiện tại không phải là người gửi lời mời này</response>
    [HttpDelete("requests/{friendshipId}")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> CancelRequest(string friendshipId)
    {
        await friendshipService.CancelRequestAsync(CurrentUid, friendshipId);
        return Ok(ApiResponse<object>.SuccessResponse(default(object)));
    }

    // ── DELETE /api/friends/{targetUserId} ───────────────────────
    /// <summary>
    /// Hủy kết bạn (Unfriend) với một người dùng đang là bạn bè.
    /// </summary>
    /// <param name="targetUserId">UID của người dùng cần hủy kết bạn</param>
    /// <returns>Kết quả hủy kết bạn thành công</returns>
    /// <response code="200">Hủy kết bạn thành công</response>
    /// <response code="400">Không tìm thấy mối quan hệ bạn bè giữa 2 người dùng</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    [HttpDelete("{targetUserId}")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Unfriend(string targetUserId)
    {
        await friendshipService.UnfriendAsync(CurrentUid, targetUserId);
        return Ok(ApiResponse<object>.SuccessResponse(default(object)));
    }

    // ── POST /api/friends/block/{targetUserId} ───────────────────
    /// <summary>
    /// Chặn (Block) một người dùng.
    /// </summary>
    /// <remarks>
    /// Sẽ hủy kết bạn / hủy lời mời đang chờ giữa hai người và đổi trạng thái quan hệ sang Blocked.
    /// </remarks>
    /// <param name="targetUserId">UID của người dùng cần chặn</param>
    /// <returns>Thông tin quan hệ sau khi bị chặn</returns>
    /// <response code="200">Chặn người dùng thành công</response>
    /// <response code="400">Không thể chặn chính mình hoặc đã chặn từ trước</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    [HttpPost("block/{targetUserId}")]
    [ProducesResponseType(typeof(ApiResponse<FriendshipResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Block(string targetUserId)
    {
        var result = await friendshipService.BlockAsync(CurrentUid, targetUserId);
        return Ok(ApiResponse<FriendshipResponse>.SuccessResponse(result));
    }

    // ── DELETE /api/friends/block/{targetUserId} ─────────────────
    /// <summary>
    /// Bỏ chặn (Unblock) một người dùng đang bị chặn.
    /// </summary>
    /// <param name="targetUserId">UID của người dùng cần bỏ chặn</param>
    /// <returns>Kết quả bỏ chặn thành công</returns>
    /// <response code="200">Bỏ chặn thành công</response>
    /// <response code="400">Không tìm thấy mối quan hệ chặn giữa hai người</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="403">Người dùng hiện tại không phải là người đã chặn (blocker)</response>
    [HttpDelete("block/{targetUserId}")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> Unblock(string targetUserId)
    {
        await friendshipService.UnblockAsync(CurrentUid, targetUserId);
        return Ok(ApiResponse<object>.SuccessResponse(default(object)));
    }
}
