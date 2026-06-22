using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.common;
using backend.dtos.Request;
using backend.dtos.Response;
using backend.dtos.Response.Feeds;
using backend.Enums;
using backend.Exceptions;
using backend.Services;
using FirebaseAdmin.Auth;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers
{
    /// <summary>
    /// Controller quản lý bảng tin (Feeds) gồm Bài đăng (Posts) và Tin nhanh (Stories).
    /// </summary>
    [ApiController]
    [Route("/api/[controller]")]
    [FirebaseAuthorize]
    public class FeedController(FeedService feedService, ILogger<FeedController> logger) : ControllerBase
    {
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

        /// <summary>
        /// Lấy danh sách tin nhanh (Stories) của bản thân và bạn bè đang hoạt động (trong vòng 24 giờ).
        /// </summary>
        /// <returns>Danh sách tin nhanh</returns>
        /// <response code="200">Lấy danh sách thành công</response>
        /// <response code="401">Người dùng chưa xác thực</response>
        [HttpGet("stories")]
        [ProducesResponseType(typeof(ApiResponse<List<FeedResponse>>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> GetStories()
        {
            logger.LogInformation("[FeedController] GetStories | UserId={UserId}", CurrentUserId);
            var result = await feedService.GetStoriesAsync(CurrentUserId);
            return Ok(new ApiResponse<List<FeedResponse>> { Result = result });
        }

        /// <summary>
        /// Lấy danh sách bài đăng (Posts) trên Bảng tin (Newsfeed) của bản thân và bạn bè.
        /// </summary>
        /// <returns>Danh sách bài đăng bảng tin</returns>
        /// <response code="200">Lấy bảng tin thành công</response>
        /// <response code="401">Người dùng chưa xác thực</response>
        [HttpGet("newsfeed")]
        [ProducesResponseType(typeof(ApiResponse<List<FeedResponse>>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> GetNewsfeed()
        {
            logger.LogInformation("[FeedController] GetNewsfeed | UserId={UserId}", CurrentUserId);
            var result = await feedService.GetNewsfeedAsync(CurrentUserId);
            return Ok(new ApiResponse<List<FeedResponse>> { Result = result });
        }

        /// <summary>
        /// Lấy gộp cả danh sách Tin nhanh (Stories) và Bài đăng (Posts) của người dùng.
        /// </summary>
        /// <returns>Hợp nhất dữ liệu Stories và Posts</returns>
        /// <response code="200">Lấy danh sách thành công</response>
        /// <response code="401">Người dùng chưa xác thực</response>
        [HttpGet]
        [ProducesResponseType(typeof(ApiResponse<NewsfeedResponse>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> GetAll()
        {
            logger.LogInformation("[FeedController] GetAll | UserId={UserId}", CurrentUserId);

            var storiesTask = feedService.GetStoriesAsync(CurrentUserId);
            var postsTask = feedService.GetNewsfeedAsync(CurrentUserId);
            await Task.WhenAll(storiesTask, postsTask);

            return Ok(new ApiResponse<NewsfeedResponse>
            {
                Result = new NewsfeedResponse
                {
                    Stories = storiesTask.Result,
                    Posts = postsTask.Result
                }
            });
        }

        /// <summary>
        /// Lấy chi tiết một bài đăng hoặc tin nhanh theo ID.
        /// </summary>
        /// <param name="feedId">ID của bài đăng/tin nhanh</param>
        /// <returns>Chi tiết bài đăng/tin nhanh</returns>
        /// <response code="200">Lấy thông tin thành công</response>
        /// <response code="401">Người dùng chưa xác thực</response>
        /// <response code="403">Người dùng không có quyền xem bài đăng này (do cấu hình quyền riêng tư)</response>
        /// <response code="404">Không tìm thấy bài đăng hoặc bài đăng đã bị vô hiệu hóa</response>
        /// <response code="410">Tin nhanh đã hết hạn sử dụng (quá 24 giờ)</response>
        [HttpGet("{feedId}")]
        [ProducesResponseType(typeof(ApiResponse<FeedResponse>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status403Forbidden)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status410Gone)]
        public async Task<IActionResult> GetById(string feedId)
        {
            logger.LogInformation("[FeedController] GetById | FeedId={FeedId} UserId={UserId}", feedId, CurrentUserId);
            var result = await feedService.GetByIdAsync(feedId, CurrentUserId);
            return Ok(new ApiResponse<FeedResponse> { Result = result });
        }

        /// <summary>
        /// Lấy danh sách bài đăng (Posts) của một người dùng cụ thể (phục vụ trang cá nhân).
        /// </summary>
        /// <param name="userId">UID của người dùng cần xem bài đăng</param>
        /// <returns>Danh sách bài đăng của người dùng</returns>
        /// <response code="200">Lấy danh sách thành công</response>
        /// <response code="401">Người dùng chưa xác thực</response>
        [HttpGet("user/{userId}")]
        [ProducesResponseType(typeof(ApiResponse<List<FeedResponse>>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> GetUserPosts(string userId)
        {
            logger.LogInformation("[FeedController] GetUserPosts | TargetUserId={TargetUserId} CurrentUserId={CurrentUserId}", userId, CurrentUserId);
            var result = await feedService.GetUserPostsAsync(userId, CurrentUserId);
            return Ok(new ApiResponse<List<FeedResponse>> { Result = result });
        }

        /// <summary>
        /// Tạo mới một bài đăng hoặc tin nhanh (hỗ trợ đính kèm nhiều hình ảnh/video).
        /// </summary>
        /// <param name="request">Thông tin bài đăng (caption, privacy, type...)</param>
        /// <param name="files">Danh sách tệp hình ảnh/video đính kèm</param>
        /// <returns>Bài đăng vừa được tạo thành công</returns>
        /// <response code="201">Tạo bài đăng thành công</response>
        /// <response code="401">Người dùng chưa xác thực</response>
        /// <response code="422">Dữ liệu yêu cầu thiếu hoặc file tải lên không hợp lệ</response>
        [HttpPost]
        [ProducesResponseType(typeof(ApiResponse<FeedResponse>), StatusCodes.Status201Created)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status422UnprocessableEntity)]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> CreateFeed([FromForm] CreateFeedRequest request, IFormFileCollection files)
        {
            request.Content ??= new CreateContentRequest();

            if (files.Count > 0)
            {
                request.Content.Media = files
                    .Select(f => new CreateMediaRequest { File = f })
                    .ToList();
            }

            logger.LogInformation("[FeedController] CreateFeed | Type={Type} UserId={UserId} MediaCount={Count}",
                request.Type, CurrentUserId, request.Content?.Media?.Count ?? 0);

            var result = await feedService.CreateFeedAsync(CurrentUserId, request);
            return CreatedAtAction(nameof(GetById), new { feedId = result.Id },
                new ApiResponse<FeedResponse> { Result = result });
        }

        /// <summary>
        /// Cập nhật thông tin bài đăng (chỉ sửa được bài viết Post, không sửa được Story).
        /// </summary>
        /// <param name="feedId">ID bài đăng cần cập nhật</param>
        /// <param name="request">Thông tin cần cập nhật (caption, privacy...)</param>
        /// <param name="files">Danh sách tệp đính kèm mới thay thế tệp cũ (nếu có)</param>
        /// <returns>Thông tin bài đăng sau khi cập nhật</returns>
        /// <response code="200">Cập nhật thành công</response>
        /// <response code="400">Yêu cầu không hợp lệ hoặc cố sửa đổi tin nhanh (Story)</response>
        /// <response code="401">Người dùng chưa xác thực</response>
        /// <response code="403">Người dùng không phải tác giả bài viết này</response>
        /// <response code="404">Không tìm thấy bài viết cần sửa</response>
        /// <response code="422">Thông tin cập nhật sai định dạng</response>
        [HttpPatch("{feedId}")]
        [ProducesResponseType(typeof(ApiResponse<FeedResponse>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status403Forbidden)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status422UnprocessableEntity)]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> UpdateFeed(
            string feedId,
            [FromForm] UpdateFeedRequest request,
            IFormFileCollection files)
        {
            if (files.Count > 0)
            {
                request.Media = files
                    .Select(f => new CreateMediaRequest { File = f })
                    .ToList();
            }

            logger.LogInformation("[FeedController] UpdateFeed | FeedId={FeedId} UserId={UserId}", feedId, CurrentUserId);
            var result = await feedService.UpdateFeedAsync(feedId, CurrentUserId, request);
            return Ok(new ApiResponse<FeedResponse> { Result = result });
        }

        /// <summary>
        /// Xóa bài đăng hoặc tin nhanh (thực hiện xóa mềm, vô hiệu hóa hiển thị).
        /// </summary>
        /// <param name="feedId">ID của bài viết cần xóa</param>
        /// <returns>Thông báo kết quả thành công</returns>
        /// <response code="200">Xóa thành công</response>
        /// <response code="401">Người dùng chưa xác thực</response>
        /// <response code="403">Người dùng không phải chủ sở hữu bài viết này</response>
        /// <response code="404">Không tìm thấy bài viết</response>
        [HttpDelete("{feedId}")]
        [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status403Forbidden)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> DeleteFeed(string feedId)
        {
            logger.LogInformation("[FeedController] DeleteFeed | FeedId={FeedId} UserId={UserId}", feedId, CurrentUserId);
            await feedService.DeleteFeedAsync(feedId, CurrentUserId);
            return Ok(new ApiResponse<object> { Code = 200, Message = "Xóa thành công" });
        }

        /// <summary>
        /// Bày tỏ hoặc hủy bỏ lượt thích (Like/Unlike) đối với bài viết/tin nhanh (Toggle Like).
        /// </summary>
        /// <param name="feedId">ID bài đăng/tin nhanh</param>
        /// <returns>Trạng thái thích và tổng lượt thích mới</returns>
        /// <response code="200">Đã đổi trạng thái thích thành công</response>
        /// <response code="401">Người dùng chưa xác thực</response>
        /// <response code="404">Không tìm thấy bài viết</response>
        [HttpPost("{feedId}/like")]
        [ProducesResponseType(typeof(ApiResponse<LikeResponse>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> ToggleLike(string feedId)
        {
            logger.LogInformation("[FeedController] ToggleLike | FeedId={FeedId} UserId={UserId}", feedId, CurrentUserId);
            var result = await feedService.ToggleLikeAsync(feedId, CurrentUserId);
            return Ok(new ApiResponse<LikeResponse> { Result = result });
        }

        /// <summary>
        /// Đánh dấu là đã xem (Record View) đối với tin nhanh (Story).
        /// </summary>
        /// <param name="feedId">ID tin nhanh (Story)</param>
        /// <returns>Tổng lượt xem mới</returns>
        /// <response code="200">Ghi nhận lượt xem thành công</response>
        /// <response code="400">Chỉ tin nhanh (Story) mới hỗ trợ ghi nhận lượt xem</response>
        /// <response code="401">Người dùng chưa xác thực</response>
        /// <response code="404">Không tìm thấy tin nhanh</response>
        [HttpPost("{feedId}/view")]
        [ProducesResponseType(typeof(ApiResponse<ViewResponse>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> RecordView(string feedId)
        {
            logger.LogInformation("[FeedController] RecordView | FeedId={FeedId} UserId={UserId}", feedId, CurrentUserId);
            var result = await feedService.TrackViewAsync(feedId, CurrentUserId);
            return Ok(new ApiResponse<ViewResponse> { Result = result });
        }

        /// <summary>
        /// Lấy danh sách UID các người dùng đã thích bài viết/tin nhanh.
        /// </summary>
        /// <param name="feedId">ID bài đăng/tin nhanh</param>
        /// <returns>Danh sách UID thích bài viết</returns>
        /// <response code="200">Lấy danh sách thành công</response>
        /// <response code="404">Không tìm thấy bài viết</response>
        [HttpGet("{feedId}/likes")]
        [ProducesResponseType(typeof(ApiResponse<LikesListResponse>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetLikes(string feedId)
        {
            var result = await feedService.GetLikesAsync(feedId, CurrentUserId);
            return Ok(new ApiResponse<LikesListResponse> { Result = result });
        }

        /// <summary>
        /// Lấy danh sách người dùng đã xem tin nhanh (chỉ tác giả của tin nhanh mới xem được).
        /// </summary>
        /// <param name="feedId">ID tin nhanh (Story)</param>
        /// <returns>Danh sách người đã xem tin nhanh</returns>
        /// <response code="200">Lấy danh sách thành công</response>
        /// <response code="400">Bài đăng không phải là tin nhanh (Story)</response>
        /// <response code="403">Người dùng không phải tác giả của tin nhanh này</response>
        /// <response code="404">Không tìm thấy tin nhanh</response>
        [HttpGet("{feedId}/viewers")]
        [ProducesResponseType(typeof(ApiResponse<ViewersListResponse>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status403Forbidden)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetViewers(string feedId)
        {
            var result = await feedService.GetViewersAsync(feedId, CurrentUserId);
            return Ok(new ApiResponse<ViewersListResponse> { Result = result });
        }

        /// <summary>
        /// Ẩn bài viết khỏi bảng tin của bản thân (không hiển thị lại nữa).
        /// </summary>
        /// <param name="feedId">ID bài đăng cần ẩn</param>
        /// <returns>Kết quả ẩn bài đăng</returns>
        /// <response code="200">Ẩn bài đăng thành công</response>
        /// <response code="400">Không thể ẩn bài đăng của chính mình hoặc không phải là bài đăng</response>
        /// <response code="404">Không tìm thấy bài đăng</response>
        [HttpPost("{feedId}/hide")]
        [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> HideFeed(string feedId)
        {
            await feedService.ToggleHidePostAsync(feedId, CurrentUserId);
            return Ok(new ApiResponse<object> { Code = 200 });
        }

        /// <summary>
        /// Thêm bình luận mới vào bài viết bằng định dạng dữ liệu JSON.
        /// </summary>
        /// <param name="feedId">ID bài đăng</param>
        /// <param name="request">Nội dung bình luận dạng JSON</param>
        /// <returns>Bình luận vừa tạo thành công</returns>
        /// <response code="201">Tạo bình luận thành công</response>
        /// <response code="401">Người dùng chưa xác thực</response>
        /// <response code="404">Không tìm thấy bài đăng</response>
        [HttpPost("{feedId}/comments")]
        [Consumes("application/json")]
        [ProducesResponseType(typeof(ApiResponse<CommentResponse>), StatusCodes.Status201Created)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> AddCommentJson(string feedId, [FromBody] CreateCommentJsonRequest request)
        {
            logger.LogInformation("[FeedController] AddCommentJson | FeedId={FeedId} UserId={UserId}", feedId, CurrentUserId);
            var result = await feedService.CreateCommentAsync(feedId, CurrentUserId, new CreateCommentRequest
            {
                Content = request.Content
            });
            return CreatedAtAction(nameof(GetById), new { feedId },
                new ApiResponse<CommentResponse> { Result = result });
        }

        /// <summary>
        /// Thêm bình luận mới vào bài viết bằng định dạng multipart form (hỗ trợ kèm hình ảnh bình luận).
        /// </summary>
        /// <param name="feedId">ID bài đăng</param>
        /// <param name="request">Nội dung bình luận và hình ảnh đính kèm (multipart form)</param>
        /// <returns>Bình luận vừa tạo thành công</returns>
        /// <response code="201">Tạo bình luận thành công</response>
        /// <response code="401">Người dùng chưa xác thực</response>
        /// <response code="404">Không tìm thấy bài đăng</response>
        [HttpPost("{feedId}/comments")]
        [Consumes("multipart/form-data")]
        [ProducesResponseType(typeof(ApiResponse<CommentResponse>), StatusCodes.Status201Created)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> AddCommentForm(string feedId, [FromForm] CreateCommentRequest request)
        {
            logger.LogInformation("[FeedController] AddCommentForm | FeedId={FeedId} UserId={UserId}", feedId, CurrentUserId);
            var result = await feedService.CreateCommentAsync(feedId, CurrentUserId, request);
            return CreatedAtAction(nameof(GetById), new { feedId },
                new ApiResponse<CommentResponse> { Result = result });
        }

        /// <summary>
        /// Lấy toàn bộ danh sách bình luận của bài đăng.
        /// </summary>
        /// <param name="feedId">ID bài đăng</param>
        /// <returns>Danh sách các bình luận</returns>
        /// <response code="200">Lấy danh sách thành công</response>
        [HttpGet("{feedId}/comments")]
        [ProducesResponseType(typeof(ApiResponse<List<CommentResponse>>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetComments(string feedId)
        {
            var result = await feedService.GetCommentsAsync(feedId, CurrentUserId);
            return Ok(new ApiResponse<List<CommentResponse>> { Result = result });
        }

        [HttpPost("comments/{commentId}/like")]
        [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> ToggleCommentLike(string commentId)
        {
            logger.LogInformation("[FeedController] ToggleCommentLike | CommentId={CommentId} UserId={UserId}", commentId, CurrentUserId);
            var result = await feedService.ToggleLikeCommentAsync(commentId, CurrentUserId);
            return Ok(new ApiResponse<object> { Result = result });
        }
    }
}
