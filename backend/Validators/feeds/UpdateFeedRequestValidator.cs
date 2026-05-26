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
    private static readonly string[] AllowedMimeTypes =
        [
            "image/jpeg", "image/png", "image/gif", "image/webp",
            "video/mp4", "video/quicktime", "video/x-msvideo",
            "video/webm", "video/x-matroska"
        ];
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
                // Tái sử dụng CreateMediaRequestValidator — cùng rule validate file
                RuleForEach(x => x.Media)
                    .SetValidator(new CreateMediaRequestValidator());
            });
    }
}
}