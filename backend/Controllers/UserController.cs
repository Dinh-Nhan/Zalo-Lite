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
[AllowAnonymous]
public class UserController(UserService userService) : ControllerBase
{
    private string CurrentUserId
    {
        get
        {
            var token = HttpContext.Items["User"] as FirebaseToken;
            if (token == null)
                throw new AppException(ErrorCode.UNAUTHENTICATED);
            return token.Uid;
        }
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(string id) =>
        Ok(new ApiResponse<UserResponse>
        {
            Code = 200,
            Result = await userService.GetByIdAsync(id)
        });

    [HttpGet]
    public async Task<IActionResult> GetAll() =>
        Ok(new ApiResponse<List<UserResponse>>
        {
            Code = 200,
            Result = await userService.GetAllAsync()
        });

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateUserRequest request)
    {
        // Dùng HttpContext.Items["User"] — đúng pattern của project
        var firebaseToken = HttpContext.Items["User"] as FirebaseToken;

        if (firebaseToken == null)
            return Unauthorized(new ApiResponse<object>
            {
                Code = 401,
                Message = "Unauthorized"
            });

        return Ok(new ApiResponse<UserResponse>
        {
            Code = 200,
            Result = await userService.CreateAsync(firebaseToken.Uid, request)
        });
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(string id, [FromBody] UpdateUserRequest request) =>
        Ok(new ApiResponse<UserResponse>
        {
            Code = 200,
            Result = await userService.UpdateAsync(id, request)
        });

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(string id)
    {
        await userService.DeleteAsync(id);
        return Ok(new ApiResponse<object> { Code = 200 });
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
