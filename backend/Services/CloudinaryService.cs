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
                    "[CloudinaryService] Cloudinary chưa được cấu hình đầy đủ — các API upload media sẽ không hoạt động. "
                    + "Vui lòng bổ sung CloudName, ApiKey, ApiSecret vào appsettings.Development.json");
                _isConfigured = false;
                return;
            }

            _isConfigured = true;
            var account = new Account(s.CloudName, s.ApiKey, s.ApiSecret);
            _cloudinary = new Cloudinary(account) { Api = { Secure = true } };
        }

        private void EnsureConfigured()
        {
            if (!_isConfigured)
                throw new InvalidOperationException(
                    "Cloudinary chưa được cấu hình. Vui lòng bổ sung CloudName, ApiKey, ApiSecret vào appsettings.Development.json");
        }

        //---------------------Feeds---------------------

        /// <summary>
        /// Upload một file lên Cloudinary.
        /// Trả về (url, publicId, MediaType).
        /// </summary>
        public async Task<(string Url, string PublicId, string MediaType)> UploadAsync(
            IFormFile file,
            string userId,
            string feedId,
            string feedType)
        {
            EnsureConfigured();
            await using var stream = file.OpenReadStream();
            var isVideo = file.ContentType.StartsWith("video/");
            var mediaType = isVideo ? "video" : "image";

            // feeds/{userId}/{posts|stories}/{feedId}/
            var folder = $"feeds/{userId}/{feedType}s/{feedId}";

            if (isVideo)
            {
                var result = await _cloudinary!.UploadAsync(new VideoUploadParams
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
                var result = await _cloudinary!.UploadAsync(new ImageUploadParams
                {
                    File = new FileDescription(file.FileName, stream),
                    Folder = folder,
                    Transformation = new Transformation().Quality("auto").FetchFormat("auto")
                });

                if (result.Error != null)
                {
                    _logger.LogError("[Cloudinary] Image upload failed: {Message}", result.Error.Message);
                    throw new Exception($"Cloudinary image upload failed: {result.Error.Message}");
                }

                _logger.LogInformation("[Cloudinary] Uploaded image {PublicId}", result.PublicId);
                return (result.SecureUrl.ToString(), result.PublicId, mediaType);
            }
        }
        public async Task DeleteFolderAsync(string userId, string feedId, string feedType)
        {
            EnsureConfigured();
            var folder = $"feeds/{userId}/{feedType}s/{feedId}";

            // Folder chỉ xóa được khi rỗng
            // Nên phải xóa hết files trước — nhưng gọi method này từ FeedService
            // thì publicIds đã được xóa trước đó rồi, giờ chỉ cần xóa folder
            try
            {
                await _cloudinary!.DeleteFolderAsync(folder);
                _logger.LogInformation("[Cloudinary] Deleted folder {Folder}", folder);
            }
            catch (Exception ex)
            {
                _logger.LogWarning("[Cloudinary] Could not delete folder {Folder}: {Msg}",
                    folder, ex.Message);
            }
        }
        public async Task DeleteManyAsync(IEnumerable<(string PublicId, bool IsVideo)> assets)
        {
            EnsureConfigured();
            foreach (var (publicId, isVideo) in assets)
            {
                await _cloudinary!.DestroyAsync(new DeletionParams(publicId)
                {
                    ResourceType = isVideo ? ResourceType.Video : ResourceType.Image
                });
                _logger.LogInformation("[Cloudinary] Deleted {PublicId}", publicId);
            }
        }

        //---------------------Users---------------------
        /// <summary>
        /// Upload avatar cho user.
        /// Trả về (Url, PublicId).
        /// </summary>
        public async Task<(string Url, string PublicId)> UploadAvatarAsync(
            IFormFile file,
            string userId)
        {
            EnsureConfigured();
            await using var stream = file.OpenReadStream();

            // avatars/{userId}/
            var folder = $"user-avatars/{userId}";

            var result = await _cloudinary!.UploadAsync(new ImageUploadParams
            {
                File = new FileDescription(file.FileName, stream),
                Folder = folder,
                Transformation = new Transformation()
                    .Width(400).Height(400)
                    .Crop("fill")           // crop vuông, focus center
                    .Quality("auto")
                    .FetchFormat("auto")
            });

            _logger.LogInformation("[Cloudinary] Uploaded avatar {PublicId} for user {UserId}",
                result.PublicId, userId);

            return (result.SecureUrl.ToString(), result.PublicId);
        }

        /// <summary>
        /// Xóa avatar cũ theo publicId.
        /// </summary>
        public async Task DeleteAvatarAsync(string publicId)
        {
            if (string.IsNullOrEmpty(publicId)) return;
            EnsureConfigured();

            await _cloudinary!.DestroyAsync(new DeletionParams(publicId)
            {
                ResourceType = ResourceType.Image
            });

            _logger.LogInformation("[Cloudinary] Deleted avatar {PublicId}", publicId);
        }

        /// <summary>
        /// Xóa toàn bộ folder avatar của user.
        /// </summary>
        public async Task DeleteUserFolderAsync(string userId)
        {
            EnsureConfigured();
            var folder = $"user-avatars/{userId}";

            try
            {
                await _cloudinary!.DeleteFolderAsync(folder);
                _logger.LogInformation("[Cloudinary] Deleted avatar folder {Folder}", folder);
            }
            catch (Exception ex)
            {
                _logger.LogWarning("[Cloudinary] Could not delete avatar folder {Folder}: {Msg}",
                    folder, ex.Message);
            }
        }
    }
}