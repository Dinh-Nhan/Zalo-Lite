using backend.Models;
using backend.Services;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UserController : ControllerBase
{
    private readonly FirebaseService _firebaseService;

    public UserController(FirebaseService firebaseService)
    {
        _firebaseService = firebaseService;
    }

    [HttpPost]
    public async Task<IActionResult> CreateUser([FromBody] UserCreateRequest request)
    {
        if (request == null || string.IsNullOrWhiteSpace(request.Id) || string.IsNullOrWhiteSpace(request.DisplayName))
        {
            return BadRequest(new { error = "Id and DisplayName are required." });
        }

        var user = await _firebaseService.EnsureUserExistsAsync(request.Id.Trim(), request.DisplayName.Trim());
        return CreatedAtAction(nameof(GetUser), new { userId = user.Id }, user);
    }

    [HttpGet]
    public async Task<IActionResult> GetUsers()
    {
        var users = await _firebaseService.GetUsersAsync();
        return Ok(users);
    }

    [HttpGet("{userId}")]
    public async Task<IActionResult> GetUser(string userId)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            return BadRequest(new { error = "userId is required." });
        }

        var user = await _firebaseService.GetUserAsync(userId.Trim());
        if (user == null)
        {
            return NotFound(new { error = "User not found." });
        }

        return Ok(user);
    }

    [HttpPost("sample")]
    public async Task<IActionResult> CreateSampleUsers()
    {
        var userA = await _firebaseService.EnsureUserExistsAsync("userA", "User A");
        var userB = await _firebaseService.EnsureUserExistsAsync("userB", "User B");
        var conversationId = FirebaseService.GetConversationId(userA.Id, userB.Id);

        return Ok(new
        {
            users = new[] { userA, userB },
            conversationId
        });
    }
}
