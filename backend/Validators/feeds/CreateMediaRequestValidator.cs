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
        private static readonly string[] AllowedMimeTypes =
        [
            "image/jpeg", "image/png", "image/gif", "image/webp",
            "video/mp4", "video/quicktime", "video/x-msvideo",
            "video/webm", "video/x-matroska"
        ];

        private const long MaxImageSize = 10 * 1024 * 1024;   // 10 MB
        private const long MaxVideoSize = 100 * 1024 * 1024;  // 100 MB

        public CreateMediaRequestValidator()
        {
            RuleFor(x => x.File)
                .NotNull().WithMessage("Media file is required");

            When(x => x.File != null, () =>
            {
                RuleFor(x => x.File.ContentType)
                    .Must(ct => AllowedMimeTypes.Contains(ct))
                    .WithMessage("File must be image (jpg/png/gif/webp) or video (mp4/mov/avi/webm/mkv)");

                RuleFor(x => x.File)
                    .Must(f =>
                    {
                        var isVideo = f.ContentType.StartsWith("video/");
                        return isVideo
                            ? f.Length <= MaxVideoSize
                            : f.Length <= MaxImageSize;
                    })
                    .WithMessage("Image max 10MB, video max 100MB");
            });
        }
    }
}