using FirebaseAdmin.Auth;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using backend.common;

namespace backend.Controllers
{
    /// <summary>
    /// Controller xác thực người dùng sử dụng Firebase JWT Token.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [FirebaseAuthorize]
    public class AuthController : ControllerBase
    {
        /// <summary>
        /// Lấy thông tin cơ bản từ Token xác thực Firebase đang đăng nhập.
        /// </summary>
        /// <remarks>
        /// Endpoint này yêu cầu cung cấp Token JWT hợp lệ qua Header Authorization Bearer.
        /// </remarks>
        /// <returns>UID của tài khoản Firebase hiện tại và thông báo xác thực thành công</returns>
        /// <response code="200">Xác thực Token thành công và trả về thông tin profile</response>
        /// <response code="401">Không tìm thấy Authorization Header hoặc Token không hợp lệ</response>
        [HttpGet("profile")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        public IActionResult GetProfile()
        {
            var user = (FirebaseToken)HttpContext.Items["User"]!;

            return Ok(new { uid = user.Uid, message = "Đây là thông tin profile của bạn" });
        }
    }
}
