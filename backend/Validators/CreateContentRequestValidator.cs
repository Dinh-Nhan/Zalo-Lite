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
            .NotEmpty().WithMessage("Caption is required");

            RuleFor(x => x.Media)
            .NotEmpty().WithMessage("Media is required");
        }
    }
}