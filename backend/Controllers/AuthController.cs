using FirebaseAdmin.Auth;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/[controller]")]
[FirebaseAuthorize]
public class AuthController : ControllerBase
{
    [HttpGet("profile")]
    public IActionResult GetProfile()
    {
        var user = (FirebaseToken)HttpContext.Items["User"]!;

        return Ok(new { uid = user.Uid, message = "Đây là thông tin profile của bạn" });
    }
}
