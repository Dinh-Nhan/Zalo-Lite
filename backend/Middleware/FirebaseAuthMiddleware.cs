using System.Security.Claims;
using FirebaseAdmin.Auth;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

public class FirebaseAuthMiddleware(RequestDelegate _next, ILogger<FirebaseAuthMiddleware> logger)
{
    public async Task Invoke(HttpContext context)
    {
        var header = context.Request.Headers["Authorization"].ToString();

        if (!string.IsNullOrEmpty(header) && header.StartsWith("Bearer "))
        {
            var token = header.Substring("Bearer ".Length);
            logger.LogInformation("[MiddleWare Auth: {token}]", token);
          
            try
            {
                logger.LogInformation("Verifying Firebase token (length={Length})...", token.Length);

                var decoded = await FirebaseAuth.DefaultInstance
                    .VerifyIdTokenAsync(token);  // ← Bỏ checkRevoked: true

                logger.LogInformation("[FirebaseAuth] Authenticated uid={Uid}", decoded.Uid);

                context.Items["User"] = decoded;
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