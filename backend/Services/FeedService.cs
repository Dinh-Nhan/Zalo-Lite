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

namespace backend.Services
{
    [ScopedService]
    public class FeedService(FirestoreDb db, ILogger<FeedService> logger)
    {
        private static string COLLECTION = "feeds";
        public async Task<FeedResponse> createFeed(string userId, CreateFeedRequest request)
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
            // 1. Lấy feed
            var snapshot = await db.Collection(COLLECTION).Document(id).GetSnapshotAsync();
            if (!snapshot.Exists)
                throw new AppException(ErrorCode.FEED_NOT_FOUND);

            var feed = snapshot.ConvertTo<Feeds>();

            // 2. Story hết hạn
            if (feed.Type == "story" && feed.Settings?.ExpiresAt < DateTime.UtcNow)
                throw new AppException(ErrorCode.FEED_EXPIRED); // 410

            // 3. Kiểm tra privacy
            await CheckPrivacyAsync(feed, currentUserId);

            // 4. Track view
            await TrackViewAsync(feed, id, currentUserId);

            // 5. Map response
            var response = feed.Adapt<FeedResponse>();
            return response with
            {
                Stats = new StatsResponse
                {
                    ViewCount = feed.Stats.Views.Count,
                    LikeCount = feed.Stats.Likes.Count,
                    // Story không có like
                    IsLiked = feed.Type == "post" && feed.Stats.Likes.Contains(currentUserId)
                }
            };
        }

        private async Task CheckPrivacyAsync(Feeds feed, string currentUserId)
        {
            // Author luôn xem được feed của chính mình
            if (feed.UserId == currentUserId) return;

            switch (feed.Privacy)
            {
                case "public":
                    return; // Cho phép tất cả

                case "private":
                    throw new AppException(ErrorCode.FORBIDDEN); // Chỉ author

                case "friends":
                    var areFriends = await AreFriendsAsync(feed.UserId, currentUserId);
                    if (!areFriends)
                        throw new AppException(ErrorCode.FORBIDDEN);
                    break;
            }
        }

        private async Task<bool> AreFriendsAsync(string userId1, string userId2)
        {
            // Friend 2 chiều: check cả 2 phía trong collection "friends"
            var friendDoc = await db.Collection("friends")
                .Document($"{userId1}_{userId2}")
                .GetSnapshotAsync();

            if (friendDoc.Exists) return true;

            // Hoặc chiều ngược lại
            var friendDocReverse = await db.Collection("friends")
                .Document($"{userId2}_{userId1}")
                .GetSnapshotAsync();

            return friendDocReverse.Exists;
        }

        private async Task TrackViewAsync(Feeds feed, string feedId, string currentUserId)
        {
            var docRef = db.Collection(COLLECTION).Document(feedId);

            if (feed.Type == "story")
            {
                // Story: chỉ đếm 1 lần / user
                if (!feed.Stats.Views.Contains(currentUserId))
                {
                    await docRef.UpdateAsync("Stats.Views",
                        FieldValue.ArrayUnion(currentUserId));
                }
            }
            else
            {
                // Post: đếm mỗi lần xem (lưu count thay vì array nếu muốn)
                await docRef.UpdateAsync("Stats.Views",
                    FieldValue.ArrayUnion(currentUserId));
            }
        }


    }

}