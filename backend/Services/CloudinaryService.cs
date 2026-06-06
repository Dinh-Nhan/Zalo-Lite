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

            if (string.IsNullOrWhiteSpace(options.Value.CloudName) || options.Value.CloudName == "placeholder")
            {
                _logger.LogWarning(
                    "[CloudinaryService] Cloudinary chua duoc cau hinh day du — cac API upload media se khong hoat dong. Vui long bo sung CloudName, ApiKey, ApiSecret vao appsettings.Development.json");
                _isConfigured = false;
                return;
            }

            _isConfigured = true;
            var account = new Account(options.Value.CloudName, options.Value.ApiKey, options.Value.ApiSecret);
            _cloudinary = new Cloudinary(account) { Api = { Secure = true } };
        }

        private Cloudinary GetClient()
        {
            if (!_isConfigured || _cloudinary == null)
                throw new InvalidOperationException(
                    "Cloudinary chua duoc cau hinh. Vui long bo sung CloudName, ApiKey, ApiSecret vao appsettings.Development.json");
            return _cloudinary;
        }

        /// <summary>
        /// Upload mot file len Cloudinary.
        /// Tra ve (url, publicId, MediaType).
        /// </summary>
        public async Task<(string Url, string PublicId, string MediaType)> UploadAsync(
            IFormFile file,
            string userId,
            string feedId,
            string feedType)
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
            else
            {
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

        //---------------------Users---------------------

        /// <summary>
        /// Upload avatar cho user.
        /// Tra ve (Url, PublicId).
        /// </summary>
        public async Task<(string Url, string PublicId)> UploadAvatarAsync(
            IFormFile file,
            string userId)
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
                    .Crop("fill")           // crop vuong, focus center
                    .Quality("auto")
                    .FetchFormat("auto")
            });

            _logger.LogInformation("[Cloudinary] Uploaded avatar {PublicId} for user {UserId}",
                result.PublicId, userId);
            return (result.SecureUrl.ToString(), result.PublicId);
        }

        /// <summary>
        /// Xoa avatar cu theo publicId.
        /// </summary>
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

        /// <summary>
        /// Xoa toan bo folder avatar cua user.
        /// </summary>
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
