using backend.Attributes;
using backend.dtos;
using backend.dtos.Request;
using backend.dtos.Response;
using backend.Enums;
using backend.Exceptions;
using backend.Models;
using Google.Cloud.Firestore;
using Mapster;
using StackExchange.Redis;
using System.Text.Json;

namespace backend.Services;

[ScopedService]
public class UserService(FirestoreDb db, ILogger<UserService> logger, CloudinaryService cloudinaryService, IDatabase redis)
{
    private readonly IDatabase _redis = redis;
    private const string Collection = "users";

    public async Task<UserResponse> GetByIdAsync(string id)
    {
        var snapshot = await db.Collection(Collection).Document(id).GetSnapshotAsync();
        if (!snapshot.Exists)
            throw new AppException(ErrorCode.USER_NOT_FOUND);
        return snapshot.ConvertTo<User>().Adapt<UserResponse>();
    }

    public async Task<List<UserResponse>> GetAllAsync()
    {
        var snapshot = await db.Collection(Collection).GetSnapshotAsync();
        return snapshot.Documents
            .Select(doc => doc.ConvertTo<User>().Adapt<UserResponse>())
            .ToList();
    }

    public async Task<UserResponse> CreateAsync(string uid, CreateUserRequest req)
    {
        var docRef = db.Collection(Collection).Document(uid);
        var snapshot = await docRef.GetSnapshotAsync();
        if (snapshot.Exists)
            return snapshot.ConvertTo<User>().Adapt<UserResponse>();

        var user = new User
        {
            Id = uid,
            Email = req.Email,
            FirstName = req.FirstName,
            LastName = req.LastName,
            DateOfBirth = req.DateOfBirth,
            Bio = req.Bio
        };

        await docRef.SetAsync(user);
        logger.LogInformation("User created: {UserId}", uid);
        return user.Adapt<UserResponse>();
    }

    public async Task<UserResponse> UpdateAsync(string id, UpdateUserRequest request)
    {
        var docRef = db.Collection(Collection).Document(id);
        var snapshot = await docRef.GetSnapshotAsync();
        if (!snapshot.Exists)
            throw new AppException(ErrorCode.USER_NOT_FOUND);

        var user = snapshot.ConvertTo<User>();
        request.Adapt(user);
        await docRef.SetAsync(user, SetOptions.MergeAll);
        return user.Adapt<UserResponse>();
    }

    public async Task DeleteAsync(string id)
    {
        var docRef = db.Collection(Collection).Document(id);
        var snapshot = await docRef.GetSnapshotAsync();
        if (!snapshot.Exists)
            throw new AppException(ErrorCode.USER_NOT_FOUND);

        var user = snapshot.ConvertTo<User>();
        if (!string.IsNullOrEmpty(user.AvatarPublicId))
            await cloudinaryService.DeleteAvatarAsync(user.AvatarPublicId);
        await cloudinaryService.DeleteUserFolderAsync(user.Id);
        await docRef.DeleteAsync();
        logger.LogInformation("User deleted: {UserId}", id);
    }

    public async Task SetEnableAsync(string id, bool enable)
    {
        var docRef = db.Collection(Collection).Document(id);
        var snapshot = await docRef.GetSnapshotAsync();
        if (!snapshot.Exists)
            throw new AppException(ErrorCode.USER_NOT_FOUND);

        await docRef.UpdateAsync(new Dictionary<string, object>
        {
            ["is_enable"] = enable,
            ["updated_at"] = Timestamp.FromDateTime(DateTime.UtcNow)
        });
        logger.LogInformation("User {UserId} is_enable set to {Enable}", id, enable);
    }

    public async Task<UserResponse> UpdateAvatarAsync(string userId, UpdateAvatarRequest request)
    {
        var docRef = db.Collection(Collection).Document(userId);
        var snapshot = await docRef.GetSnapshotAsync();
        if (!snapshot.Exists)
            throw new AppException(ErrorCode.USER_NOT_FOUND);

        var user = snapshot.ConvertTo<User>();
        if (!string.IsNullOrEmpty(user.AvatarPublicId))
            await cloudinaryService.DeleteAvatarAsync(user.AvatarPublicId);

        var (url, publicId) = await cloudinaryService.UploadAvatarAsync(request.File, userId);

        await docRef.UpdateAsync(new Dictionary<string, object>
        {
            ["avatar"] = url,
            ["avatar_public_id"] = publicId
        });

        logger.LogInformation("[UserService] Updated avatar for user {UserId}", userId);
        var updated = await docRef.GetSnapshotAsync();
        return updated.ConvertTo<User>().Adapt<UserResponse>();
    }

    public async Task<List<UserRequestDto>> SearchUser(string keyword, string currentUserId)
    {
        keyword = keyword.Trim().ToLower();
        if (keyword.Length < 2)
            return new();

        string cacheKey = $"search:user:{keyword}:{currentUserId}";
        var cached = await _redis.StringGetAsync(cacheKey);

        if (!string.IsNullOrEmpty(cached))
            return JsonSerializer.Deserialize<List<UserRequestDto>>(cached.ToString()) ?? new();

        var snapshot = await db.Collection(Collection).GetSnapshotAsync();
        var users = snapshot.Documents
            .Select(doc => doc.ConvertTo<User>())
            .Where(u => u.Id != currentUserId)
            .Where(u =>
                (!string.IsNullOrWhiteSpace(u.FirstName) && u.FirstName.ToLower().Contains(keyword)) ||
                (!string.IsNullOrWhiteSpace(u.LastName) && u.LastName.ToLower().Contains(keyword)) ||
                (!string.IsNullOrWhiteSpace(u.Email) && u.Email.ToLower().Contains(keyword)))
            .Select(u => new UserRequestDto
            {
                Id = u.Id,
                Email = u.Email,
                FullName = $"{u.FirstName} {u.LastName}".Trim(),
                Avatar = u.Avatar
            })
            .Take(20)
            .ToList();

        await _redis.StringSetAsync(cacheKey, JsonSerializer.Serialize(users), TimeSpan.FromMinutes(5));
        return users;
    }

    public async Task SaveFcmTokenAsync(string userId, string token)
    {
        await db.Collection("users").Document(userId).UpdateAsync("fcm_token", token);
    }

    public async Task<string?> GetFcmTokenAsync(string userId)
    {
        var doc = await db.Collection("users").Document(userId).GetSnapshotAsync();
        if (!doc.Exists) return null;
        var user = doc.ConvertTo<User>();
        return user.FcmToken;
    }
}
