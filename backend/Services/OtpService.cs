using System.Security.Cryptography;
using System.Text;
using StackExchange.Redis;
using backend.Attributes;

namespace backend.Services
{
    [ScopedService]
    public class OtpService 
    {
        private readonly IDatabase _redis;
        private readonly EmailService _emailService;

        public OtpService(IConnectionMultiplexer redis, EmailService emailService)
        {
            _redis = redis.GetDatabase();
            _emailService = emailService;
        }

        public async Task<string> GenerateOtpAsync(string email)
        {
            var otp = new Random().Next(100000, 999999).ToString();
            var hashedOtp = HashOtp(otp);
            await _redis.StringSetAsync(
                    $"otp:{email}",
                    hashedOtp,
                    TimeSpan.FromSeconds(120)
                );

            // Send OTP to user's email here (omitted for brevity)
            await _emailService.SendOtpEmailAsync(email, otp);

            return otp;
        }

        public async Task<bool> VerifyOtpAsync(string email, string otp)
        {
            var key = $"otp:{email}";
            var storedHash = await _redis.StringGetAsync(key);

            if (storedHash.IsNullOrEmpty)
                return false;

            var inputHash = HashOtp(otp);

            if(storedHash == inputHash)
            {
                await _redis.KeyDeleteAsync(key); // Use only one time
                return true;
            }

            return false;
        }

        private string HashOtp(string otp)
        {
            using var sha = SHA256.Create();
            var bytes = sha.ComputeHash(Encoding.UTF8.GetBytes(otp));
            return Convert.ToBase64String(bytes);
        }
    }
}
