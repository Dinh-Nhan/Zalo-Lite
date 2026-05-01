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
        [HttpPost]
        public async Task<ApiResponse<FeedResponse>> createFeed(string userId, CreateFeedRequest request)
        {
            return new ApiResponse<FeedResponse>
            {
                Result = await feedService.createFeed(userId, request)
            };
        }

        [HttpGet("/{feedId}")]
        public async Task<ApiResponse<FeedResponse>> getFeed(string feedId, string currentUserId)
        {
            return new ApiResponse<FeedResponse>
            {
                Result = await feedService.GetByIdAsync(feedId, currentUserId)
            };
        }
    }
}