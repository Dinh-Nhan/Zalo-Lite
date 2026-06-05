using backend.Attributes;
using backend.settings;
using CloudinaryDotNet;
using CloudinaryDotNet.Actions;
using Microsoft.Extensions.Options;

namespace backend.Services
{
    [ScopedService]
    public class CloudinaryService
    {
        private readonly Cloudinary? _cloudinary;
        private readonly ILogger<CloudinaryService> _logger;
        private readonly bool _isConfigured;

        public CloudinaryService(
            IOptions<CloudinarySettings> options,
            ILogger<CloudinaryService> logger)
        {
            _logger = logger;
            var s = options.Value;

            if (string.IsNullOrWhiteSpace(s.CloudName) || s.CloudName == "placeholder")
            {
                _logger.LogWarning(
                    "[CloudinaryService] Cloudinary chưa được cấu hình đầy đủ — các API upload media sẽ không hoạt động. Vui lòng bổ sung CloudName, ApiKey, ApiSecret vào appsettings.Development.json");
                _isConfigured = false;
                return;
            }

            _isConfigured = true;
            var account = new Account(s.CloudName, s.ApiKey, s.ApiSecret);
            _cloudinary = new Cloudinary(account) { Api = { Secure = true } };
        }

        private Cloudinary GetClient()
        {
            if (!_isConfigured || _cloudinary == null)
                throw new InvalidOperationException(
                    "Cloudinary chưa được cấu hình. Vui lòng bổ sung CloudName, ApiKey, ApiSecret vào appsettings.Development.json");
            return _cloudinary;
        }

        public async Task<(string Url, string PublicId, string MediaType)> UploadAsync(
            IFormFile file, string userId, string feedId, string feedType)
        {
            var cloudinary = GetClient();
            await using var stream = file.OpenReadStream();
            var isVideo = file.ContentType.StartsWith("video/");
            var mediaType = isVideo ? "video" : "image";
            var folder = $"feeds/{userId}/{feedType}s/{feedId}";

            if (isVideo)
            {
                var result = await cloudinary.UploadAsync(new VideoUploadParams
                {
                    File = new FileDescription(file.FileName, stream),
                    Folder = folder,
                    Transformation = new Transformation().Quality("auto")
                });

                if (result.Error != null)
                {
                    _logger.LogError("[Cloudinary] Video upload failed: {Message}", result.Error.Message);
                    throw new Exception($"Cloudinary video upload failed: {result.Error.Message}");
                }

                _logger.LogInformation("[Cloudinary] Uploaded video {PublicId}", result.PublicId);
                return (result.SecureUrl.ToString(), result.PublicId, mediaType);
            }

            var imageResult = await cloudinary.UploadAsync(new ImageUploadParams
            {
                File = new FileDescription(file.FileName, stream),
                Folder = folder,
                Transformation = new Transformation().Quality("auto").FetchFormat("auto")
            });

            if (imageResult.Error != null)
            {
                _logger.LogError("[Cloudinary] Image upload failed: {Message}", imageResult.Error.Message);
                throw new Exception($"Cloudinary image upload failed: {imageResult.Error.Message}");
            }

            _logger.LogInformation("[Cloudinary] Uploaded image {PublicId}", imageResult.PublicId);
            return (imageResult.SecureUrl.ToString(), imageResult.PublicId, mediaType);
        }

        public async Task DeleteFolderAsync(string userId, string feedId, string feedType)
        {
            var cloudinary = GetClient();
            var folder = $"feeds/{userId}/{feedType}s/{feedId}";
            try
            {
                await cloudinary.DeleteFolderAsync(folder);
                _logger.LogInformation("[Cloudinary] Deleted folder {Folder}", folder);
            }
            catch (Exception ex)
            {
                _logger.LogWarning("[Cloudinary] Could not delete folder {Folder}: {Msg}", folder, ex.Message);
            }
        }

        public async Task DeleteManyAsync(IEnumerable<(string PublicId, bool IsVideo)> assets)
        {
            var cloudinary = GetClient();
            foreach (var (publicId, isVideo) in assets)
            {
                await cloudinary.DestroyAsync(new DeletionParams(publicId)
                {
                    ResourceType = isVideo ? ResourceType.Video : ResourceType.Image
                });
                _logger.LogInformation("[Cloudinary] Deleted {PublicId}", publicId);
            }
        }

        public async Task<(string Url, string PublicId)> UploadAvatarAsync(IFormFile file, string userId)
        {
            var cloudinary = GetClient();
            await using var stream = file.OpenReadStream();
            var folder = $"user-avatars/{userId}";

            var result = await cloudinary.UploadAsync(new ImageUploadParams
            {
                File = new FileDescription(file.FileName, stream),
                Folder = folder,
                Transformation = new Transformation()
                    .Width(400).Height(400)
                    .Crop("fill")
                    .Quality("auto")
                    .FetchFormat("auto")
            });

            _logger.LogInformation("[Cloudinary] Uploaded avatar {PublicId} for user {UserId}", result.PublicId, userId);
            return (result.SecureUrl.ToString(), result.PublicId);
        }

        public async Task DeleteAvatarAsync(string publicId)
        {
            if (string.IsNullOrEmpty(publicId)) return;
            var cloudinary = GetClient();
            await cloudinary.DestroyAsync(new DeletionParams(publicId)
            {
                ResourceType = ResourceType.Image
            });
            _logger.LogInformation("[Cloudinary] Deleted avatar {PublicId}", publicId);
        }

        public async Task DeleteUserFolderAsync(string userId)
        {
            var cloudinary = GetClient();
            var folder = $"user-avatars/{userId}";
            try
            {
                await cloudinary.DeleteFolderAsync(folder);
                _logger.LogInformation("[Cloudinary] Deleted avatar folder {Folder}", folder);
            }
            catch (Exception ex)
            {
                _logger.LogWarning("[Cloudinary] Could not delete avatar folder {Folder}: {Msg}", folder, ex.Message);
            }
        }
    }
}
