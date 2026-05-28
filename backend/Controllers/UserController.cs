using backend.common;
using backend.dtos;
using backend.dtos.Request;
using backend.dtos.Response;
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
public class UserController(UserService userService) : ControllerBase
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
    /// Lấy thông tin user hiện tại (từ token)
    /// GET /api/user/me
    /// </summary>
    [HttpGet("me")]
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
    /// Lấy thông tin user theo ID (public hoặc friend)
    /// GET /api/user/{id}
    /// </summary>
    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(string id)
    {
        return Ok(new ApiResponse<UserResponse>
        {
            Code = 200,
            Result = await userService.GetByIdAsync(id)
        });
    }

    /// <summary>
    /// Lấy danh sách tất cả users (admin only hoặc search)
    /// GET /api/user
    /// </summary>
    [HttpGet]
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
    /// </summary>
    [HttpPost]
    [AllowAnonymous]  // ← Cho phép register không cần token (vì chưa có account)
    public async Task<IActionResult> Create([FromBody] CreateUserRequest request)
    {
        // Nếu có token → dùng uid từ token
        // Nếu không có token → dùng uid từ request body (cho register flow)
        // var firebaseToken = HttpContext.Items["User"] as FirebaseToken;
        // var uid = firebaseToken?.Uid ?? request.Id;

        var uid = GetUserIdFromToken(); // Cố gắng lấy UID từ token trước
        if(uid == null)
        {
            uid = request.Id; // Cho phép lấy UID từ body nếu token không có (trường hợp register)
        }

        if (string.IsNullOrEmpty(uid))
            return BadRequest(new ApiResponse<object>
            {
                Code = 400,
                Message = "User ID is required"
            });

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
    [HttpPut("me")]
    public async Task<IActionResult> UpdateMe([FromBody] UpdateUserRequest request)
    {
        var uid = GetUserIdFromToken();
        if(uid == null)
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
    /// Cập nhật user theo ID (admin only)
    /// PUT /api/user/{id}
    /// </summary>
    [HttpPut("{id}")]
    public async Task<IActionResult> Update(string id, [FromBody] UpdateUserRequest request)
    {
        return Ok(new ApiResponse<UserResponse>
        {
            Code = 200,
            Result = await userService.UpdateAsync(id, request)
        });
    }

    /// <summary>
    /// Xóa user hiện tại
    /// DELETE /api/user/me
    /// </summary>
    [HttpDelete("me")]
    public async Task<IActionResult> DeleteMe()
    {
        var firebaseToken = (FirebaseToken)HttpContext.Items["User"]!;
        await userService.DeleteAsync(firebaseToken.Uid);
        return Ok(new ApiResponse<object> { Code = 200, Message = "User deleted successfully" });
    }

    /// <summary>
    /// Xóa user theo ID (admin only)
    /// DELETE /api/user/{id}
    /// </summary>
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(string id)
    {
        await userService.DeleteAsync(id);
        return Ok(new ApiResponse<object> { Code = 200, Message = "User deleted successfully" });
    }

    /// <summary>
    /// Tìm kiếm user theo email
    /// GET /api/user/search/{email}
    /// </summary>
    [HttpGet("search/{email}")]
    public async Task<IActionResult> SearchUser(string email)
    {
        var currentUserId = GetUserIdFromToken();
        var users = await userService.SearchUser(email, currentUserId);
        return Ok(new ApiResponse<List<UserRequestDto>> { Code = 200, Result = users });
    }

    [HttpPatch("avatar")]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> UpdateAvatar([FromForm] UpdateAvatarRequest request)
    {
        return Ok(new ApiResponse<UserResponse>()
        {
            Result = await userService.UpdateAvatarAsync(CurrentUserId, request),
            Message = "Cập nhật avatar thành công"
        });
    }
}