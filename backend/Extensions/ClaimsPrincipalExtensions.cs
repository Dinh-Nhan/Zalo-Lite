using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using backend.Enums;
using backend.Exceptions;

namespace backend.Extensions
{
    public static class ClaimsPrincipalExtensions
    {
        public static string GetUid(this ClaimsPrincipal user) =>
        user.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? throw new AppException(ErrorCode.UNAUTHENTICATED);
    }
}