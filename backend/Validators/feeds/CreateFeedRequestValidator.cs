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
        private static readonly string[] AllowedMediaTypes = ["image", "video"];

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

            RuleFor(x => x.Content.Caption)
                .NotEmpty().WithMessage("Caption is required")
                .MaximumLength(2000).WithMessage("Caption must not exceed 2000 characters");

            RuleForEach(x => x.Content.Media)
                .ChildRules(media =>
                {
                    media.RuleFor(m => m.Url)
                        .NotEmpty().WithMessage("Media URL is required")
                        .Must(url => Uri.TryCreate(url, UriKind.Absolute, out _))
                        .WithMessage("Media URL is invalid");

                    media.RuleFor(m => m.Type)
                        .NotEmpty().WithMessage("Media type is required")
                        .Must(t => AllowedMediaTypes.Contains(t))
                        .WithMessage("Media type must be 'image' or 'video'");
                });
        }
    }
}