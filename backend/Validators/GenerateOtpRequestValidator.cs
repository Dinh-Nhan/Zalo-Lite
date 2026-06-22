using backend.dtos.Request;
using FluentValidation;

namespace backend.Validators
{
    public class GenerateOtpRequestValidator : AbstractValidator<GenerateOtpRequest>
    {
        public GenerateOtpRequestValidator()
        {
            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email is required")
                .EmailAddress().WithMessage("Invalid email format");
        }
    }
}
