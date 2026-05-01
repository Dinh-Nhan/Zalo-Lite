using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.dtos.Request;
using FluentValidation;

namespace backend.Validators
{
   public class UpdateUserRequestValidator : AbstractValidator<UpdateUserRequest>
{
    public UpdateUserRequestValidator()
    {
        RuleFor(x => x.FirstName)
            .MaximumLength(50).WithMessage("First name max 50 characters")
            .When(x => x.FirstName is not null);

        RuleFor(x => x.LastName)
            .MaximumLength(50).WithMessage("Last name max 50 characters")
            .When(x => x.LastName is not null);

        RuleFor(x => x.DateOfBirth)
            .Must(dob => dob < DateOnly.FromDateTime(DateTime.UtcNow))
                .WithMessage("Date of birth must be in the past")
            .Must(dob => dob > DateOnly.FromDateTime(DateTime.UtcNow.AddYears(-100)))
                .WithMessage("Date of birth is not valid")
            .When(x => x.DateOfBirth is not null);

        RuleFor(x => x.Bio)
            .MaximumLength(200).WithMessage("Bio max 200 characters")
            .When(x => x.Bio is not null);
    }
}
}