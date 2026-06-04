using backend.Attributes;
using FirebaseAdmin.Messaging;

namespace backend.Services;

[ScopedService]
public class FcmService
{
    private readonly ILogger<FcmService> _logger;

    public FcmService(ILogger<FcmService> logger)
    {
        _logger = logger;
    }

    public async Task SendMessageNotificationAsync(
        string fcmToken,
        string title,
        string body,
        string conversationId,
        string senderName,
        bool isGroup)
    {
        try
        {
            var notifBody = isGroup ? $"{senderName}: {body}" : body;

            var message = new Message
            {
                Token = fcmToken,
                Notification = new Notification { Title = title, Body = notifBody },
                Data = new Dictionary<string, string>
                {
                    { "type",            "new_message" },
                    { "conversation_id", conversationId },
                    { "sender_name",     senderName },
                },
                Android = new AndroidConfig
                {
                    Priority = Priority.High,
                    Notification = new AndroidNotification
                    {
                        ChannelId = "messages",
                        Sound     = "default",
                    }
                },
                Apns = new ApnsConfig
                {
                    Aps = new Aps { Sound = "default" }
                }
            };

            var result = await FirebaseMessaging.DefaultInstance.SendAsync(message);
            _logger.LogInformation("[FCM] Sent message notification: {Result}", result);
        }
        catch (Exception ex)
        {
            _logger.LogWarning("[FCM] Failed to send message notification: {Msg}", ex.Message);
        }
    }

    public async Task SendCallNotificationAsync(
        string fcmToken,
        string conversationId,
        string callerId,
        string callerName,
        string callerAvatar,
        string callType)
    {
        try
        {
            var body = callType == "video" ? "Cuộc gọi video đến" : "Cuộc gọi thoại đến";

            var message = new Message
            {
                Token = fcmToken,
                // Data-only message — không có Notification field
                // Background handler sẽ gọi CallKeep để show native call UI
                Data = new Dictionary<string, string>
                {
                    { "type",            "incoming_call" },
                    { "conversation_id", conversationId },
                    { "caller_id",       callerId },
                    { "caller_name",     callerName },
                    { "caller_avatar",   callerAvatar },
                    { "call_type",       callType }
                },
                Android = new AndroidConfig
                {
                    Priority = Priority.High,
                },
                Apns = new ApnsConfig
                {
                    Headers = new Dictionary<string, string>
                    {
                        { "apns-priority", "10" },
                        { "apns-push-type", "alert" }
                    },
                    Aps = new Aps
                    {
                        Alert = new ApsAlert
                        {
                            Title = callerName,
                            Body  = callType == "video"
                                ? "Cuộc gọi video đến"
                                : "Cuộc gọi thoại đến"
                        },
                        Sound = "default"
                    }
                }
            };

            var result = await FirebaseMessaging.DefaultInstance.SendAsync(message);
            _logger.LogInformation("[FCM] Sent call notification: {Result}", result);
        }
        catch (Exception ex)
        {
            _logger.LogWarning("[FCM] Failed to send notification: {Message}", ex.Message);
        }
    }
}
