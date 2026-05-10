using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.dtos.Request;
using backend.dtos.Response;
using backend.Services;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers
{
    [ApiController]
    [Route("/api/[controller]")]
    [FirebaseAuthorize]
    public class FeedController(FeedService feedService)
    {
<<<<<<< HEAD
=======
        private string CurrentUserId
        {
            get
            {
                var token = HttpContext.Items["User"] as FirebaseToken;
                if (token == null)
                    throw new AppException(ErrorCode.UNAUTHENTICATED);
                return token.Uid;
            }
        }

        /// <summary>Lấy danh sách Story Bar</summary>
        /// <remarks>
        /// Trả về các story còn hạn (chưa quá 24h) từ danh sách bạn bè.
        /// Loại trừ story của những người đã bị mute.
        /// </remarks>
        /// <response code="200">Danh sách story thành công</response>
        /// <response code="401">Chưa xác thực</response>
        [HttpGet("stories")]
        public async Task<IActionResult> GetStories()
        {
            logger.LogInformation("[FeedController] GetStories | UserId={UserId}", CurrentUserId);
            var result = await feedService.GetStoriesAsync(CurrentUserId);
            return Ok(ApiResponse<List<FeedResponse>>.SuccessResponse(result));
        }

        /// <summary>Lấy Newsfeed (bài post)</summary>
        /// <remarks>
        /// Trả về các bài post từ bạn bè và của chính mình.
        /// Loại trừ bài đã ẩn, bài của người đã mute và bài có privacy là private.
        /// </remarks>
        /// <response code="200">Danh sách post thành công</response>
        /// <response code="401">Chưa xác thực</response>

        [HttpGet("newsfeed")]
        [ProducesResponseType(typeof(ApiResponse<List<FeedResponse>>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> GetNewsfeed()
        {
            logger.LogInformation("[FeedController] GetNewsfeed | UserId={UserId}", CurrentUserId);
            var result = await feedService.GetNewsfeedAsync(CurrentUserId);
            return Ok(ApiResponse<List<FeedResponse>>.SuccessResponse(result));
        }

        /// <summary>Lấy toàn bộ bảng tin (Story + Newsfeed)</summary>
        /// <remarks>
        /// Gộp cả Story Bar và Newsfeed trong một request duy nhất.
        /// Dùng khi load màn hình chính của ứng dụng.
        /// </remarks>
        /// <response code="200">Story và Newsfeed thành công</response>
        /// <response code="401">Chưa xác thực</response>
        [HttpGet]
        [ProducesResponseType(typeof(ApiResponse<NewsfeedResponse>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> GetAll()
        {
            logger.LogInformation("[FeedController] GetAll | UserId={UserId}", CurrentUserId);

            var storiesTask = feedService.GetStoriesAsync(CurrentUserId);
            var postsTask = feedService.GetNewsfeedAsync(CurrentUserId);
            await Task.WhenAll(storiesTask, postsTask);

            var response = new NewsfeedResponse
            {
                Stories = await storiesTask,
                Posts = await postsTask
            };

            return Ok(ApiResponse<NewsfeedResponse>.SuccessResponse(response));
        }

        /// <summary>Lấy chi tiết một feed theo ID</summary>
        /// <remarks>
        /// Trả về thông tin chi tiết của một post hoặc story.
        /// Story đã hết hạn sẽ trả về lỗi FEED_EXPIRED.
        /// </remarks>
        /// <param name="feedId">ID của feed cần lấy</param>
        /// <response code="200">Thông tin feed thành công</response>
        /// <response code="401">Chưa xác thực</response>
        /// <response code="404">Không tìm thấy feed</response>
        /// <response code="410">Story đã hết hạn</response>
        [HttpGet("{feedId}")]
        [ProducesResponseType(typeof(ApiResponse<FeedResponse>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status410Gone)]
        public async Task<IActionResult> GetById(string feedId)
        {
            logger.LogInformation("[FeedController] GetById | FeedId={FeedId} UserId={UserId}", feedId, CurrentUserId);
            var result = await feedService.GetByIdAsync(feedId, CurrentUserId);
            return Ok(ApiResponse<FeedResponse>.SuccessResponse(result));
        }

        /// <summary>Tạo post hoặc story mới</summary>
        /// <remarks>
        /// Tạo một bài đăng mới. Nếu type là "story" thì tự động đặt thời hạn 24h.
        ///
        /// **Type:**
        /// - `post` → bài đăng thông thường, không có thời hạn
        /// - `story` → tin 24h, tự động hết hạn
        ///
        /// **Privacy:**
        /// - `public` → tất cả bạn bè thấy
        /// - `friends` → chỉ bạn bè thấy
        /// - `private` → chỉ mình thấy
        /// </remarks>
        /// <response code="201">Tạo feed thành công</response>
        /// <response code="401">Chưa xác thực</response>
        /// <response code="422">Dữ liệu không hợp lệ</response>
>>>>>>> 6c973c6 (feature conversation)
        [HttpPost]
        public async Task<ApiResponse<FeedResponse>> createFeed(string userId, CreateFeedRequest request)
        {
<<<<<<< HEAD
            return new ApiResponse<FeedResponse>
            {
                Result = await feedService.createFeed(userId, request)
            };
=======
            logger.LogInformation("[FeedController] CreateFeed | Type={Type} UserId={UserId}", request.Type, CurrentUserId);
            var result = await feedService.CreateFeedAsync(CurrentUserId, request);
            return CreatedAtAction(nameof(GetById), new { feedId = result.Id },
                ApiResponse<FeedResponse>.SuccessResponse(result));
        }

        /// <summary>Chỉnh sửa nội dung post</summary>
        /// <remarks>
        /// Chỉ chủ bài mới được chỉnh sửa. Story không được phép chỉnh sửa.
        /// Chỉ cần gửi lên các field muốn thay đổi (partial update).
        ///
        /// **Các field có thể sửa:**
        /// - `caption` → nội dung bài viết
        /// - `media` → danh sách ảnh/video (ghi đè toàn bộ)
        /// - `privacy` → quyền riêng tư
        /// </remarks>
        /// <param name="feedId">ID của post cần chỉnh sửa</param>
        /// <response code="200">Cập nhật thành công</response>
        /// <response code="400">Story không được phép sửa hoặc không có gì để update</response>
        /// <response code="401">Chưa xác thực</response>
        /// <response code="403">Không phải chủ bài</response>
        /// <response code="404">Không tìm thấy feed</response>
        /// <response code="422">Dữ liệu không hợp lệ</response>
        [HttpPatch("{feedId}")]
        [ProducesResponseType(typeof(ApiResponse<FeedResponse>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status403Forbidden)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status422UnprocessableEntity)]
        public async Task<IActionResult> UpdateFeed(string feedId, [FromBody] UpdateFeedRequest request)
        {
            logger.LogInformation("[FeedController] UpdateFeed | FeedId={FeedId} UserId={UserId}",
                feedId, CurrentUserId);

            var result = await feedService.UpdateFeedAsync(feedId, CurrentUserId, request);

            return Ok(ApiResponse<FeedResponse>.SuccessResponse(result));
        }

        /// <summary>Xóa post hoặc story</summary>
        /// <remarks>
        /// Chỉ chủ bài mới được xóa. Không xóa vĩnh viễn mà chỉ đánh dấu deleted_at.
        /// Sau khi xóa, feed sẽ không còn xuất hiện trong newsfeed hoặc story bar.
        /// </remarks>
        /// <param name="feedId">ID của feed cần xóa</param>
        /// <response code="200">Xóa thành công</response>
        /// <response code="401">Chưa xác thực</response>
        /// <response code="403">Không phải chủ bài</response>
        /// <response code="404">Không tìm thấy feed</response>
        [HttpDelete("{feedId}")]
        [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status403Forbidden)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> DeleteFeed(string feedId)
        {
            logger.LogInformation("[FeedController] DeleteFeed | FeedId={FeedId} UserId={UserId}",
                feedId, CurrentUserId);

            await feedService.DeleteFeedAsync(feedId, CurrentUserId);

            return Ok(ApiResponse<object>.SuccessResponse(null, "Xóa thành công"));
>>>>>>> 6c973c6 (feature conversation)
        }

        [HttpGet("/{feedId}")]
        public async Task<ApiResponse<FeedResponse>> getFeed(string feedId, string currentUserId)
        {
<<<<<<< HEAD
            return new ApiResponse<FeedResponse>
            {
                Result = await feedService.GetByIdAsync(feedId, currentUserId)
            };
=======
            logger.LogInformation("[FeedController] ToggleLike | FeedId={FeedId} UserId={UserId}",
                feedId, CurrentUserId);

            var result = await feedService.ToggleLikeAsync(feedId, CurrentUserId);

            return Ok(ApiResponse<LikeResponse>.SuccessResponse(result));
        }

        /// <summary>Lấy danh sách người đã like</summary>
        /// <remarks>
        /// Trả về danh sách userId đã like cùng tổng số like.
        /// Áp dụng cho cả post và story.
        /// </remarks>
        /// <param name="feedId">ID của feed cần xem danh sách like</param>
        /// <response code="200">Danh sách like thành công</response>
        /// <response code="401">Chưa xác thực</response>
        /// <response code="404">Không tìm thấy feed</response>
        [HttpGet("{feedId}/likes")]
        [ProducesResponseType(typeof(ApiResponse<LikesListResponse>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetLikes(string feedId)
        {
            logger.LogInformation("[FeedController] GetLikes | FeedId={FeedId} UserId={UserId}",
                feedId, CurrentUserId);

            var result = await feedService.GetLikesAsync(feedId, CurrentUserId);

            return Ok(ApiResponse<LikesListResponse>.SuccessResponse(result));
        }

        /// <summary>Xem story (track view)</summary>
        /// <remarks>
        /// Đánh dấu user đã xem story. Chỉ áp dụng cho story, không áp dụng cho post.
        /// Mỗi user chỉ được đếm 1 lần dù xem nhiều lần.
        /// </remarks>
        /// <param name="feedId">ID của story cần track view</param>
        /// <response code="200">Track view thành công</response>
        /// <response code="400">Feed không phải story</response>
        /// <response code="401">Chưa xác thực</response>
        /// <response code="404">Không tìm thấy feed</response>
        /// <response code="410">Story đã hết hạn</response>
        [HttpPost("{feedId}/view")]
        [ProducesResponseType(typeof(ApiResponse<ViewResponse>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status410Gone)]
        public async Task<IActionResult> TrackView(string feedId)
        {
            logger.LogInformation("[FeedController] TrackView | FeedId={FeedId} UserId={UserId}",
                feedId, CurrentUserId);

            var result = await feedService.TrackViewAsync(feedId, CurrentUserId);
            return Ok(ApiResponse<ViewResponse>.SuccessResponse(result));
        }

        /// <summary>Lấy danh sách người đã xem story</summary>
        /// <remarks>
        /// Chỉ chủ story mới xem được danh sách viewers.
        /// Chỉ áp dụng cho story, không áp dụng cho post.
        /// </remarks>
        /// <param name="feedId">ID của story cần xem danh sách viewers</param>
        /// <response code="200">Danh sách viewers thành công</response>
        /// <response code="400">Feed không phải story</response>
        /// <response code="401">Chưa xác thực</response>
        /// <response code="403">Không phải chủ story</response>
        /// <response code="404">Không tìm thấy feed</response>
        [HttpGet("{feedId}/viewers")]
        [ProducesResponseType(typeof(ApiResponse<ViewersListResponse>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status403Forbidden)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetViewers(string feedId)
        {
            logger.LogInformation("[FeedController] GetViewers | FeedId={FeedId} UserId={UserId}",
                feedId, CurrentUserId);

            var result = await feedService.GetViewersAsync(feedId, CurrentUserId);
            return Ok(ApiResponse<ViewersListResponse>.SuccessResponse(result));
        }

        /// <summary>Ẩn hoặc bỏ ẩn một post</summary>
        /// <remarks>
        /// Toggle ẩn post: nếu chưa ẩn thì ẩn, nếu đã ẩn thì bỏ ẩn.
        /// Post đã ẩn sẽ không xuất hiện trong newsfeed.
        /// Chỉ áp dụng cho post, không áp dụng cho story.
        /// Không thể ẩn bài của chính mình.
        /// </remarks>
        /// <param name="feedId">ID của post cần ẩn/bỏ ẩn</param>
        /// <response code="200">Thao tác thành công</response>
        /// <response code="400">Feed không phải post hoặc là bài của chính mình</response>
        /// <response code="401">Chưa xác thực</response>
        /// <response code="404">Không tìm thấy feed</response>
        [HttpPost("{feedId}/hide")]
        [ProducesResponseType(typeof(ApiResponse<HideResponse>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> ToggleHidePost(string feedId)
        {
            logger.LogInformation("[FeedController] ToggleHidePost | FeedId={FeedId} UserId={UserId}",
                feedId, CurrentUserId);

            var result = await feedService.ToggleHidePostAsync(feedId, CurrentUserId);
            return Ok(ApiResponse<HideResponse>.SuccessResponse(result));
        }

        /// <summary>Lấy danh sách feed của một user</summary>
        /// <remarks>
        /// Lấy tất cả post của một user cụ thể theo userId.
        /// Nếu xem profile người khác chỉ thấy post public và friends.
        /// Nếu xem profile của chính mình thấy tất cả trừ đã xóa.
        /// </remarks>
        /// <param name="userId">ID của user cần xem feed</param>
        /// <response code="200">Danh sách feed thành công</response>
        /// <response code="401">Chưa xác thực</response>
        [HttpGet("user/{userId}")]
        [ProducesResponseType(typeof(ApiResponse<List<FeedResponse>>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> GetFeedsByUserId(string userId)
        {
            logger.LogInformation("[FeedController] GetFeedsByUserId | TargetUserId={UserId} CurrentUserId={CurrentUserId}",
                userId, CurrentUserId);

            var result = await feedService.GetFeedsByUserIdAsync(userId, CurrentUserId);
            return Ok(ApiResponse<List<FeedResponse>>.SuccessResponse(result));
        }

        /// <summary>Lấy danh sách feed của chính user mà đã bị xóa</summary>
        /// <remarks>
        ///Lấy tất cả feed tùy thuộc vào type để xem kho lưu trữ.
        /// Type có thể là post or story.
        /// </remarks>
        /// <param name="type">Xem kho lưu trữ theo post hoặc story</param>
        /// <response code="200">Danh sách feed(story or post) thành công</response>
        /// <response code="401">Chưa xác thực</response>
        [HttpGet("me/deleted/{type}")]
        [ProducesResponseType(typeof(ApiResponse<List<FeedResponse>>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> getAllFeedDeleted(string type)
        {
            logger.LogInformation("[FeedController] getAllFeedDeleted | CurrentUserId={CurrentUserId}",
                CurrentUserId);

            var result = await feedService.getAllFeedDeleted(CurrentUserId, type);

            return Ok(ApiResponse<List<FeedResponse>>.SuccessResponse(result));
>>>>>>> 6c973c6 (feature conversation)
        }
    }
}
