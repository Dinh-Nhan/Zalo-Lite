using FirebaseAdmin.Auth;

public class FirebaseAuthMiddleware
{
    private readonly RequestDelegate _next;

    public FirebaseAuthMiddleware(RequestDelegate next)
    {
        _next = next;
    }

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

                context.Items["User"] = decoded;
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