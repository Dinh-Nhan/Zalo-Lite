using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.dtos.Request;
using backend.dtos.Response;
using backend.Extensions;
using backend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers
{
    [ApiController]
    [Route("/api/[controller]")]
    [FirebaseAuthorize]
    public class FeedController(FeedService feedService) : ControllerBase
    {
        [HttpPost]
        public async Task<ApiResponse<FeedResponse>> CreateFeed(CreateFeedRequest request)
        {
            var currentUserId = User.GetUid();
            return new ApiResponse<FeedResponse>
            {
                Result = await feedService.createFeed(currentUserId, request)
            };
        }

        [HttpGet("{feedId}")]
        public async Task<ApiResponse<FeedResponse>> GetFeed(string feedId)
        {
            var currentUserId = User.GetUid();
            return new ApiResponse<FeedResponse>
            {
                Result = await feedService.GetByIdAsync(feedId, currentUserId)
            };
        }
    }
}