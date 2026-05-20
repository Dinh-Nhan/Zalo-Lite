using backend.common;
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
    /// Lấy thông tin người dùng theo ID
    /// </summary>
    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(string id) =>
        Ok(ApiResponse<UserResponse>.SuccessResponse(await userService.GetByIdAsync(id)));

    [HttpGet]
    public async Task<IActionResult> GetAll() =>
        Ok(ApiResponse<List<UserResponse>>.SuccessResponse(await userService.GetAllAsync()));

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateUserRequest request)
    {
        // Dùng HttpContext.Items["User"] — đúng pattern của project
        var firebaseToken = HttpContext.Items["User"] as FirebaseToken;

        if (firebaseToken == null)
            return Unauthorized(ApiResponse<object>.ErrorResponse(401, "Unauthorized"));

        return Ok(ApiResponse<UserResponse>.SuccessResponse(
            await userService.CreateAsync(firebaseToken.Uid, request)));
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(string id, [FromBody] UpdateUserRequest request) =>
        Ok(ApiResponse<UserResponse>.SuccessResponse(await userService.UpdateAsync(id, request)));


    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(string id)
    {
        await userService.DeleteAsync(id);
        return Ok(ApiResponse<object>.SuccessResponse(null));
    }
}
