using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.dtos.Request;
using FluentValidation;

namespace backend.Validators
{
    public class CreateContentRequestValidator : AbstractValidator<CreateContentRequest>
    {
        public CreateContentRequestValidator()
        {
            RuleFor(x => x.Caption)
            .MaximumLength(2000).WithMessage("Caption must not exceed 2000 characters");
        }
    }
}