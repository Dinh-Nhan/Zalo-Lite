using System.Security.Claims;
using FirebaseAdmin.Auth;
using Microsoft.Extensions.Logging;

public class FirebaseAuthMiddleware(RequestDelegate _next, ILogger<FirebaseAuthMiddleware> logger)
{
    private readonly RequestDelegate _next;
    private readonly ILogger<FirebaseAuthMiddleware> _logger;

    public FirebaseAuthMiddleware(RequestDelegate next, ILogger<FirebaseAuthMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task Invoke(HttpContext context)
    {
        var header = context.Request.Headers["Authorization"].ToString();

        if (!string.IsNullOrEmpty(header) && header.StartsWith("Bearer "))
        {
            var token = header.Substring("Bearer ".Length);
            logger.LogInformation("[MiddleWare Auth: {token}]", token);
          
            try
            {
                _logger.LogInformation("Verifying Firebase token (length={Length})...", token.Length);

                var decoded = await FirebaseAuth.DefaultInstance
                    .VerifyIdTokenAsync(token);  // ← Bỏ checkRevoked: true

                logger.LogInformation("[FirebaseAuth] Authenticated uid={Uid}", decoded.Uid);

                context.Items["User"] = decoded;
                _logger.LogInformation("Token verified OK — uid={Uid}", decoded.Uid);
            }
            catch (Exception ex)
            {
                logger.LogWarning("[FirebaseAuth] Token invalid: {Message}", ex.Message);

                // Token sai → không set user
                context.Items["User"] = null;
                _logger.LogWarning("Token verification FAILED: [{Type}] {Message}", ex.GetType().Name, ex.Message);
            }
        }
        else
        {
            _logger.LogWarning("No Bearer token in request to {Path}", context.Request.Path);
        }

        await _next(context);
    }
}