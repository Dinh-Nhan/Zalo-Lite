using FirebaseAdmin.Auth;
using System.Security.Claims;

public class FirebaseAuthMiddleware
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
            var token = header.Substring("Bearer ".Length).Trim();

            try
            {
                _logger.LogInformation("Verifying Firebase token (length={Length})...", token.Length);

                var decoded = await FirebaseAuth.DefaultInstance
                    .VerifyIdTokenAsync(token);

                context.Items["User"] = decoded;
                context.User = new ClaimsPrincipal(new ClaimsIdentity(
                    new[] { new Claim(ClaimTypes.NameIdentifier, decoded.Uid) },
                    "Firebase"));

                _logger.LogInformation("Token verified OK — uid={Uid}", decoded.Uid);
            }
            catch (Exception ex)
            {
                context.Items["User"] = null;
                context.User = new ClaimsPrincipal();
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