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

    //Feed - 5xxx
    [ErrorMeta(5000, "Feed not found", HttpStatusCode.NotFound)]
    FEED_NOT_FOUND,

    [ErrorMeta(5001, "feed is expired", HttpStatusCode.Gone)]
    FEED_EXPIRED,
    // Friendship - 6xxx
    [ErrorMeta(6000, "Friend request not found", HttpStatusCode.NotFound)]
    FRIEND_REQUEST_NOT_FOUND,

    [ErrorMeta(6001, "Cannot send friend request to yourself", HttpStatusCode.BadRequest)]
    CANNOT_SELF_FRIEND,

    [ErrorMeta(6002, "You are already friends with this user", HttpStatusCode.Conflict)]
    ALREADY_FRIENDS,

    [ErrorMeta(6003, "A pending friend request already exists", HttpStatusCode.Conflict)]
    FRIEND_REQUEST_ALREADY_SENT,

    [ErrorMeta(6004, "You have been blocked by this user", HttpStatusCode.Forbidden)]
    BLOCKED_BY_USER,

    [ErrorMeta(6005, "You have blocked this user", HttpStatusCode.Forbidden)]
    YOU_BLOCKED_USER,

    [ErrorMeta(6006, "You can only respond to requests sent to you", HttpStatusCode.Forbidden)]
    NOT_REQUEST_RECIPIENT,

    [ErrorMeta(6007, "This friend request is no longer pending", HttpStatusCode.Conflict)]
    REQUEST_NOT_PENDING,

    [ErrorMeta(6008, "You can only cancel requests that you sent", HttpStatusCode.Forbidden)]
    NOT_REQUEST_SENDER,

    [ErrorMeta(6009, "Cannot block yourself", HttpStatusCode.BadRequest)]
    CANNOT_SELF_BLOCK,

    [ErrorMeta(6010, "You have already blocked this user", HttpStatusCode.Conflict)]
    ALREADY_BLOCKED,
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