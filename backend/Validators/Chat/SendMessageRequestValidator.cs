using backend.dtos.Request.Chat;
using FluentValidation;

namespace backend.Validators.Chat;

public class SendMessageRequestValidator : AbstractValidator<SendMessageRequest>
{
    public SendMessageRequestValidator()
    {
        RuleFor(x => x.ConversationId)
            .NotEmpty().WithMessage("Conversation ID is required");

        RuleFor(x => x.Type)
            .NotEmpty().WithMessage("Message type is required")
            .Must(type => new[] { "text", "image", "video", "audio", "file", "sticker", "location", "contact", "call" }.Contains(type))
            .WithMessage("Invalid message type");

        RuleFor(x => x.Content)
            .NotEmpty().WithMessage("Content is required")
            .MaximumLength(5000).WithMessage("Content must not exceed 5000 characters");

        // Chỉ media thật sự mới cần MediaUrl (call/location/contact không cần)
        When(x => new[] { "image", "video", "audio", "file", "sticker" }.Contains(x.Type), () =>
        {
            RuleFor(x => x.MediaUrl)
                .NotEmpty().WithMessage("Media URL is required for media messages");
        });
    }
}
