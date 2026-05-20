using backend.common;
using backend.dtos.Response;
using backend.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers
{
    [Route("api/otp")]
    [ApiController]
    [FirebaseAuthorize]
    public class OtpController(OtpService otpService) : ControllerBase
    {
        //private readonly OtpService otpService;

        //public OtpController(OtpService otpService)
        //{
        //    this.otpService = otpService;
        //}

        [HttpPost("generate")]
        public async Task<IActionResult> GenerateOtp(string email)
        {
            //validate email format
            if (!email.Contains("@"))
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

        [HttpPost("verify")]
        public async Task<IActionResult> VerifyOtp(string email, string otp)
        {
            var result = await otpService.VerifyOtpAsync(email, otp);

            if(!result)
            {
                var message = await otpService.MessageVerifyOtpAsync(email, otp);
                return BadRequest(ApiResponse<object>.ErrorResponse(400, message));
            }

            return Ok(ApiResponse<object>.SuccessResponse(true, "OTP verified successfully"));
        }
    }
}
