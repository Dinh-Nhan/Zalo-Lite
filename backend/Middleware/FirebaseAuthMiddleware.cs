using System.Security.Claims;
using FirebaseAdmin.Auth;

public class FirebaseAuthMiddleware(RequestDelegate _next, ILogger<FirebaseAuthMiddleware> logger)
{

    public async Task Invoke(HttpContext context)
    {
        var header = context.Request.Headers["Authorization"].ToString();

        if (!string.IsNullOrEmpty(header) && header.StartsWith("Bearer "))
        {
            var token = header.Substring("Bearer ".Length);

            try
            {
                var decoded = await FirebaseAuth.DefaultInstance
                    .VerifyIdTokenAsync(token, true);

                context.User = new ClaimsPrincipal(new ClaimsIdentity(new[]
                {
                    new Claim(ClaimTypes.NameIdentifier, decoded.Uid),
                    new Claim(ClaimTypes.Email, decoded.Claims
                        .GetValueOrDefault("email")?.ToString() ?? "")
                }, "Firebase"));

                logger.LogInformation("INFORMATION MiddleWare Auth");
                logger.LogInformation("Decoded: {decoded}", decoded);
                logger.LogInformation("User Id in Subject: {subject}", decoded.Subject);
                logger.LogInformation("User id in Uid: {uid}", decoded.Uid);

            }
            catch
            {
                // Token sai → không set user
                context.Items["User"] = null;
            }
        }

        await _next(context);
    }
}