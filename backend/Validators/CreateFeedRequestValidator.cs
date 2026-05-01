using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.dtos.Request;
using FluentValidation;

namespace backend.Validators
{
    public class CreateFeedRequestValidator : AbstractValidator<CreateFeedRequest>
    {
        public CreateFeedRequestValidator()
        {
            RuleFor(x => x.Type)
            .NotEmpty().WithMessage("Type Feed's is required");

            RuleFor(x => x.Privacy)
            .NotEmpty().WithMessage("Privacy is required");
        }
    }
}