using backend.common;
using backend.dtos;
using backend.dtos.Request;
using backend.dtos.Response;
using backend.dtos.Response.Chat;
using backend.Enums;
using backend.Exceptions;
using backend.Models;
using backend.Services;
using FirebaseAdmin.Auth;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

[ApiController]
[Route("api/[controller]")]
[FirebaseAuthorize]
public class UserController(UserService userService, ChatService chatService) : ControllerBase
{
    /// <summary>
    /// Lấy UId từ token
    /// </summary>
    private string GetUserIdFromToken()
    {
        var firebaseToken = HttpContext.Items["User"] as FirebaseToken;
        if (firebaseToken == null)
            throw new AppException(ErrorCode.UNAUTHENTICATED);
        return firebaseToken.Uid;
    }

    private string CurrentUserId => GetUserIdFromToken();


    /// <summary>
    /// Lấy thông tin hồ sơ của người dùng hiện tại từ Firebase Token.
    /// </summary>
    /// <returns>Hồ sơ người dùng hiện tại</returns>
    /// <response code="200">Lấy thông tin thành công</response>
    /// <response code="401">Người dùng chưa xác thực hoặc token hết hạn</response>
    /// <response code="404">Không tìm thấy thông tin người dùng trong hệ thống</response>
    [HttpGet("me")]
    [ProducesResponseType(typeof(ApiResponse<UserResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetMe()
    {
        var uid = GetUserIdFromToken();

        return Ok(new ApiResponse<UserResponse>
        {
            Code = 200,
            Result = await userService.GetByIdAsync(uid)
        });
    }

    /// <summary>
    /// Tim kiem user theo keyword (query param)
    /// GET /api/user/search?q=...
    /// </summary>
    [HttpGet("search")]
    public async Task<IActionResult> SearchUser([FromQuery] string q)
    {
        var currentUserId = GetUserIdFromToken();
        var users = await userService.SearchUser(q ?? "", currentUserId);
        return Ok(new ApiResponse<List<UserRequestDto>> { Code = 200, Result = users });
    }

    /// <summary>
    /// Lấy thông tin user theo ID (public hoặc friend)
    /// GET /api/user/{id}
    /// Lấy thông tin hồ sơ của người dùng theo ID (UID).
    /// </summary>
    /// <param name="id">UID của người dùng cần lấy thông tin</param>
    /// <returns>Thông tin hồ sơ người dùng</returns>
    /// <response code="200">Lấy thông tin thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="404">Không tìm thấy người dùng</response>
    [HttpGet("{id}")]
    [ProducesResponseType(typeof(ApiResponse<UserResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(string id)
    {
        return Ok(new ApiResponse<UserResponse>
        {
            Code = 200,
            Result = await userService.GetByIdAsync(id)
        });
    }

    /// <summary>
    /// Lấy danh sách toàn bộ người dùng trong hệ thống (dành cho quản trị viên hoặc tìm kiếm).
    /// </summary>
    /// <returns>Danh sách hồ sơ người dùng</returns>
    /// <response code="200">Lấy danh sách thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<UserResponse>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetAll()
    {
        return Ok(new ApiResponse<List<UserResponse>>
        {
            Code = 200,
            Result = await userService.GetAllAsync()
        });
    }

    /// <summary>
    /// Tạo user mới — uid lấy từ token, không từ body
    /// POST /api/user
    /// Tạo hồ sơ người dùng mới trong hệ thống.
    /// </summary>
    /// <remarks>
    /// Thường dùng cho luồng đăng ký ban đầu (khi chưa có token JWT, gửi ID đăng ký trong body) 
    /// hoặc luồng khởi tạo thông tin người dùng sau khi xác thực thành công.
    /// </remarks>
    /// <param name="request">Thông tin hồ sơ cần tạo</param>
    /// <returns>Thông tin hồ sơ đã được tạo</returns>
    /// <response code="200">Tạo người dùng thành công</response>
    /// <response code="401">Không xác định được danh tính (thiếu token và ID đăng ký)</response>
    /// <response code="422">Thông tin đầu vào không hợp lệ</response>
    [HttpPost]
    [AllowAnonymous]  // ← Cho phép register không cần token (vì chưa có account)
    [ProducesResponseType(typeof(ApiResponse<UserResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status422UnprocessableEntity)]
    public async Task<IActionResult> Create([FromBody] CreateUserRequest request)
    {
        // Lấy UID an toàn: ưu tiên token (user đã login), fallback về request.Id (register flow)
        var firebaseToken = HttpContext.Items["User"] as FirebaseToken;
        var uid = firebaseToken?.Uid ?? request.Id;

        if (string.IsNullOrEmpty(uid))
            throw new AppException(ErrorCode.UNAUTHENTICATED);

        return Ok(new ApiResponse<UserResponse>
        {
            Code = 200,
            Result = await userService.CreateAsync(uid, request)
        });
    }

    /// <summary>
    /// Cập nhật thông tin user hiện tại
    /// PUT /api/user/me
    /// </summary>
    /// <summary>
    /// Cập nhật thông tin hồ sơ của bản thân người dùng hiện tại.
    /// </summary>
    /// <param name="request">Thông tin cần cập nhật</param>
    /// <returns>Hồ sơ người dùng sau khi cập nhật</returns>
    /// <response code="200">Cập nhật thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="404">Không tìm thấy người dùng</response>
    /// <response code="422">Dữ liệu cập nhật không hợp lệ</response>
    [HttpPut("me")]
    [ProducesResponseType(typeof(ApiResponse<UserResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status422UnprocessableEntity)]
    public async Task<IActionResult> UpdateMe([FromBody] UpdateUserRequest request)
    {
        var uid = GetUserIdFromToken();
        if (uid == null)
        {
            throw new AppException(ErrorCode.UNAUTHENTICATED);
        }

        return Ok(new ApiResponse<UserResponse>
        {
            Code = 200,
            Result = await userService.UpdateAsync(uid, request)
        });
    }

    /// <summary>
    /// Cập nhật thông tin hồ sơ người dùng theo ID (dành cho quản trị viên).
    /// </summary>
    /// <param name="id">UID của người dùng cần cập nhật</param>
    /// <param name="request">Thông tin cập nhật</param>
    /// <returns>Hồ sơ người dùng sau khi cập nhật</returns>
    /// <response code="200">Cập nhật thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="404">Không tìm thấy người dùng</response>
    /// <response code="422">Dữ liệu cập nhật không hợp lệ</response>
    [HttpPut("{id}")]
    [ProducesResponseType(typeof(ApiResponse<UserResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status422UnprocessableEntity)]
    public async Task<IActionResult> Update(string id, [FromBody] UpdateUserRequest request)
    {
        return Ok(new ApiResponse<UserResponse>
        {
            Code = 200,
            Result = await userService.UpdateAsync(id, request)
        });
    }

    /// <summary>
    /// Xóa tài khoản của người dùng hiện tại khỏi hệ thống.
    /// </summary>
    /// <returns>Thông điệp kết quả xóa thành công</returns>
    /// <response code="200">Xóa tài khoản thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="404">Không tìm thấy người dùng</response>
    [HttpDelete("me")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteMe()
    {
        var firebaseToken = (FirebaseToken)HttpContext.Items["User"]!;
        await userService.DeleteAsync(firebaseToken.Uid);
        return Ok(new ApiResponse<object> { Code = 200, Message = "User deleted successfully" });
    }

    /// <summary>
    /// Xóa tài khoản người dùng theo ID (dành cho quản trị viên).
    /// </summary>
    /// <param name="id">UID của người dùng cần xóa</param>
    /// <returns>Thông điệp kết quả xóa thành công</returns>
    /// <response code="200">Xóa tài khoản thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="404">Không tìm thấy người dùng</response>
    [HttpDelete("{id}")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(string id)
    {
        await userService.DeleteAsync(id);
        return Ok(new ApiResponse<object> { Code = 200, Message = "User deleted successfully" });
    }

    /// <summary>
    /// Kích hoạt lại tài khoản người dùng đang bị khóa (dành cho quản trị viên).
    /// </summary>
    /// <param name="id">UID của người dùng cần kích hoạt</param>
    /// <returns>Thông điệp kích hoạt thành công</returns>
    /// <response code="200">Kích hoạt tài khoản thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="404">Không tìm thấy người dùng</response>
    [HttpPatch("{id}/enable")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> EnableUser(string id)
    {
        await userService.SetEnableAsync(id, true);
        return Ok(new ApiResponse<object> { Code = 200, Message = "User enabled" });
    }

    /// <summary>
    /// Vô hiệu hóa/Khóa tài khoản người dùng (dành cho quản trị viên).
    /// </summary>
    /// <param name="id">UID của người dùng cần khóa</param>
    /// <returns>Thông điệp vô hiệu hóa thành công</returns>
    /// <response code="200">Vô hiệu hóa tài khoản thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="404">Không tìm thấy người dùng</response>
    [HttpPatch("{id}/disable")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DisableUser(string id)
    {
        await userService.SetEnableAsync(id, false);
        return Ok(new ApiResponse<object> { Code = 200, Message = "User disabled" });
    }

    /// <summary>
    /// Cập nhật hình đại diện (avatar) của người dùng hiện tại.
    /// </summary>
    /// <param name="request">File hình ảnh đại diện tải lên</param>
    /// <returns>Thông tin hồ sơ sau khi cập nhật avatar</returns>
    /// <response code="200">Cập nhật avatar thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="422">File hình ảnh không hợp lệ hoặc bị trống</response>
    [HttpPatch("avatar")]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(ApiResponse<UserResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status422UnprocessableEntity)]
    public async Task<IActionResult> UpdateAvatar([FromForm] UpdateAvatarRequest request)
    {
        return Ok(new ApiResponse<UserResponse>()
        {
            Result = await userService.UpdateAvatarAsync(CurrentUserId, request),
            Message = "Cập nhật avatar thành công"
        });
    }

    /// <summary>
    /// Lưu trữ mã đăng ký thông báo FCM Token để hỗ trợ nhận thông báo đẩy (push notifications).
    /// </summary>
    /// <param name="request">Mã FCM token mới của thiết bị</param>
    /// <returns>Kết quả lưu thành công</returns>
    /// <response code="200">Lưu token thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="422">Dữ liệu yêu cầu bị thiếu hoặc sai format</response>
    [HttpPost("fcm-token")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status422UnprocessableEntity)]
    public async Task<IActionResult> SaveFcmToken([FromBody] SaveFcmTokenRequest request)
    {
        await userService.SaveFcmTokenAsync(GetUserIdFromToken(), request.Token);
        return Ok(new ApiResponse<object> { Code = 200, Message = "FCM token saved" });
    }

    /// <summary>
    /// Lấy trạng thái hoạt động trực tuyến (online/offline/last seen) của người dùng khác.
    /// </summary>
    /// <param name="id">UID của người dùng cần xem trạng thái</param>
    /// <returns>Trạng thái trực tuyến và thời gian hoạt động cuối</returns>
    /// <response code="200">Lấy trạng thái thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="404">Không tìm thấy người dùng</response>
    [HttpGet("{id}/online")]
    [ProducesResponseType(typeof(ApiResponse<OnlineStatusResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetOnlineStatus(string id)
    {
        var status = await chatService.GetOnlineStatusAsync(id);
        return Ok(new ApiResponse<OnlineStatusResponse> { Code = 200, Result = status });
    }
}
