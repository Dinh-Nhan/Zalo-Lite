namespace backend.dtos.Response.Chat;

public class ConversationResponse
{
    public string Id { get; set; } = null!;
    public string Type { get; set; } = null!;
    public List<ParticipantResponse> Participants { get; set; } = new();
    public MessageResponse? LastMessage { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    // Group specific
    public string? GroupName { get; set; }
    public string? GroupAvatarUrl { get; set; }
    public string? GroupDescription { get; set; }
    public string? CreatedBy { get; set; }

    // For private chat - other user info
    public string? OtherUserId { get; set; }
    public string? OtherUserName { get; set; }
    public string? OtherUserAvatar { get; set; }
    public bool? OtherUserOnline { get; set; }
    public DateTime? OtherUserLastSeen { get; set; }

    // User specific settings
    public bool IsMuted { get; set; }
    public bool IsPinned { get; set; }
    public int UnreadCount { get; set; }

    // Pinned message
    public string? PinnedMessageId { get; set; }
    public string? PinnedMessageContent { get; set; }

    public bool IsArchived { get; set; }
}

public class ParticipantResponse
{
    public string UserId { get; set; } = null!;
    public string UserName { get; set; } = null!;
    public string Avatar { get; set; } = null!;
    public string Role { get; set; } = null!;
    public DateTime JoinedAt { get; set; }
    public DateTime? LastSeen { get; set; }
    public string? Nickname { get; set; }
    public bool IsOnline { get; set; }
}
