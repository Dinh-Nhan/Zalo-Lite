using System.Net;
using System.Reflection;

namespace backend.Enums
{
    public enum ErrorCode
    {
    [ErrorMeta(1000, "Unauthenticated", HttpStatusCode.Unauthorized)]
    UNAUTHENTICATED,

    [ErrorMeta(1001, "Token is invalid or expired", HttpStatusCode.Unauthorized)]
    INVALID_TOKEN,

    [ErrorMeta(1002, "You do not have permission", HttpStatusCode.Forbidden)]
    FORBIDDEN,

    // User - 2xxx
    [ErrorMeta(2000, "User not found", HttpStatusCode.NotFound)]
    USER_NOT_FOUND,

    [ErrorMeta(2001, "Email already exists", HttpStatusCode.Conflict)]
    EMAIL_ALREADY_EXISTS,

    [ErrorMeta(2002, "User is disabled", HttpStatusCode.Forbidden)]
    USER_DISABLED,

    [ErrorMeta(2003, "User is blocked", HttpStatusCode.Forbidden)]
    USER_BLOCKED,

    // Message - 3xxx
    [ErrorMeta(3000, "Message not found", HttpStatusCode.NotFound)]
    MESSAGE_NOT_FOUND,

    [ErrorMeta(3001, "Cannot send message to yourself", HttpStatusCode.BadRequest)]
    CANNOT_SELF_MESSAGE,

    // Conversation - 4xxx
    [ErrorMeta(4000, "Conversation not found", HttpStatusCode.NotFound)]
    CONVERSATION_NOT_FOUND,

    [ErrorMeta(4001, "Already in conversation", HttpStatusCode.Conflict)]
    ALREADY_IN_CONVERSATION,

    // Common - 9xxx
    [ErrorMeta(9000, "Validation failed", HttpStatusCode.UnprocessableEntity)]
    VALIDATION_ERROR,

    [ErrorMeta(9999, "Internal server error", HttpStatusCode.InternalServerError)]
    INTERNAL_ERROR,
    }

    [AttributeUsage(AttributeTargets.Field)]
public class ErrorMetaAttribute(int code, string message, HttpStatusCode httpStatus) : Attribute
{
    public int Code { get; } = code;
    public string Message { get; } = message;
    public HttpStatusCode HttpStatus { get; } = httpStatus;
}

// Extension đọc metadata
public static class ErrorCodeExtensions
{
    public static ErrorMetaAttribute GetMeta(this ErrorCode errorCode)
    {
        var field = typeof(ErrorCode).GetField(errorCode.ToString())!;
        return field.GetCustomAttribute<ErrorMetaAttribute>()!;
    }
}
}