using backend.Attributes;
using System.Net;
using System.Net.Mail;

namespace backend.Services
{
    [ScopedService]
    public class EmailService(IConfiguration configuration, ILogger<EmailService> logger)
    {
        public async Task<bool> SendOtpEmailAsync(string toEmail, string otp)
        {
            try
            {
                var host = configuration["Email:SmtpHost"];
                var port = configuration["Email:Port"];
                var username = configuration["Email:Username"];
                var password = configuration["Email:Password"];

                if (string.IsNullOrEmpty(host) ||
                    string.IsNullOrEmpty(port) ||
                    string.IsNullOrEmpty(username) ||
                    string.IsNullOrEmpty(password))
                {
                    logger.LogError("Email config missing");
                    return false;
                }

                var smtp = new SmtpClient(host)
                {
                    Port = int.Parse(port),
                    Credentials = new NetworkCredential(username, password),
                    EnableSsl = true,
                    Timeout = 10000 // 10s
                };

                var mail = new MailMessage
                {
                    From = new MailAddress(username, "No Reply"),
                    Subject = "Your OTP Code",
                    Body = $"""
                    Your OTP code is: {otp}

                    This code will expire in 60 seconds.
                    Do not share this code with anyone.
                    """,
                    IsBodyHtml = false
                };

                mail.To.Add(toEmail);

                await smtp.SendMailAsync(mail);

                logger.LogInformation($"OTP sent to {toEmail}");
                return true;
            }
            catch (Exception ex)
            {
                logger.LogError(ex, $"Failed to send OTP to {toEmail}");

                // retry đơn giản 1 lần
                try
                {
                    await Task.Delay(1000);
                    return await SendOtpEmailAsync(toEmail, otp);
                }
                catch
                {
                    return false;
                }
            }
        }
    }
}