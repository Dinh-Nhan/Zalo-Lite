using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.Attributes;
using backend.dtos.Request;
using backend.dtos.Response;
using backend.dtos.Response.Feeds;
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
    public class FeedService(FirestoreDb db, IMapper mapper, ILogger<FeedService> logger, CloudinaryService cloudinaryService)
    {
        // get story bar 
        public async Task<List<FeedResponse>> GetStoriesAsync(string userId)
        {
            var friendIdsTask = GetFriendIdsAsync(userId);
            var mutedStoryIdsTask = GetMutedStoryUserIdsAsync(userId);
            await Task.WhenAll(friendIdsTask, mutedStoryIdsTask);

            var friendIds = friendIdsTask.Result;
            var mutedStoryIds = mutedStoryIdsTask.Result;

            if (friendIds.Count == 0)
            {
                logger.LogInformation("[FeedService] User {UserId} has no friends, returning empty stories", userId);
                return [];
            }

            var now = Timestamp.FromDateTime(DateTime.UtcNow);

            var stories = await QueryFeedsByBatchAsync(db, friendIds, "story",
                (col, batch) => col
                    .WhereEqualTo("type", "story")
                    .WhereIn("user_id", batch)
                    .WhereGreaterThan("settings.expires_at", now)
                    .WhereEqualTo("deleted_at", null)
                    .OrderByDescending("create_at"));

            var filtered = stories.Where(s => !mutedStoryIds.Contains(s.UserId)).ToList();

            // Query tất cả author 1 lần
            var authorIds = filtered.Select(s => s.UserId);
            var authors = await GetUsersByIdsAsync(authorIds);

            return filtered
                .Where(s => authors.ContainsKey(s.UserId))
                .Select(s => ToResponse(s, userId, authors[s.UserId]))
                .ToList();
        }


        //get new feeds
        public async Task<List<FeedResponse>> GetNewsfeedAsync(string userId)
        {
            var friendIdsTask = GetFriendIdsAsync(userId);
            var mutedUserIdsTask = GetMutedUserIdsAsync(userId);
            var hiddenPostIdsTask = GetHiddenPostIdsAsync(userId);
            await Task.WhenAll(friendIdsTask, mutedUserIdsTask, hiddenPostIdsTask);

            var friendIds = friendIdsTask.Result;
            var mutedUserIds = mutedUserIdsTask.Result;
            var hiddenPostIds = hiddenPostIdsTask.Result;

            var targetIds = friendIds.Append(userId).Distinct().ToList();

            var posts = await QueryFeedsByBatchAsync(db, targetIds, "post",
                (col, batch) => col
                    .WhereEqualTo("type", "post")
                    .WhereIn("user_id", batch)
                    .WhereNotEqualTo("privacy", "private")
                    .WhereEqualTo("deleted_at", null)
                    .OrderByDescending("create_at"));

            var filtered = posts
            .Where(p => !mutedUserIds.Contains(p.UserId))
            .Where(p => !hiddenPostIds.Contains(p.Id))
            .ToList();

            var authorIds = filtered.Select(p => p.UserId);
            var authors = await GetUsersByIdsAsync(authorIds);

            return filtered
                .Where(p => authors.ContainsKey(p.UserId))
                .Select(p => ToResponse(p, userId, authors[p.UserId]))
                .ToList();
        }

        // create feed (story or post)
        public async Task<FeedResponse> CreateFeedAsync(string userId, CreateFeedRequest request)
        {
            var now = Timestamp.FromDateTime(DateTime.UtcNow);
            var docRef = db.Collection("feeds").Document();
            var feedId = docRef.Id;

            var mediaList = new List<Dictionary<String, Object>>();

            foreach (var media in request.Content.Media)
            {
                var (url, publicId, MediaType) = await cloudinaryService.UploadAsync(media.File, userId, feedId, request.Type);
                mediaList.Add(new Dictionary<string, object>
                {
                    ["url"] = url,
                    ["type"] = MediaType,
                    ["public_id"] = publicId
                });
            }

            var data = new Dictionary<string, object?>
            {
                ["user_id"] = userId,
                ["type"] = request.Type,
                ["content"] = new Dictionary<string, object>
                {
                    ["caption"] = request.Content.Caption,
                    ["media"] = mediaList
                },
                ["privacy"] = request.Privacy,
                ["settings"] = new Dictionary<string, object?>
                {
                    ["is_expired"] = false,
                    ["expires_at"] = request.Type == "story"
                        ? Timestamp.FromDateTime(DateTime.UtcNow.AddHours(24))
                        : null
                },
                ["stats"] = new Dictionary<string, object>
                {
                    ["views"] = new List<string>(),
                    ["likes"] = new List<string>()
                },
                ["create_at"] = now,
                ["deleted_at"] = null
            };

            logger.LogInformation("[FeedService] Creating {Type} for user {UserId}", request.Type, userId);

            await docRef.SetAsync(data);
            var snap = await docRef.GetSnapshotAsync();

            if (!snap.Exists)
                throw new AppException(ErrorCode.INTERNAL_ERROR);

            var feed = snap.ConvertTo<Feeds>();
            var authorSnap = await db.Collection("users").Document(userId).GetSnapshotAsync();
            if (!authorSnap.Exists) throw new AppException(ErrorCode.USER_NOT_FOUND);
            var author = authorSnap.ConvertTo<User>();

            logger.LogInformation("[FeedService] Created feed {FeedId}", feed.Id);
            return ToResponse(feed, userId, author);
        }

        // get feed by id 

        public async Task<FeedResponse> GetByIdAsync(string feedId, string userId)
        {
            var snap = await db.Collection("feeds").Document(feedId).GetSnapshotAsync();

            if (!snap.Exists || snap.GetValue<object>("deleted_at") != null)
                throw new AppException(ErrorCode.FEED_NOT_FOUND);

            var feed = snap.ConvertTo<Feeds>();

            if (feed.Type == "story" &&
                feed.Settings.ExpiresAt.HasValue &&
                feed.Settings.ExpiresAt.Value < DateTime.UtcNow)
                throw new AppException(ErrorCode.FEED_EXPIRED);

            var authorSnap = await db.Collection("users").Document(feed.UserId).GetSnapshotAsync();
            if (!authorSnap.Exists) throw new AppException(ErrorCode.USER_NOT_FOUND);
            var author = authorSnap.ConvertTo<User>();

            return ToResponse(feed, userId, author);
        }

        // update feed
        public async Task<FeedResponse> UpdateFeedAsync(string feedId, string userId, UpdateFeedRequest request)
        {
            var docRef = db.Collection("feeds").Document(feedId);
            var snap = await docRef.GetSnapshotAsync();

            // Kiểm tra tồn tại
            if (!snap.Exists || snap.GetValue<object?>("deleted_at") != null)
                throw new AppException(ErrorCode.FEED_NOT_FOUND);

            var feed = snap.ConvertTo<Feeds>();

            // Chỉ chủ bài mới được sửa
            if (feed.UserId != userId)
                throw new AppException(ErrorCode.FORBIDDEN);

            // Chỉ post mới được sửa, story không cho sửa
            if (feed.Type != "post")
                throw new AppException(ErrorCode.FEED_STORY_NOT_EDITABLE);

            // Chỉ update các field được gửi lên (partial update)
            var updates = new Dictionary<string, object>();

            if (request.Caption != null)
                updates["content.caption"] = request.Caption;

            if (request.Privacy != null)
                updates["privacy"] = request.Privacy;

            // nếu có cập nhật media thì xóa các image/video cũ trên cloud và thêm mới
            if (request.Media != null)
            {

                var oldAssets = feed.Content.Media
                .Where(m => !string.IsNullOrEmpty(m.PublicId))
                .Select(m => (m.PublicId!, m.Type == "video"));

                await cloudinaryService.DeleteManyAsync(oldAssets);

                var mediaList = new List<Dictionary<string, Object>>();
                foreach (var media in request.Media)
                {
                    var (url, publicId, mediaType) = await cloudinaryService.UploadAsync(media.File, userId, feed.Id, feed.Type);

                    mediaList.Add(new Dictionary<string, object>
                    {
                        ["url"] = url,
                        ["type"] = mediaType,
                        ["public_id"] = publicId
                    });
                }
                updates["content.media"] = mediaList;


            }

            if (updates.Count == 0)
                throw new AppException(ErrorCode.FEED_NOTHING_TO_UPDATE);

            updates["updated_at"] = Timestamp.FromDateTime(DateTime.UtcNow);

            logger.LogInformation("[FeedService] Updating feed {FeedId} by user {UserId}", feedId, userId);

            await docRef.UpdateAsync(updates);

            var updated = await docRef.GetSnapshotAsync();

            var authorSnap = await db.Collection("users").Document(userId).GetSnapshotAsync();
            if (!authorSnap.Exists) throw new AppException(ErrorCode.USER_NOT_FOUND);
            var author = authorSnap.ConvertTo<User>();

            return ToResponse(updated.ConvertTo<Feeds>(), userId, author);
        }

        // soft delete (set deletedAt = now)
        public async Task DeleteFeedAsync(string feedId, string userId)
        {
            var docRef = db.Collection("feeds").Document(feedId);
            var snap = await docRef.GetSnapshotAsync();

            if (!snap.Exists || snap.GetValue<object?>("deleted_at") != null)
                throw new AppException(ErrorCode.FEED_NOT_FOUND);

            var feed = snap.ConvertTo<Feeds>();

            if (feed.UserId != userId) throw new AppException(ErrorCode.FORBIDDEN);

            // ── Xóa từng file theo publicId đã lưu — không cần query Cloudinary ──
            await cloudinaryService.DeleteManyAsync(
                feed.Content.Media
                    .Where(m => !string.IsNullOrEmpty(m.PublicId))
                    .Select(m => (m.PublicId!, m.Type == "video"))
            );
            // sau khi đã xóa các file thì xóa luôn folder
            await cloudinaryService.DeleteFolderAsync(userId, feed.Id, feed.Type);

            await docRef.UpdateAsync(new Dictionary<string, object>
            {
                ["deleted_at"] = Timestamp.FromDateTime(DateTime.UtcNow)
            });

            logger.LogInformation("[FeedService] Deleted feed {FeedId} by {UserId}", feedId, userId);
        }

        // ── Like / Unlike ────────────────────────────────────────────────

        public async Task<LikeResponse> ToggleLikeAsync(string feedId, string userId)
        {
            var docRef = db.Collection("feeds").Document(feedId);
            var snap = await docRef.GetSnapshotAsync();

            if (!snap.Exists || snap.GetValue<object?>("deleted_at") != null)
                throw new AppException(ErrorCode.FEED_NOT_FOUND);

            var feed = snap.ConvertTo<Feeds>();

            // Story đã hết hạn không thể like
            if (feed.Type == "story" &&
                feed.Settings.ExpiresAt.HasValue &&
                feed.Settings.ExpiresAt.Value < DateTime.UtcNow)
                throw new AppException(ErrorCode.FEED_EXPIRED);

            var isLiked = feed.Stats.Likes.Contains(userId);

            if (isLiked)
            {
                // Unlike → xóa userId khỏi mảng
                await docRef.UpdateAsync(new Dictionary<string, object>
                {
                    ["stats.likes"] = FieldValue.ArrayRemove(userId)
                });
                logger.LogInformation("[FeedService] User {UserId} unliked feed {FeedId}", userId, feedId);
            }
            else
            {
                // Like → thêm userId vào mảng
                await docRef.UpdateAsync(new Dictionary<string, object>
                {
                    ["stats.likes"] = FieldValue.ArrayUnion(userId)
                });
                logger.LogInformation("[FeedService] User {UserId} liked feed {FeedId}", userId, feedId);
            }

            // Lấy lại số like sau khi update
            var updated = await docRef.GetSnapshotAsync();
            var updatedFeed = updated.ConvertTo<Feeds>();

            return new LikeResponse
            {
                IsLiked = !isLiked,
                LikeCount = updatedFeed.Stats.Likes.Count
            };
        }

        public async Task<LikesListResponse> GetLikesAsync(string feedId, string userId)
        {
            var snap = await db.Collection("feeds").Document(feedId).GetSnapshotAsync();

            if (!snap.Exists || snap.GetValue<object?>("deleted_at") != null)
                throw new AppException(ErrorCode.FEED_NOT_FOUND);

            var feed = snap.ConvertTo<Feeds>();

            return new LikesListResponse
            {
                FeedId = feedId,
                LikeCount = feed.Stats.Likes.Count,
                IsLiked = feed.Stats.Likes.Contains(userId),
                UserIds = feed.Stats.Likes
            };
        }

        // helper method for feeds
        private async Task<List<string>> GetFriendIdsAsync(string userId)
        {
            logger.LogInformation("[FeedService] Fetching friends for user {UserId}", userId);

            // Query cả 2 chiều: user là sender hoặc là addressee
            var asSenderTask = db.Collection("friendships")
                .WhereEqualTo("sender_id", userId)
                .WhereEqualTo("status", "accepted")
                .GetSnapshotAsync();

            var asAddresseeTask = db.Collection("friendships")
                .WhereEqualTo("addressee_id", userId)
                .WhereEqualTo("status", "accepted")
                .GetSnapshotAsync();

            await Task.WhenAll(asSenderTask, asAddresseeTask);

            var friendIds = new List<string>();

            // Khi user là sender → lấy addressee_id
            friendIds.AddRange(asSenderTask.Result.Documents
                .Select(d => d.GetValue<string>("addressee_id")));

            // Khi user là addressee → lấy sender_id
            friendIds.AddRange(asAddresseeTask.Result.Documents
                .Select(d => d.GetValue<string>("sender_id")));

            return friendIds.Distinct().ToList();
        }

        private async Task<List<string>> GetMutedStoryUserIdsAsync(string userId)
        {
            var snap = await db.Collection("muted_stories")
                .WhereEqualTo("user_id", userId)
                .GetSnapshotAsync();

            return snap.Documents
                .Select(d => d.GetValue<string>("muted_user_id"))
                .ToList();
        }

        // muted story or post with a users 
        private async Task<List<string>> GetMutedUserIdsAsync(string userId)
        {
            var snap = await db.Collection("muted_users")
                .WhereEqualTo("user_id", userId)
                .GetSnapshotAsync();

            return snap.Documents
                .Select(d => d.GetValue<string>("muted_user_id"))
                .ToList();
        }

        private async Task<List<string>> GetHiddenPostIdsAsync(string userId)
        {
            var snap = await db.Collection("hidden_posts")
                .WhereEqualTo("viewer_id", userId)
                .GetSnapshotAsync();

            return snap.Documents
                .Select(d => d.GetValue<string>("post_id"))
                .ToList();
        }

        private FeedResponse ToResponse(Feeds feed, string currentUserId, User author)
        {
            var response = mapper.Map<FeedResponse>(feed);

            response.Stats.IsLiked = feed.Stats.Likes.Contains(currentUserId);

            response.Author = new AuthorResponse
            {
                UserId = author.Id,
                Name = $"{author.FirstName} {author.LastName}",
                AvatarUrl = author.Avatar
            };

            return response;
        }

        private static async Task<List<Feeds>> QueryFeedsByBatchAsync(
            FirestoreDb db,
            List<string> userIds,
            string type,
            Func<CollectionReference, IEnumerable<string>, Query> buildQuery)
        {
            var results = new List<Feeds>();

            foreach (var batch in userIds.Chunk(30))
            {
                var query = buildQuery(db.Collection("feeds"), batch);
                var snap = await query.GetSnapshotAsync();
                results.AddRange(snap.Documents.Select(d => d.ConvertTo<Feeds>()));
            }

            return results;
        }

        // ── Track View ──────────────────────────────────────────────────

        public async Task<ViewResponse> TrackViewAsync(string feedId, string userId)
        {
            var docRef = db.Collection("feeds").Document(feedId);
            var snap = await docRef.GetSnapshotAsync();

            if (!snap.Exists || snap.GetValue<object?>("deleted_at") != null)
                throw new AppException(ErrorCode.FEED_NOT_FOUND);

            var feed = snap.ConvertTo<Feeds>();

            // Chỉ story mới track view
            if (feed.Type != "story")
                throw new AppException(ErrorCode.FEED_VIEW_NOT_ALLOWED);

            // Story đã hết hạn
            if (feed.Settings.ExpiresAt.HasValue &&
                feed.Settings.ExpiresAt.Value < DateTime.UtcNow)
                throw new AppException(ErrorCode.FEED_EXPIRED);

            var hasViewed = feed.Stats.Views.Contains(userId);

            // Chỉ thêm nếu chưa xem, tránh duplicate
            if (!hasViewed)
            {
                await docRef.UpdateAsync(new Dictionary<string, object>
                {
                    ["stats.views"] = FieldValue.ArrayUnion(userId)
                });

                logger.LogInformation("[FeedService] User {UserId} viewed story {FeedId}", userId, feedId);
            }

            var updated = await docRef.GetSnapshotAsync();
            var updatedFeed = updated.ConvertTo<Feeds>();

            return new ViewResponse
            {
                ViewCount = updatedFeed.Stats.Views.Count,
                HasViewed = true
            };
        }

        public async Task<ViewersListResponse> GetViewersAsync(string feedId, string userId)
        {
            var snap = await db.Collection("feeds").Document(feedId).GetSnapshotAsync();

            if (!snap.Exists || snap.GetValue<object?>("deleted_at") != null)
                throw new AppException(ErrorCode.FEED_NOT_FOUND);

            var feed = snap.ConvertTo<Feeds>();

            // Chỉ story mới có viewers
            if (feed.Type != "story")
                throw new AppException(ErrorCode.FEED_VIEW_NOT_ALLOWED);

            // Chỉ chủ story mới xem được danh sách viewers
            if (feed.UserId != userId)
                throw new AppException(ErrorCode.FORBIDDEN);

            return new ViewersListResponse
            {
                FeedId = feedId,
                ViewCount = feed.Stats.Views.Count,
                HasViewed = feed.Stats.Views.Contains(userId),
                UserIds = feed.Stats.Views
            };
        }

        // ── Hide / Unhide Post ──────────────────────────────────────────

        public async Task<HideResponse> ToggleHidePostAsync(string feedId, string userId)
        {
            var snap = await db.Collection("feeds").Document(feedId).GetSnapshotAsync();

            if (!snap.Exists || snap.GetValue<object?>("deleted_at") != null)
                throw new AppException(ErrorCode.FEED_NOT_FOUND);

            var feed = snap.ConvertTo<Feeds>();

            // Chỉ ẩn post, không ẩn story
            if (feed.Type != "post")
                throw new AppException(ErrorCode.FEED_HIDE_NOT_ALLOWED);

            // Không thể ẩn bài của chính mình
            if (feed.UserId == userId)
                throw new AppException(ErrorCode.FEED_CANNOT_HIDE_OWN);

            var hiddenRef = db.Collection("hidden_posts")
                .WhereEqualTo("viewer_id", userId)
                .WhereEqualTo("post_id", feedId);

            var existingSnap = await hiddenRef.GetSnapshotAsync();
            var isHidden = existingSnap.Count > 0;

            if (isHidden)
            {
                // Bỏ ẩn → xóa document
                await existingSnap.Documents[0].Reference.DeleteAsync();
                logger.LogInformation("[FeedService] User {UserId} unhid post {FeedId}", userId, feedId);

                return new HideResponse { IsHidden = false };
            }
            else
            {
                // Ẩn → tạo document mới
                await db.Collection("hidden_posts").AddAsync(new Dictionary<string, object>
                {
                    ["viewer_id"] = userId,
                    ["post_id"] = feedId,
                    ["created_at"] = Timestamp.FromDateTime(DateTime.UtcNow)
                });
                logger.LogInformation("[FeedService] User {UserId} hid post {FeedId}", userId, feedId);

                return new HideResponse { IsHidden = true };
            }
        }

        // ── Feed By UserId ──────────────────────────────────────────────

        public async Task<List<FeedResponse>> GetFeedsByUserIdAsync(string targetUserId, string currentUserId)
        {
            var query = db.Collection("feeds")
                .WhereEqualTo("user_id", targetUserId)
                .WhereEqualTo("type", "post")
                .OrderByDescending("create_at");

            // Nếu xem profile người khác → chỉ thấy public và friends
            // Nếu xem profile của chính mình → thấy tất cả trừ đã xóa
            if (targetUserId != currentUserId)
                query = query.WhereNotEqualTo("privacy", "private");

            var snap = await query.GetSnapshotAsync();

            var feeds = snap.Documents
            .Select(d => d.ConvertTo<Feeds>())
            .Where(f => f.DeletedAt == null)
            .ToList();

            var authorIds = feeds.Select(f => f.UserId);
            var authors = await GetUsersByIdsAsync(authorIds);

            return feeds
                .Where(f => authors.ContainsKey(f.UserId))
                .Select(f => ToResponse(f, currentUserId, authors[f.UserId]))
                .ToList();
        }

        // get feeds are deleted to display story or post stored
        public async Task<List<FeedResponse>> getAllFeedDeleted(string currentUserId, string type)
        {
            var query = db.Collection("feeds")
            .WhereEqualTo("user_id", currentUserId)
            .WhereEqualTo("type", type)
            .OrderByDescending("create_at");

            var snapshot = await query.GetSnapshotAsync();
            var feeds = snapshot.Documents
            .Select(d => d.ConvertTo<Feeds>())
            .Where(f => f.DeletedAt == null)
            .ToList();

            var authorIds = feeds.Select(f => f.UserId);
            var authors = await GetUsersByIdsAsync(authorIds);

            return feeds
                .Where(f => authors.ContainsKey(f.UserId))
                .Select(f => ToResponse(f, currentUserId, authors[f.UserId]))
                .ToList();
        }

        private async Task<Dictionary<string, User>> GetUsersByIdsAsync(IEnumerable<string> userIds)
        {
            var distinct = userIds.Distinct().ToList();
            var tasks = distinct.Select(id =>
                db.Collection("users").Document(id).GetSnapshotAsync());

            var snaps = await Task.WhenAll(tasks);

            return snaps
                .Where(s => s.Exists)
                .Select(s => s.ConvertTo<User>())
                .ToDictionary(u => u.Id);
        }
    }

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
