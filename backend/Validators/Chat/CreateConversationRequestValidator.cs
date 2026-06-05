using backend.dtos.Request.Chat;
using FluentValidation;

namespace backend.Validators.Chat;

public class CreateConversationRequestValidator : AbstractValidator<CreateConversationRequest>
{
    public CreateConversationRequestValidator()
    {
        RuleFor(x => x.Type)
            .NotEmpty().WithMessage("Type is required")
            .Must(type => type == "private" || type == "group")
            .WithMessage("Type must be 'private' or 'group'");

        RuleFor(x => x.ParticipantIds)
            .NotEmpty().WithMessage("At least one participant is required")
            .Must(ids => ids.Count > 0).WithMessage("At least one participant is required");

        When(x => x.Type == "private", () =>
        {
            RuleFor(x => x.ParticipantIds)
                .Must(ids => ids.Count == 1)
                .WithMessage("Private chat must have exactly 1 other participant");
        });

        When(x => x.Type == "group", () =>
        {
            RuleFor(x => x.GroupName)
                .NotEmpty().WithMessage("Group name is required for group conversations")
                .MaximumLength(100).WithMessage("Group name must not exceed 100 characters");
        });
    }
}
