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
            .Must(type => new[] { "text", "image", "video", "audio", "file", "sticker", "location", "contact" }.Contains(type))
            .WithMessage("Invalid message type");

        RuleFor(x => x.Content)
            .NotEmpty().WithMessage("Content is required")
            .MaximumLength(5000).WithMessage("Content must not exceed 5000 characters");

        When(x => x.Type != "text", () =>
        {
            RuleFor(x => x.MediaUrl)
                .NotEmpty().WithMessage("Media URL is required for non-text messages");
        });
    }
}
