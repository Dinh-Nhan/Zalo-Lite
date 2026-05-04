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
            logger.LogInformation("[MiddleWare Auth: {token}]", token);
            try
            {
                var decoded = await FirebaseAuth.DefaultInstance
                    .VerifyIdTokenAsync(token, true);

                logger.LogInformation("[FirebaseAuth] Authenticated uid={Uid}", decoded.Uid);

                context.Items["User"] = decoded;
            }
            catch (Exception ex)
            {
                logger.LogWarning("[FirebaseAuth] Token invalid: {Message}", ex.Message);

                // Token sai → không set user
                context.Items["User"] = null;
            }
        }

        await _next(context);
    }
}