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
[AllowAnonymous]
public class UserController(UserService userService) : ControllerBase
{
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
}
