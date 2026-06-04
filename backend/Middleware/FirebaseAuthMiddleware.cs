using System.Security.Claims;
using FirebaseAdmin.Auth;
using Microsoft.Extensions.Logging;

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
                logger.LogInformation("Verifying Firebase token (length={Length})...", token.Length);

                var decoded = await FirebaseAuth.DefaultInstance
                    .VerifyIdTokenAsync(token);  // ← Bỏ checkRevoked: true

                logger.LogInformation("[FirebaseAuth] Authenticated uid={Uid}", decoded.Uid);

                context.Items["User"] = decoded;

                // Set ClaimsPrincipal để User.GetUid() hoạt động trong controllers
                var claims = new[]
                {
                    new System.Security.Claims.Claim(
                        System.Security.Claims.ClaimTypes.NameIdentifier, decoded.Uid)
                };
                var identity = new System.Security.Claims.ClaimsIdentity(claims, "Firebase");
                context.User = new System.Security.Claims.ClaimsPrincipal(identity);

                logger.LogInformation("Token verified OK — uid={Uid}", decoded.Uid);
            }
            catch (Exception ex)
            {
                logger.LogWarning("[FirebaseAuth] Token invalid: {Message}", ex.Message);

                // Token sai → không set user
                context.Items["User"] = null;
                logger.LogWarning("Token verification FAILED: [{Type}] {Message}", ex.GetType().Name, ex.Message);
            }
        }
        else
        {
            logger.LogWarning("No Bearer token in request to {Path}", context.Request.Path);
        }

        await _next(context);
    }
}
