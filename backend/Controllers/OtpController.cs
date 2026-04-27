using backend.dtos.Response;
using backend.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers
{
    [Route("api/otp")]
    [ApiController]
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
            var generatedOtp = await otpService.GenerateOtpAsync(email);
            return Ok(new ApiResponse<OtpResponse>
            {
                Code = 200,
                Result = new OtpResponse
                {
                    Otp = generatedOtp,
                    Email = email
                }
            });
        }

        [HttpPost("verify")]
        public async Task<IActionResult> VerifyOtp(string email, string otp)
        {
            var result = await otpService.VerifyOtpAsync(email, otp);

            if(!result)
            {
                return BadRequest(new ApiResponse<object>
                {
                    Code = 400,
                    Message = "Not implemented",
                    Result = false,
                });
            }

            return Ok(new ApiResponse<object>
            {
                Code = 200,
                Message = "Verify Otp Success",
                Result = true,            
            });
        }
    }
}
