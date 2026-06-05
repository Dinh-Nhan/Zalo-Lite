using backend.Attributes;
using backend.dtos.Request;
using backend.dtos.Response;
using backend.Enums;
using backend.Exceptions;
using backend.Hubs;
using backend.Models;
using Google.Cloud.Firestore;
using Mapster;
using Microsoft.AspNetCore.SignalR;

namespace backend.Services;

/// <summary>
/// Quản lý toàn bộ nghiệp vụ kết bạn.
///
/// Cấu trúc collection Firestore:
///   friendships/{docId}  — mỗi document là một cạnh quan hệ giữa 2 user,
///   với sender_id, addressee_id, status.
///
/// Quy tắc canonical: để tìm quan hệ giữa A và B, query:
///   (sender_id == A AND addressee_id == B)
///   OR
///   (sender_id == B AND addressee_id == A)
/// </summary>
[ScopedService]
public class FriendshipService(
    FirestoreDb db,
    ILogger<FriendshipService> logger,
    IHubContext<FriendHub> hubContext)
{
    private const string Col = "friendships";
    private const string UsersCol = "users";

    // ─────────────────────────────────────────────────────────────
    // PUBLIC API
    // ─────────────────────────────────────────────────────────────

    /// <summary>
    /// Gửi lời mời kết bạn.
    ///
    /// Kiểm duyệt (theo thứ tự):
    ///  1. Không tự gửi cho bản thân
    ///  2. Người nhận phải tồn tại
    ///  3. Chưa là bạn bè (status == accepted)
    ///  4. Chưa có lời mời đang chờ (status == pending) theo chiều nào
    ///  5. Người nhận chưa block người gửi
    ///  6. Người gửi chưa block người nhận
    ///  7. Nếu người nhận đã bị từ chối trước đó → tạo lại lời mời mới
    /// </summary>
    public async Task<FriendshipResponse> SendRequestAsync(string senderId, SendFriendRequestDto dto)
    {
        var addresseeId = dto.AddresseeId.Trim();

        // 1. Không tự gửi cho bản thân
        if (senderId == addresseeId)
            throw new AppException(ErrorCode.CANNOT_SELF_FRIEND);

        // 2. Người nhận phải tồn tại & active
        await EnsureUserExistsAsync(addresseeId);

        // 3-6. Kiểm tra quan hệ hiện tại
        var existing = await GetRelationshipAsync(senderId, addresseeId);

        if (existing is not null)
        {
            switch (existing.Status)
            {
                case "accepted":
                    throw new AppException(ErrorCode.ALREADY_FRIENDS);

                case "pending":
                    // Có lời mời đang chờ — phân biệt chiều gửi
                    if (existing.SenderId == senderId)
                        throw new AppException(ErrorCode.FRIEND_REQUEST_ALREADY_SENT);
                    // Người kia đã gửi cho mình → tự động chấp nhận (UX Zalo)
                    return await AcceptExistingAsync(existing.Id, senderId);

                case "blocked":
                    // Ai block ai?
                    if (existing.SenderId == senderId)
                        throw new AppException(ErrorCode.YOU_BLOCKED_USER);
                    else
                        throw new AppException(ErrorCode.BLOCKED_BY_USER);

                case "declined":
                    // Cho phép gửi lại — xoá record cũ rồi tạo mới
                    await db.Collection(Col).Document(existing.Id).DeleteAsync();
                    break;
            }
        }

        // Tạo lời mời mới
        var senderSnap = await db.Collection(UsersCol).Document(senderId).GetSnapshotAsync();
        var addresseeSnap = await db.Collection(UsersCol).Document(addresseeId).GetSnapshotAsync();

        string senderName = "";
        string senderAvatar = "";
        string addresseeName = "";

        if (senderSnap.Exists)
        {
            var su = senderSnap.ConvertTo<User>();
            senderName   = $"{su.FirstName} {su.LastName}".Trim();
            senderAvatar = su.Avatar;
        }

        if (addresseeSnap.Exists)
        {
            var au = addresseeSnap.ConvertTo<User>();
            addresseeName = $"{au.FirstName} {au.LastName}".Trim();
        }

        var friendship = new Friendship
        {
            SenderId    = senderId,
            AddresseeId = addresseeId,
            Status      = "pending",
            SourceType  = dto.SourceType,
            CreatedAt   = DateTime.UtcNow,
            UpdatedAt   = DateTime.UtcNow,
            AddresseeName = addresseeName
        };

        var docRef = await db.Collection(Col).AddAsync(friendship);
        friendship.Id = docRef.Id;

        logger.LogInformation("Friend request sent: {SenderId} → {AddresseeId} [{Id}]",
            senderId, addresseeId, friendship.Id);

        // ── SignalR: notify người nhận có lời mời mới ─────────────
        var enriched = new FriendshipResponse
        {
            Id          = friendship.Id,
            SenderId    = friendship.SenderId,
            AddresseeId = friendship.AddresseeId,
            Status      = friendship.Status,
            SourceType  = friendship.SourceType,
            CreatedAt   = friendship.CreatedAt,
            UpdatedAt   = friendship.UpdatedAt,
            SenderName   = senderName,
            SenderAvatar = senderAvatar,
            AddresseeName = addresseeName
        };

        await hubContext.Clients
            .Group(FriendHub.GroupName(addresseeId))
            .SendAsync("FriendRequestReceived", enriched);

        return enriched;
    }

    /// <summary>
    /// Chấp nhận hoặc từ chối lời mời kết bạn.
    ///
    /// Kiểm duyệt:
    ///  1. Document phải tồn tại
    ///  2. Người gọi phải là addressee (người nhận)
    ///  3. Status phải là "pending"
    /// </summary>
    public async Task<FriendshipResponse> RespondAsync(
        string currentUserId, string friendshipId, RespondFriendRequestDto dto)
    {
        var (docRef, friendship) = await GetFriendshipDocAsync(friendshipId);

        // 2. Chỉ addressee mới được phản hồi
        if (friendship.AddresseeId != currentUserId)
            throw new AppException(ErrorCode.NOT_REQUEST_RECIPIENT);

        // 3. Phải ở trạng thái pending
        if (friendship.Status != "pending")
            throw new AppException(ErrorCode.REQUEST_NOT_PENDING);

        friendship.Status    = dto.Accept ? "accepted" : "declined";
        friendship.UpdatedAt = DateTime.UtcNow;

        await docRef.SetAsync(friendship, SetOptions.MergeAll);

        logger.LogInformation("Friend request {Id} {Action} by {UserId}",
            friendshipId, friendship.Status, currentUserId);

        var response = friendship.Adapt<FriendshipResponse>();

        // ── SignalR: notify người gửi lời mời về kết quả ─────────
        if (dto.Accept)
        {
            await hubContext.Clients
                .Group(FriendHub.GroupName(friendship.SenderId))
                .SendAsync("FriendRequestAccepted", response);
        }
        else
        {
            await hubContext.Clients
                .Group(FriendHub.GroupName(friendship.SenderId))
                .SendAsync("FriendRequestDeclined", response);
        }

        return response;
    }

    /// <summary>
    /// Huỷ lời mời kết bạn đã gửi (chỉ sender mới được huỷ).
    ///
    /// Kiểm duyệt:
    ///  1. Document phải tồn tại
    ///  2. Người gọi phải là sender
    ///  3. Status phải là "pending"
    /// </summary>
    public async Task CancelRequestAsync(string currentUserId, string friendshipId)
    {
        var (docRef, friendship) = await GetFriendshipDocAsync(friendshipId);

        if (friendship.SenderId != currentUserId)
            throw new AppException(ErrorCode.NOT_REQUEST_SENDER);

        if (friendship.Status != "pending")
            throw new AppException(ErrorCode.REQUEST_NOT_PENDING);

        await docRef.DeleteAsync();

        logger.LogInformation("Friend request {Id} cancelled by {UserId}",
            friendshipId, currentUserId);
    }

    /// <summary>
    /// Huỷ kết bạn (unfriend) — xoá document có status == "accepted".
    ///
    /// Kiểm duyệt:
    ///  1. Document phải tồn tại
    ///  2. Status phải là "accepted"
    ///  3. Người gọi phải là một trong hai bên
    /// </summary>
    public async Task UnfriendAsync(string currentUserId, string targetUserId)
    {
        var existing = await GetRelationshipAsync(currentUserId, targetUserId);

        if (existing is null || existing.Status != "accepted")
            throw new AppException(ErrorCode.ALREADY_FRIENDS); // reuse: not friends

        if (existing.SenderId != currentUserId && existing.AddresseeId != currentUserId)
            throw new AppException(ErrorCode.FORBIDDEN);

        await db.Collection(Col).Document(existing.Id).DeleteAsync();

        logger.LogInformation("Unfriend: {A} ↔ {B}", currentUserId, targetUserId);
    }

    /// <summary>
    /// Block người dùng.
    ///
    /// Kiểm duyệt:
    ///  1. Không tự block bản thân
    ///  2. Người bị block phải tồn tại
    ///  3. Chưa block người này
    ///  Nếu đang là bạn / đang có lời mời pending → đổi sang "blocked"
    ///  Không có quan hệ → tạo mới với status "blocked"
    /// </summary>
    public async Task<FriendshipResponse> BlockAsync(string blockerId, string blockedId)
    {
        if (blockerId == blockedId)
            throw new AppException(ErrorCode.CANNOT_SELF_BLOCK);

        await EnsureUserExistsAsync(blockedId);

        var existing = await GetRelationshipAsync(blockerId, blockedId);

        if (existing is not null)
        {
            if (existing.Status == "blocked" && existing.SenderId == blockerId)
                throw new AppException(ErrorCode.ALREADY_BLOCKED);

            // Ghi đè thành blocked, đặt sender = blocker
            var blockedDoc = db.Collection(Col).Document(existing.Id);

            // Enrich AddresseeName
            var addresseeSnap = await db.Collection(UsersCol).Document(blockedId).GetSnapshotAsync();
            string addresseeName = "";
            if (addresseeSnap.Exists)
            {
                var u = addresseeSnap.ConvertTo<User>();
                addresseeName = $"{u.FirstName} {u.LastName}".Trim();
            }

            var updated = new Friendship
            {
                Id          = existing.Id,
                SenderId    = blockerId,
                AddresseeId = blockedId,
                Status      = "blocked",
                SourceType  = existing.SourceType,
                CreatedAt   = existing.CreatedAt,
                UpdatedAt   = DateTime.UtcNow,
                AddresseeName = addresseeName
            };
            await blockedDoc.SetAsync(updated);

            logger.LogInformation("User {BlockerId} blocked {BlockedId} (existing doc updated)", blockerId, blockedId);
            return updated.Adapt<FriendshipResponse>();
        }

        // Enrich AddresseeName trước khi lưu
        var snap = await db.Collection(UsersCol).Document(blockedId).GetSnapshotAsync();
        string name = "";
        if (snap.Exists)
        {
            var u = snap.ConvertTo<User>();
            name = $"{u.FirstName} {u.LastName}".Trim();
        }

        // Tạo mới
        var friendship = new Friendship
        {
            SenderId    = blockerId,
            AddresseeId = blockedId,
            Status      = "blocked",
            SourceType  = "search",
            CreatedAt   = DateTime.UtcNow,
            UpdatedAt   = DateTime.UtcNow,
            AddresseeName = name
        };

        var docRef = await db.Collection(Col).AddAsync(friendship);
        friendship.Id = docRef.Id;

        logger.LogInformation("User {BlockerId} blocked {BlockedId} (new doc)", blockerId, blockedId);
        return friendship.Adapt<FriendshipResponse>();
    }

    /// <summary>
    /// Bỏ block người dùng.
    ///
    /// Kiểm duyệt:
    ///  1. Document phải tồn tại, status == "blocked"
    ///  2. Người gọi phải là blocker (sender)
    /// </summary>
    public async Task UnblockAsync(string blockerId, string blockedId)
    {
        var existing = await GetRelationshipAsync(blockerId, blockedId);

        if (existing is null || existing.Status != "blocked")
            throw new AppException(ErrorCode.FRIEND_REQUEST_NOT_FOUND);

        if (existing.SenderId != blockerId)
            throw new AppException(ErrorCode.FORBIDDEN);

        await db.Collection(Col).Document(existing.Id).DeleteAsync();

        logger.LogInformation("User {BlockerId} unblocked {BlockedId}", blockerId, blockedId);
    }

    /// <summary>Lấy danh sách bạn bè (status == accepted) của user</summary>
    public async Task<List<FriendSummaryResponse>> GetFriendsAsync(string userId)
    {
        var (senderDocs, addresseeDocs) = await FetchBothSidesAsync(userId, "accepted");
        var friendIds = new List<(string FriendId, string FriendshipId, DateTime Since)>();

        foreach (var d in senderDocs.Documents)
        {
            var f = d.ConvertTo<Friendship>();
            friendIds.Add((f.AddresseeId, f.Id, f.UpdatedAt));
        }
        foreach (var d in addresseeDocs.Documents)
        {
            var f = d.ConvertTo<Friendship>();
            friendIds.Add((f.SenderId, f.Id, f.UpdatedAt));
        }

        return await EnrichWithUserDataAsync(friendIds);
    }

    /// <summary>Lấy danh sách lời mời kết bạn đang chờ MÀ người dùng NHẬN được (kèm SenderName/Avatar)</summary>
    public async Task<List<FriendshipResponse>> GetPendingReceivedAsync(string userId)
    {
        userId = userId.Trim();
        logger.LogInformation("GetPendingReceivedAsync: userId={UserId}", userId);

        var snapshot = await db.Collection(Col)
            .WhereEqualTo("addressee_id", userId)
            .WhereEqualTo("status", "pending")
            .GetSnapshotAsync();

        logger.LogInformation("GetPendingReceivedAsync: found {Count} pending requests", snapshot.Documents.Count);

        var friendships = snapshot.Documents
            .Select(d => d.ConvertTo<Friendship>())
            .ToList();

        if (friendships.Count == 0) return [];

        // Enrich với thông tin sender và addressee song song
        var userTasks = friendships.Select(f => new
        {
            SenderTask = db.Collection(UsersCol).Document(f.SenderId).GetSnapshotAsync(),
            AddresseeTask = db.Collection(UsersCol).Document(f.AddresseeId).GetSnapshotAsync()
        }).ToList();

        await Task.WhenAll(userTasks.SelectMany(x => new[] { x.SenderTask, x.AddresseeTask }));
        var result = new List<FriendshipResponse>();

        for (int i = 0; i < friendships.Count; i++)
        {
            var f = friendships[i];
            var senderSnap = userTasks[i].SenderTask.Result;
            var addresseeSnap = userTasks[i].AddresseeTask.Result;

            string senderName = f.SenderId;
            string senderAvatar = "";
            string addresseeName = "";

            if (senderSnap.Exists)
            {
                var u = senderSnap.ConvertTo<User>();
                senderName = $"{u.FirstName} {u.LastName}".Trim();
                senderAvatar = u.Avatar;
            }

            if (addresseeSnap.Exists)
            {
                var u = addresseeSnap.ConvertTo<User>();
                addresseeName = $"{u.FirstName} {u.LastName}".Trim();
            }

            result.Add(new FriendshipResponse
            {
                Id           = f.Id,
                SenderId     = f.SenderId,
                AddresseeId  = f.AddresseeId,
                Status       = f.Status,
                SourceType   = f.SourceType,
                CreatedAt    = f.CreatedAt,
                UpdatedAt    = f.UpdatedAt,
                SenderName   = senderName,
                SenderAvatar = senderAvatar,
                AddresseeName = addresseeName
            });
        }

        return result;
    }

    /// <summary>Lấy danh sách lời mời kết bạn đang chờ MÀ người dùng ĐÃ GỬI</summary>
    public async Task<List<FriendshipResponse>> GetPendingSentAsync(string userId)
    {
        var snapshot = await db.Collection(Col)
            .WhereEqualTo("sender_id", userId)
            .WhereEqualTo("status", "pending")
            .GetSnapshotAsync();

        var friendships = snapshot.Documents
            .Select(d => d.ConvertTo<Friendship>())
            .ToList();

        if (friendships.Count == 0) return [];

        // Enrich với thông tin addressee
        var addresseeTasks = friendships
            .Select(f => db.Collection(UsersCol).Document(f.AddresseeId).GetSnapshotAsync())
            .ToList();

        var addresseeSnaps = await Task.WhenAll(addresseeTasks);
        var result = new List<FriendshipResponse>();

        for (int i = 0; i < friendships.Count; i++)
        {
            var f = friendships[i];
            var snap = addresseeSnaps[i];
            string addresseeName = "";

            if (snap.Exists)
            {
                var u = snap.ConvertTo<User>();
                addresseeName = $"{u.FirstName} {u.LastName}".Trim();
            }

            result.Add(new FriendshipResponse
            {
                Id           = f.Id,
                SenderId     = f.SenderId,
                AddresseeId  = f.AddresseeId,
                Status       = f.Status,
                SourceType   = f.SourceType,
                CreatedAt    = f.CreatedAt,
                UpdatedAt    = f.UpdatedAt,
                AddresseeName = addresseeName
            });
        }

        return result;
    }

    /// <summary>Lấy danh sách người đã bị block</summary>
    public async Task<List<FriendshipResponse>> GetBlockedUsersAsync(string userId)
    {
        var snapshot = await db.Collection(Col)
            .WhereEqualTo("sender_id", userId)
            .WhereEqualTo("status", "blocked")
            .GetSnapshotAsync();

        var friendships = snapshot.Documents
            .Select(d => d.ConvertTo<Friendship>())
            .ToList();

        if (friendships.Count == 0) return [];

        // Enrich với thông tin addressee
        var addresseeTasks = friendships
            .Select(f => db.Collection(UsersCol).Document(f.AddresseeId).GetSnapshotAsync())
            .ToList();

        var addresseeSnaps = await Task.WhenAll(addresseeTasks);
        var result = new List<FriendshipResponse>();

        for (int i = 0; i < friendships.Count; i++)
        {
            var f = friendships[i];
            var snap = addresseeSnaps[i];
            string addresseeName = "";

            if (snap.Exists)
            {
                var u = snap.ConvertTo<User>();
                addresseeName = $"{u.FirstName} {u.LastName}".Trim();
            }

            result.Add(new FriendshipResponse
            {
                Id           = f.Id,
                SenderId     = f.SenderId,
                AddresseeId  = f.AddresseeId,
                Status       = f.Status,
                SourceType   = f.SourceType,
                CreatedAt    = f.CreatedAt,
                UpdatedAt    = f.UpdatedAt,
                AddresseeName = addresseeName
            });
        }

        return result;
    }

    /// <summary>Lấy trạng thái quan hệ với một user cụ thể</summary>
    public async Task<FriendshipResponse?> GetRelationshipStatusAsync(string currentUserId, string targetUserId)
    {
        var rel = await GetRelationshipAsync(currentUserId, targetUserId);
        if (rel is null) return null;

        // Enrich AddresseeName
        var addresseeSnap = await db.Collection(UsersCol).Document(rel.AddresseeId).GetSnapshotAsync();
        string addresseeName = "";
        if (addresseeSnap.Exists)
        {
            var u = addresseeSnap.ConvertTo<User>();
            addresseeName = $"{u.FirstName} {u.LastName}".Trim();
        }

        return new FriendshipResponse
        {
            Id = rel.Id,
            SenderId = rel.SenderId,
            AddresseeId = rel.AddresseeId,
            Status = rel.Status,
            SourceType = rel.SourceType,
            CreatedAt = rel.CreatedAt,
            UpdatedAt = rel.UpdatedAt,
            AddresseeName = addresseeName
        };
    }

    // ─────────────────────────────────────────────────────────────
    // PRIVATE HELPERS
    // ─────────────────────────────────────────────────────────────

    /// <summary>
    /// Tìm document quan hệ giữa A và B (không phân biệt chiều gửi).
    /// Firestore không hỗ trợ OR natively nên chạy 2 query song song.
    /// </summary>
    private async Task<Friendship?> GetRelationshipAsync(string a, string b)
    {
        var t1 = db.Collection(Col)
            .WhereEqualTo("sender_id", a)
            .WhereEqualTo("addressee_id", b)
            .Limit(1)
            .GetSnapshotAsync();

        var t2 = db.Collection(Col)
            .WhereEqualTo("sender_id", b)
            .WhereEqualTo("addressee_id", a)
            .Limit(1)
            .GetSnapshotAsync();

        await Task.WhenAll(t1, t2);

        var doc = t1.Result.Documents.FirstOrDefault()
               ?? t2.Result.Documents.FirstOrDefault();

        return doc?.ConvertTo<Friendship>();
    }

    /// <summary>Lấy document + docRef hoặc ném FRIEND_REQUEST_NOT_FOUND</summary>
    private async Task<(DocumentReference DocRef, Friendship Friendship)> GetFriendshipDocAsync(string id)
    {
        var docRef   = db.Collection(Col).Document(id);
        var snapshot = await docRef.GetSnapshotAsync();

        if (!snapshot.Exists)
            throw new AppException(ErrorCode.FRIEND_REQUEST_NOT_FOUND);

        return (docRef, snapshot.ConvertTo<Friendship>());
    }

    /// <summary>Chắc chắn user tồn tại và đang active</summary>
    private async Task EnsureUserExistsAsync(string uid)
    {
        var snapshot = await db.Collection(UsersCol).Document(uid).GetSnapshotAsync();
        if (!snapshot.Exists)
            throw new AppException(ErrorCode.USER_NOT_FOUND);

        var user = snapshot.ConvertTo<User>();
        if (!user.Status)
            throw new AppException(ErrorCode.USER_DISABLED);
    }

    /// <summary>
    /// Khi người nhận gửi lại lời mời cho người đã gửi cho họ
    /// → tự động accept thay vì tạo 2 lời mời pending song song
    /// </summary>
    private async Task<FriendshipResponse> AcceptExistingAsync(string friendshipId, string acceptorId)
    {
        var dto = new RespondFriendRequestDto { Accept = true };
        return await RespondAsync(acceptorId, friendshipId, dto);
    }

    /// <summary>
    /// Fetch documents ở cả hai phía (sender / addressee) cùng status.
    /// Firestore chưa hỗ trợ OR compound queries → 2 query song song.
    /// </summary>
    private async Task<(QuerySnapshot Sender, QuerySnapshot Addressee)> FetchBothSidesAsync(
        string userId, string status)
    {
        var t1 = db.Collection(Col)
            .WhereEqualTo("sender_id", userId)
            .WhereEqualTo("status", status)
            .GetSnapshotAsync();

        var t2 = db.Collection(Col)
            .WhereEqualTo("addressee_id", userId)
            .WhereEqualTo("status", status)
            .GetSnapshotAsync();

        await Task.WhenAll(t1, t2);
        return (t1.Result, t2.Result);
    }

    /// <summary>Bổ sung thông tin User (tên, avatar) vào danh sách bạn bè</summary>
    private async Task<List<FriendSummaryResponse>> EnrichWithUserDataAsync(
        List<(string FriendId, string FriendshipId, DateTime Since)> entries)
    {
        if (entries.Count == 0) return [];

        var tasks = entries.Select(e =>
            db.Collection(UsersCol).Document(e.FriendId).GetSnapshotAsync());

        var snapshots = await Task.WhenAll(tasks);
        var result    = new List<FriendSummaryResponse>();

        for (int i = 0; i < entries.Count; i++)
        {
            var snap = snapshots[i];
            if (!snap.Exists) continue; // user bị xoá → bỏ qua

            var user = snap.ConvertTo<User>();
            result.Add(new FriendSummaryResponse
            {
                FriendshipId = entries[i].FriendshipId,
                FriendId     = user.Id,
                FirstName    = user.FirstName,
                LastName     = user.LastName,
                Avatar       = user.Avatar,
                FriendsSince = entries[i].Since
            });
        }

        return result;
    }
}
