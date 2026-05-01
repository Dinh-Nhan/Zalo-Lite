namespace backend.Models
{
    public class OtpData
    {
        public String Email { get; set; } = string.Empty;
        public String HashOtp { get; set; } = string.Empty;
        public DateTime ExpireAt { get; set; }
        public int AttemptCount { get; set; }
    }
}
