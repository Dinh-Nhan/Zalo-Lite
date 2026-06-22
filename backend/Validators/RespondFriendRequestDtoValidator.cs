using backend.dtos.Request;
using FluentValidation;

namespace backend.Validators
{
    public class RespondFriendRequestDtoValidator : AbstractValidator<RespondFriendRequestDto>
    {
        public RespondFriendRequestDtoValidator()
        {
            // Accept is a boolean, so it will always be either true or false.
            // Under normal circumstances, just having the rule is enough, or we don't need extensive checks.
            RuleFor(x => x.Accept)
                .NotNull().WithMessage("Accept decision is required (true or false).");
        }
    }
}
