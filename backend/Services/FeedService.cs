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

namespace backend.Services
{
    [ScopedService]
    public class FeedService(FirestoreDb db, ILogger<FeedService> logger)
    {
        private static string COLLECTION = "feeds";
        public async Task<FeedResponse> createFeed(String userId, CreateFeedRequest request)
        {
            var feed = request.Adapt<Feeds>();

            feed.UserId = userId;           // lấy từ token
            feed.CreateAt = DateTime.UtcNow;
            feed.DeletedAt = null;
            feed.Type = request.Type;
            feed.Settings = new Settings
            {
                IsExpired = false,
                ExpiresAt = request.Type == "story"
                    ? DateTime.UtcNow.AddHours(24)  // story hết hạn sau 24h
                    : null
            };
            feed.Stats = new Stats
            {
                Views = [],
                Likes = []
            };

            var docRef = await db.Collection(COLLECTION).AddAsync(feed);
            feed.Id = docRef.Id;

            logger.LogInformation("[{UserId}] Feed created: {FeedId}", userId, feed.Id);

            // Map Feeds → FeedResponse
            // Stats.IsLiked cần biết current user → tính thêm sau khi map
            var response = feed.Adapt<FeedResponse>();
            return response;
        }


    public async Task<FeedResponse> GetByIdAsync(string id, string currentUserId)
    {
        var snapshot = await db.Collection(COLLECTION).Document(id).GetSnapshotAsync();

        if (!snapshot.Exists)
            throw new AppException(ErrorCode.FEED_NOT_FOUND);

        var feed = snapshot.ConvertTo<Feeds>();
        var response = feed.Adapt<FeedResponse>();

        // IsLiked không map được trong config vì cần currentUserId
        // → dùng with expression để set thêm sau khi map
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
    }
    
}