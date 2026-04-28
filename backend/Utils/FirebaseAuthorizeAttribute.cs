using FirebaseAdmin.Auth;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

/// <summary>
/// Attribute bảo vệ endpoint — chỉ cho phép request có Firebase token hợp lệ.
/// Dùng trên Controller (bảo vệ toàn bộ) hoặc trên từng Action (bảo vệ riêng lẻ).
///
/// Cách dùng:
///   [FirebaseAuthorize]              ← trên class → bảo vệ tất cả endpoint trong controller
///   [FirebaseAuthorize]              ← trên method → chỉ bảo vệ endpoint đó
///   [AllowAnonymous]                 ← trên method để bỏ qua nếu class đã có [FirebaseAuthorize]
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class FirebaseAuthorizeAttribute : Attribute, IAuthorizationFilter
{
    public void OnAuthorization(AuthorizationFilterContext context)
    {
        // Nếu endpoint có [AllowAnonymous] thì bỏ qua kiểm tra
        var hasAllowAnonymous = context.ActionDescriptor.EndpointMetadata
            .Any(m => m is AllowAnonymousAttribute);

        if (hasAllowAnonymous) return;

        // Kiểm tra Middleware đã set user chưa
        var user = context.HttpContext.Items["User"] as FirebaseToken;

        if (user == null)
        {
            context.Result = new UnauthorizedObjectResult(new
            {
                error = "Unauthorized",
                message = "Token không hợp lệ hoặc chưa đăng nhập"
            });
        }
    }
}
