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
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers
{
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

        [HttpGet("stories")]
        public async Task<IActionResult> GetStories()
        {
            logger.LogInformation("[FeedController] GetStories | UserId={UserId}", CurrentUserId);
            var result = await feedService.GetStoriesAsync(CurrentUserId);
            return Ok(new ApiResponse<List<FeedResponse>> { Result = result });
        }

        [HttpGet("newsfeed")]
        [ProducesResponseType(typeof(ApiResponse<List<FeedResponse>>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> GetNewsfeed()
        {
            logger.LogInformation("[FeedController] GetNewsfeed | UserId={UserId}", CurrentUserId);
            var result = await feedService.GetNewsfeedAsync(CurrentUserId);
            return Ok(new ApiResponse<List<FeedResponse>> { Result = result });
        }

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

        [HttpGet("{feedId}")]
        [ProducesResponseType(typeof(ApiResponse<FeedResponse>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status403Forbidden)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status410Gone)]
        public async Task<IActionResult> GetById(string feedId)
        {
            logger.LogInformation("[FeedController] GetById | FeedId={FeedId} UserId={UserId}", feedId, CurrentUserId);
            var result = await feedService.GetByIdAsync(feedId, CurrentUserId);
            return Ok(new ApiResponse<FeedResponse> { Result = result });
        }

        [HttpGet("user/{userId}")]
        [ProducesResponseType(typeof(ApiResponse<List<FeedResponse>>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> GetUserPosts(string userId)
        {
            logger.LogInformation("[FeedController] GetUserPosts | TargetUserId={TargetUserId} CurrentUserId={CurrentUserId}", userId, CurrentUserId);
            var result = await feedService.GetUserPostsAsync(userId, CurrentUserId);
            return Ok(new ApiResponse<List<FeedResponse>> { Result = result });
        }

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

        [HttpPost("{feedId}/like")]
        [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> ToggleLike(string feedId)
        {
            logger.LogInformation("[FeedController] ToggleLike | FeedId={FeedId} UserId={UserId}", feedId, CurrentUserId);
            var result = await feedService.ToggleLikeAsync(feedId, CurrentUserId);
            return Ok(new ApiResponse<object> { Result = result });
        }

        [HttpPost("{feedId}/view")]
        [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> RecordView(string feedId)
        {
            logger.LogInformation("[FeedController] RecordView | FeedId={FeedId} UserId={UserId}", feedId, CurrentUserId);
            await feedService.TrackViewAsync(feedId, CurrentUserId);
            return Ok(new ApiResponse<object> { Code = 200 });
        }

        [HttpGet("{feedId}/likes")]
        [ProducesResponseType(typeof(ApiResponse<List<LikesListResponse>>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetLikes(string feedId)
        {
            var result = await feedService.GetLikesAsync(feedId, CurrentUserId);
            return Ok(new ApiResponse<LikesListResponse> { Result = result });
        }

        [HttpGet("{feedId}/viewers")]
        [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetViewers(string feedId)
        {
            var result = await feedService.GetViewersAsync(feedId, CurrentUserId);
            return Ok(new ApiResponse<ViewersListResponse> { Result = result });
        }

        [HttpPost("{feedId}/hide")]
        [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
        public async Task<IActionResult> HideFeed(string feedId)
        {
            await feedService.ToggleHidePostAsync(feedId, CurrentUserId);
            return Ok(new ApiResponse<object> { Code = 200 });
        }

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

        [HttpGet("{feedId}/comments")]
        [ProducesResponseType(typeof(ApiResponse<List<CommentResponse>>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetComments(string feedId)
        {
            var result = await feedService.GetCommentsAsync(feedId, CurrentUserId);
            return Ok(new ApiResponse<List<CommentResponse>> { Result = result });
        }
    }
}
