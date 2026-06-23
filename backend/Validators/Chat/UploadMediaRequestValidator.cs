using backend.dtos.Request.Chat;
using FluentValidation;

namespace backend.Validators.Chat;

public class UploadMediaRequestValidator : AbstractValidator<UploadMediaRequest>
{
    private static readonly string[] AllowedMediaMimeTypes =
    [
        "image/jpeg", "image/png", "image/gif", "image/webp",
        "video/mp4", "video/quicktime", "video/x-msvideo", "video/webm", "video/x-matroska",
        "audio/mpeg", "audio/aac", "audio/wav", "audio/ogg", "audio/m4a", "audio/mp4", "audio/x-m4a", "audio/webm", "audio/amr", "audio/3gpp"
    ];

    private const long MaxImageSize = 10 * 1024 * 1024; // 10 MB
    private const long MaxVideoSize = 100 * 1024 * 1024; // 100 MB
    private const long MaxAudioSize = 20 * 1024 * 1024; // 20 MB

    public UploadMediaRequestValidator()
    {
        RuleFor(x => x.ConversationId)
            .NotEmpty().WithMessage("Conversation ID is required.");

        RuleFor(x => x.File)
            .NotNull().WithMessage("File is required.")
            .Must(file => file == null || file.Length > 0)
            .WithMessage("Tệp tin tải lên trống (kích thước bằng 0).")
            .Must(file => file == null || AllowedMediaMimeTypes.Contains(file.ContentType))
            .WithMessage(x => $"Định dạng tệp '{x.File?.ContentType}' không được hỗ trợ trong tin nhắn.")
            .Must((req, file) =>
            {
                if (file == null || string.IsNullOrEmpty(file.ContentType)) return true;
                var isVideo = file.ContentType.StartsWith("video/");
                var isAudio = file.ContentType.StartsWith("audio/");
                var maxSize = isVideo ? MaxVideoSize : (isAudio ? MaxAudioSize : MaxImageSize);
                return file.Length <= maxSize;
            })
            .WithMessage((req, file) =>
            {
                if (file == null || string.IsNullOrEmpty(file.ContentType)) return string.Empty;
                var isVideo = file.ContentType.StartsWith("video/");
                var isAudio = file.ContentType.StartsWith("audio/");
                var maxSize = isVideo ? MaxVideoSize : (isAudio ? MaxAudioSize : MaxImageSize);
                var limitMb = maxSize / (1024 * 1024);
                return $"Kích thước tệp vượt quá giới hạn cho phép ({limitMb} MB).";
            });
    }
}
