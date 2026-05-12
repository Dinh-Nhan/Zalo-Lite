using backend.dtos.Request;
using backend.dtos.Response;
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
    /// Lấy thông tin user hiện tại (từ token)
    /// GET /api/user/me
    /// </summary>
    [HttpGet("me")]
    public async Task<IActionResult> GetMe()
    {
        var firebaseToken = (FirebaseToken)HttpContext.Items["User"]!;
        
        return Ok(new ApiResponse<UserResponse>
        {
            Code = 200,
            Result = await userService.GetByIdAsync(firebaseToken.Uid)
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
        var firebaseToken = HttpContext.Items["User"] as FirebaseToken;
        var uid = firebaseToken?.Uid ?? request.Id;

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
        var firebaseToken = (FirebaseToken)HttpContext.Items["User"]!;
        
        return Ok(new ApiResponse<UserResponse>
        {
            Code = 200,
            Result = await userService.UpdateAsync(firebaseToken.Uid, request)
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
        var users = await userService.SearchUser(email);
        return Ok(new ApiResponse<List<UserRequestDto>> { Code = 200, Result = users });
    }
}
