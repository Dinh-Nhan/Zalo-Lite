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
        private static readonly string[] AllowedTypes = ["post", "story"];
        private static readonly string[] AllowedPrivacy = ["public", "friends", "private"];

        public CreateFeedRequestValidator()
        {
            RuleFor(x => x.Type)
                .NotEmpty().WithMessage("Type is required")
                .Must(t => AllowedTypes.Contains(t))
                .WithMessage("Type must be 'post' or 'story'");

            RuleFor(x => x.Privacy)
                .NotEmpty().WithMessage("Privacy is required")
                .Must(p => AllowedPrivacy.Contains(p))
                .WithMessage("Privacy must be 'public', 'friends' or 'private'");

            RuleFor(x => x.Content)
                .NotNull().WithMessage("Content is required");

            When(x => x.Type != "story" && (x.Content?.Media == null || x.Content.Media.Count == 0), () =>
            {
                RuleFor(x => x.Content!.Caption)
                    .NotEmpty().WithMessage("Caption is required when no media is provided")
                    .MaximumLength(2000).WithMessage("Caption must not exceed 2000 characters");
            });

            // RuleFor(x => x.Content.Media)
            //     .NotEmpty().WithMessage("At least one media file is required");

            // Delegate validate từng media sang CreateMediaRequestValidator
            // RuleForEach(x => x.Content.Media)
            //     .SetValidator(new CreateMediaRequestValidator());
        }
    }
}