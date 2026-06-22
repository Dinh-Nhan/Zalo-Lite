using backend.dtos.Request;
using FluentValidation;

namespace backend.Validators
{
    public class SendFriendRequestDtoValidator : AbstractValidator<SendFriendRequestDto>
    {
        public SendFriendRequestDtoValidator()
        {
            RuleFor(x => x.AddresseeId)
                .NotEmpty().WithMessage("Addressee ID (recipient UID) is required.");

            RuleFor(x => x.SourceType)
                .NotEmpty().WithMessage("Source type is required.")
                .Must(src => new[] { "search", "phone_contact", "group", "qr_code" }.Contains(src))
                .WithMessage("Source type must be one of: 'search', 'phone_contact', 'group', 'qr_code'.");
        }
    }
}
