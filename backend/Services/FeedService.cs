using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.Attributes;
using backend.dtos.Request;
using backend.dtos.Response;
using backend.Enums;
using backend.Exceptions;
using backend.Models;
using Google.Cloud.Firestore;
using Mapster;
using MapsterMapper;
using Microsoft.Extensions.Logging;

namespace backend.Services
{
    [ScopedService]
    public class FeedService(FirestoreDb db, ILogger<FeedService> logger)
    {
        private static string COLLECTION = "feeds";

        public async Task<FeedResponse> CreateFeedAsync(string userId, CreateFeedRequest request)
        {
            var feed = request.Adapt<Feeds>();

            feed.UserId = userId;
            feed.CreateAt = DateTime.UtcNow;
            feed.DeletedAt = null;
            feed.Type = request.Type;
            feed.Settings = new Settings
            {
                IsExpired = false,
                ExpiresAt = request.Type == "story"
                    ? DateTime.UtcNow.AddHours(24)
                    : null
            };
            feed.Stats = new Stats
            {
                Views = new List<string>(),
                Likes = new List<string>()
            };

            var docRef = await db.Collection(COLLECTION).AddAsync(feed);
            feed.Id = docRef.Id;

            logger.LogInformation("[{UserId}] Feed created: {FeedId}", userId, feed.Id);

            return feed.Adapt<FeedResponse>();
        }

        public async Task<FeedResponse> GetByIdAsync(string id, string currentUserId)
        {
            var snapshot = await db.Collection(COLLECTION).Document(id).GetSnapshotAsync();

            if (!snapshot.Exists)
                throw new AppException(ErrorCode.FEED_NOT_FOUND);

            var feed = snapshot.ConvertTo<Feeds>();
            var response = feed.Adapt<FeedResponse>();

            return response with
            {
                Stats = new StatsResponse
                {
                    ViewCount = response.Stats.ViewCount,
                    LikeCount = response.Stats.LikeCount,
                    IsLiked = feed.Stats.Likes.Contains(currentUserId)
                }
            };
        }

        public Task<List<FeedResponse>> GetStoriesAsync(string currentUserId)
            => Task.FromResult(new List<FeedResponse>());

        public Task<List<FeedResponse>> GetNewsfeedAsync(string currentUserId)
            => Task.FromResult(new List<FeedResponse>());

        public Task<LikeResponse> ToggleLikeAsync(string feedId, string currentUserId)
            => Task.FromResult(new LikeResponse { LikeCount = 0, IsLiked = false });

        public Task<LikesListResponse> GetLikesAsync(string feedId, string currentUserId)
            => Task.FromResult(new LikesListResponse { TotalLikes = 0, UserIds = new List<string>() });

        public Task<ViewResponse> TrackViewAsync(string feedId, string currentUserId)
            => Task.FromResult(new ViewResponse { ViewCount = 0 });

        public Task<ViewersListResponse> GetViewersAsync(string feedId, string currentUserId)
            => Task.FromResult(new ViewersListResponse { ViewerCount = 0, ViewerIds = new List<string>() });

        public Task<HideResponse> ToggleHidePostAsync(string feedId, string currentUserId)
            => Task.FromResult(new HideResponse { IsHidden = true });

        public Task<FeedResponse> UpdateFeedAsync(string feedId, string currentUserId, UpdateFeedRequest request)
            => Task.FromResult(new FeedResponse());

        public Task DeleteFeedAsync(string feedId, string currentUserId)
            => Task.CompletedTask;

        public Task<List<FeedResponse>> GetFeedsByUserIdAsync(string userId, string currentUserId)
            => Task.FromResult(new List<FeedResponse>());

        public Task<List<FeedResponse>> GetAllFeedDeletedAsync(string currentUserId, string type)
            => Task.FromResult(new List<FeedResponse>());
    }
}
