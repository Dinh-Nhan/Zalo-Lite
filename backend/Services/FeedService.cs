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

            var now = Timestamp.FromDateTime(DateTime.UtcNow);

            // Always include the current user so their own stories appear in the story bar,
            // even if they have no friends yet.
            var allStoryAuthors = friendIds.Count > 0
                ? friendIds.Append(userId).ToList()
                : new List<string> { userId };

            var stories = await QueryFeedsByBatchAsync(db, allStoryAuthors, "story",
                (col, batch) => col
                    .WhereEqualTo("type", "story")
                    .WhereIn("user_id", batch)
                    .WhereEqualTo("deleted_at", null));

            var utcNow = DateTime.UtcNow;
            var activeStories = stories
                .Where(s => s.Settings == null || (!s.Settings.IsExpired && (!s.Settings.ExpiresAt.HasValue || s.Settings.ExpiresAt.Value > utcNow)))
                .OrderByDescending(s => s.CreatedAt)
                .ToList();

            var filtered = activeStories.Where(s => !mutedStoryIds.Contains(s.UserId)).ToList();

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
            logger.LogInformation("[FeedService] CreateFeedAsync | Type={Type} MediaCount={Count}",
                request.Type, request.Content?.Media?.Count ?? -1);
            var now = Timestamp.FromDateTime(DateTime.UtcNow);
            var docRef = db.Collection("feeds").Document();
            var feedId = docRef.Id;

            var mediaList = new List<Dictionary<String, Object>>();

            if (request.Content?.Media?.Any() == true)
            {
                foreach (var media in request.Content.Media.Where(m => m.File != null))
                {
                var (url, publicId, MediaType) = await cloudinaryService.UploadAsync(media.File!, userId, feedId, request.Type);
                mediaList.Add(new Dictionary<string, object>
                {
                    ["url"] = url,
                    ["type"] = MediaType,
                    ["public_id"] = publicId
                });
                }
            }

            var data = new Dictionary<string, object?>
            {
                ["user_id"] = userId,
                ["type"] = request.Type,
                ["content"] = new Dictionary<string, object?>
                {
                    ["caption"] = request.Content?.Caption,
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

            if (!snap.Exists || snap.GetValue<object?>("deleted_at") != null)
                throw new AppException(ErrorCode.FEED_NOT_FOUND);

            var feed = snap.ConvertTo<Feeds>();

            if (feed.UserId != userId)
                throw new AppException(ErrorCode.FORBIDDEN);

            if (feed.Type != "post")
                throw new AppException(ErrorCode.FEED_STORY_NOT_EDITABLE);

            var updates = new Dictionary<string, object>();

            if (request.Caption != null)
                updates["content.caption"] = request.Caption;

            if (request.Privacy != null)
                updates["privacy"] = request.Privacy;

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

            await cloudinaryService.DeleteManyAsync(
                feed.Content.Media
                    .Where(m => !string.IsNullOrEmpty(m.PublicId))
                    .Select(m => (m.PublicId!, m.Type == "video"))
            );
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

            if (feed.Type == "story" &&
                feed.Settings.ExpiresAt.HasValue &&
                feed.Settings.ExpiresAt.Value < DateTime.UtcNow)
                throw new AppException(ErrorCode.FEED_EXPIRED);

            var isLiked = feed.Stats.Likes.Contains(userId);

            if (isLiked)
            {
                await docRef.UpdateAsync(new Dictionary<string, object>
                {
                    ["stats.likes"] = FieldValue.ArrayRemove(userId)
                });
                logger.LogInformation("[FeedService] User {UserId} unliked feed {FeedId}", userId, feedId);
            }
            else
            {
                await docRef.UpdateAsync(new Dictionary<string, object>
                {
                    ["stats.likes"] = FieldValue.ArrayUnion(userId)
                });
                logger.LogInformation("[FeedService] User {UserId} liked feed {FeedId}", userId, feedId);
            }

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

            friendIds.AddRange(asSenderTask.Result.Documents
                .Select(d => d.GetValue<string>("addressee_id")));

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

            if (feed.Type != "story")
                throw new AppException(ErrorCode.FEED_VIEW_NOT_ALLOWED);

            if (feed.Settings.ExpiresAt.HasValue &&
                feed.Settings.ExpiresAt.Value < DateTime.UtcNow)
                throw new AppException(ErrorCode.FEED_EXPIRED);

            var hasViewed = feed.Stats.Views.Contains(userId);

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

            if (feed.Type != "story")
                throw new AppException(ErrorCode.FEED_VIEW_NOT_ALLOWED);

            if (feed.UserId != userId)
                throw new AppException(ErrorCode.FORBIDDEN);

            return new ViewersListResponse
            {
                FeedId = feedId,
                ViewCount = feed.Stats.Views.Count,
                HasViewed = feed.Stats.Views.Contains(userId),
                ViewerIds = feed.Stats.Views
            };
        }

        // ── Hide / Unhide Post ──────────────────────────────────────────

        public async Task<HideResponse> ToggleHidePostAsync(string feedId, string userId)
        {
            var snap = await db.Collection("feeds").Document(feedId).GetSnapshotAsync();

            if (!snap.Exists || snap.GetValue<object?>("deleted_at") != null)
                throw new AppException(ErrorCode.FEED_NOT_FOUND);

            var feed = snap.ConvertTo<Feeds>();

            if (feed.Type != "post")
                throw new AppException(ErrorCode.FEED_HIDE_NOT_ALLOWED);

            if (feed.UserId == userId)
                throw new AppException(ErrorCode.FEED_CANNOT_HIDE_OWN);

            var hiddenRef = db.Collection("hidden_posts")
                .WhereEqualTo("viewer_id", userId)
                .WhereEqualTo("post_id", feedId);

            var existingSnap = await hiddenRef.GetSnapshotAsync();
            var isHidden = existingSnap.Count > 0;

            if (isHidden)
            {
                await existingSnap.Documents[0].Reference.DeleteAsync();
                logger.LogInformation("[FeedService] User {UserId} unhid post {FeedId}", userId, feedId);

                return new HideResponse { IsHidden = false };
            }
            else
            {
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

        // ── Comments ───────────────────────────────────────────────────

        public async Task<CommentResponse> CreateCommentAsync(string feedId, string userId, CreateCommentRequest request)
        {
            var feedSnap = await db.Collection("feeds").Document(feedId).GetSnapshotAsync();
            if (!feedSnap.Exists || feedSnap.GetValue<object?>("deleted_at") != null)
                throw new AppException(ErrorCode.FEED_NOT_FOUND);

            var docRef = db.Collection("comments").Document();
            var commentId = docRef.Id;
            var imageUrl = "";

            if (request.File != null)
            {
                var (url, _, _) = await cloudinaryService.UploadAsync(request.File, userId, commentId, "comment");
                imageUrl = url;
            }

            var comment = new Comment
            {
                Id = commentId,
                FeedId = feedId,
                UserId = userId,
                Content = request.Content,
                ImageUrl = imageUrl,
                Likes = new List<string>(),
                CreatedAt = DateTime.UtcNow
            };

            await docRef.SetAsync(comment);

            var authorSnap = await db.Collection("users").Document(userId).GetSnapshotAsync();
            var author = authorSnap.ConvertTo<User>();

            return new CommentResponse
            {
                Id = comment.Id,
                FeedId = comment.FeedId,
                UserId = comment.UserId,
                UserName = $"{author.FirstName} {author.LastName}",
                UserAvatar = author.Avatar,
                Content = comment.Content,
                ImageUrl = comment.ImageUrl,
                LikeCount = 0,
                IsLiked = false,
                CreatedAt = comment.CreatedAt
            };
        }

        public async Task<List<CommentResponse>> GetCommentsAsync(string feedId, string currentUserId)
        {
            var query = db.Collection("comments")
                .WhereEqualTo("feed_id", feedId);

            var snapshot = await query.GetSnapshotAsync();
            var comments = snapshot.Documents
                .Select(d => d.ConvertTo<Comment>())
                .OrderBy(c => c.CreatedAt)
                .ToList();

            if (comments.Count == 0) return new List<CommentResponse>();

            var authorIds = comments.Select(c => c.UserId).Distinct().ToList();
            var authors = await GetUsersByIdsAsync(authorIds);

            return comments
                .Where(c => authors.ContainsKey(c.UserId))
                .Select(c => {
                    var author = authors[c.UserId];
                    return new CommentResponse
                    {
                        Id = c.Id,
                        FeedId = c.FeedId,
                        UserId = c.UserId,
                        UserName = $"{author.FirstName} {author.LastName}",
                        UserAvatar = author.Avatar,
                        Content = c.Content,
                        ImageUrl = c.ImageUrl,
                        LikeCount = c.Likes?.Count ?? 0,
                        IsLiked = c.Likes?.Contains(currentUserId) ?? false,
                        CreatedAt = c.CreatedAt
                    };
                })
                .ToList();
        }

        public async Task<LikeResponse> ToggleLikeCommentAsync(string commentId, string userId)
        {
            var docRef = db.Collection("comments").Document(commentId);
            var snap = await docRef.GetSnapshotAsync();

            if (!snap.Exists)
                throw new AppException(ErrorCode.INTERNAL_ERROR);

            var comment = snap.ConvertTo<Comment>();
            var likesList = comment.Likes ?? new List<string>();
            var isLiked = likesList.Contains(userId);

            if (isLiked)
            {
                await docRef.UpdateAsync(new Dictionary<string, object>
                {
                    ["likes"] = FieldValue.ArrayRemove(userId)
                });
            }
            else
            {
                await docRef.UpdateAsync(new Dictionary<string, object>
                {
                    ["likes"] = FieldValue.ArrayUnion(userId)
                });
            }

            var updatedSnap = await docRef.GetSnapshotAsync();
            var updatedComment = updatedSnap.ConvertTo<Comment>();

            return new LikeResponse
            {
                IsLiked = !isLiked,
                LikeCount = updatedComment.Likes?.Count ?? 0
            };
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
}
