using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.dtos.Request;
using FluentValidation;

namespace backend.Validators
{
    public class CreateMediaRequestValidator : AbstractValidator<CreateMediaRequest>
    {
        public CreateMediaRequestValidator()
        {
            RuleFor(x => x.Type)
            .NotEmpty().WithMessage("Type Media is required");

            RuleFor(x => x.Url)
            .NotEmpty().WithMessage("Url is required")
            .Must(url => Uri.TryCreate(url, UriKind.Absolute, out var result)
                && (result.Scheme == Uri.UriSchemeHttp || result.Scheme == Uri.UriSchemeHttps)
            )
            .WithMessage("Invalid URL format")
            .Must(url =>
                {
                    var allowedExtensions = new[]
                {
                    // image
                    ".jpg", ".jpeg", ".png", ".gif", ".webp",
                    // video
                    ".mp4", ".mov", ".avi", ".mkv", ".webm"
                };
                    return allowedExtensions.Any(ext => url.ToLower().Contains(ext));
                })
            .WithMessage("Url must be an image or video");
        }
    }
}