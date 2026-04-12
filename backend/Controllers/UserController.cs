using backend.Models;
using backend.Services;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UserController : ControllerBase
{
    private readonly UserService _userService;
    private readonly FirebaseService _firebaseService;

    public UserController(UserService userService, FirebaseService firebaseService)
    {
        _userService = userService;
        _firebaseService = firebaseService;
    }

    // POST: api/user
    [HttpPost]
    public async Task<IActionResult> CreateUser([FromBody] User user)
    {
        if (user == null || string.IsNullOrWhiteSpace(user.Id))
        {
            return BadRequest(new { error = "User data and Id are required." });
        }

        try
        {
            var createdUser = await _userService.CreateUserAsync(user);
            var response = UserResponse.FromUser(createdUser);
            return CreatedAtAction(nameof(GetUserById), new { userId = createdUser.Id }, response);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = ex.Message });
        }
    }

    // GET: api/user
    [HttpGet]
    public async Task<IActionResult> GetAllUsers()
    {
        try
        {
            var users = await _userService.GetUsersAsync();
            var response = UserResponse.FromUsers(users);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = ex.Message });
        }
    }

    // GET: api/user/{userId}
    [HttpGet("{userId}")]
    public async Task<IActionResult> GetUserById(string userId)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            return BadRequest(new { error = "userId is required." });
        }

        try
        {
            var user = await _userService.GetUserAsync(userId.Trim());
            if (user == null)
            {
                return NotFound(new { error = "User not found." });
            }

            var response = UserResponse.FromUser(user);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = ex.Message });
        }
    }

    // PUT: api/user/{userId}
    [HttpPut("{userId}")]
    public async Task<IActionResult> UpdateUser(string userId, [FromBody] User user)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            return BadRequest(new { error = "userId is required." });
        }

        if (user == null)
        {
            return BadRequest(new { error = "User data is required." });
        }

        try
        {
            var updatedUser = await _userService.UpdateUserAsync(userId.Trim(), user);
            if (updatedUser == null)
            {
                return NotFound(new { error = "User not found." });
            }

            var response = UserResponse.FromUser(updatedUser);
            return Ok(response);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = ex.Message });
        }
    }

    // DELETE: api/user/{userId}
    [HttpDelete("{userId}")]
    public async Task<IActionResult> DeleteUser(string userId)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            return BadRequest(new { error = "userId is required." });
        }

        try
        {
            var result = await _userService.DeleteUserAsync(userId.Trim());
            if (!result)
            {
                return NotFound(new { error = "User not found." });
            }

            return Ok(new { message = "User deleted successfully." });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = ex.Message });
        }
    }

    // POST: api/user/sample
    [HttpPost("sample")]
    public async Task<IActionResult> CreateSampleUsers()
    {
        try
        {
            var userA = await _userService.EnsureUserExistsAsync("userA", "User A");
            var userB = await _userService.EnsureUserExistsAsync("userB", "User B");
            var conversationId = FirebaseService.GetConversationId(userA.Id, userB.Id);

            return Ok(new
            {
                users = UserResponse.FromUsers(new[] { userA, userB }),
                conversationId
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = ex.Message });
        }
    }
}
