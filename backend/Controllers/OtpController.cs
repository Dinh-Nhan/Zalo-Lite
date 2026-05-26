using backend.common;
using backend.dtos.Response;
using backend.Services;
using FirebaseAdmin.Auth;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers
{
    [Route("api/otp")]
    [ApiController]
    public class OtpController(OtpService otpService) : ControllerBase
    {
        /// <summary>
        /// Tạo OTP và gửi qua email — không cần token (dùng cho forgot password, verify email)
        /// POST /api/otp/generate
        /// </summary>
        [HttpPost("generate")]
        [AllowAnonymous]  // ← Không cần token vì dùng cho forgot password
        public async Task<IActionResult> GenerateOtp([FromQuery] string email)
        {
            // Validate email format
            if (string.IsNullOrEmpty(email) || !email.Contains("@"))
            {
                return BadRequest(ApiResponse<object>.ErrorResponse(400, "Invalid email format"));
            }

            var generatedOtp = await otpService.GenerateOtpAsync(email);

            return Ok(ApiResponse<OtpResponse>.SuccessResponse(new OtpResponse
            {
                Otp = generatedOtp,
                Email = email
            }));
        }

        /// <summary>
        /// Verify OTP — không cần token
        /// POST /api/otp/verify
        /// </summary>
        [HttpPost("verify")]
        [AllowAnonymous]  // ← Không cần token vì dùng cho forgot password
        public async Task<IActionResult> VerifyOtp([FromQuery] string email, [FromQuery] string otp)
        {
            if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(otp))
            {
                return BadRequest(new ApiResponse<object>
                {
                    Code = 400,
                    Message = "Email and OTP are required",
                    Result = false,
                });
            }

            var result = await otpService.VerifyOtpAsync(email, otp);
            
            if (!result)
            {
                var message = await otpService.MessageVerifyOtpAsync(email, otp);
                return BadRequest(ApiResponse<object>.ErrorResponse(400, message));
            }

            return Ok(ApiResponse<object>.SuccessResponse(true, "OTP verified successfully"));
        }
    }
}
