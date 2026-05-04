using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.dtos.Request;
using FluentValidation;

namespace backend.Validators
{
    public class UpdateFeedRequestValidator : AbstractValidator<UpdateFeedRequest>
{
    private static readonly string[] AllowedPrivacy = ["public", "friends", "private"];
    private static readonly string[] AllowedMediaTypes = ["image", "video"];

    public UpdateFeedRequestValidator()
    {
        // all field are optional when update
        // but if there is one, it must be valid

        When(x => x.Caption != null, () =>
        {
            RuleFor(x => x.Caption)
                .NotEmpty().WithMessage("Caption can not be blank")
                .MaximumLength(2000).WithMessage("Caption must not exceed 2000 characters");
        });

        When(x => x.Privacy != null, () =>
        {
            RuleFor(x => x.Privacy)
                .Must(p => AllowedPrivacy.Contains(p))
                .WithMessage("Privacy must be 'public', 'friends' or 'private'");
        });

        When(x => x.Media != null && x.Media.Count > 0, () =>
        {
            RuleForEach(x => x.Media)
                .ChildRules(media =>
                {
                    media.RuleFor(m => m.Url)
                        .NotEmpty().WithMessage("Media URL can not be blank")
                        .Must(url => Uri.TryCreate(url, UriKind.Absolute, out _))
                        .WithMessage("Media URL is invalid");

                    media.RuleFor(m => m.Type)
                        .NotEmpty().WithMessage("Media type can not be blank")
                        .Must(t => AllowedMediaTypes.Contains(t))
                        .WithMessage("Media type must be 'image' or 'video'");
                });
        });
    }
}
}