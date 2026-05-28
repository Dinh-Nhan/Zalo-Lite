using backend.Attributes;
using backend.dtos.Request;
using backend.dtos.Response;
using backend.Enums;
using backend.Exceptions;
using backend.Models;
using Google.Cloud.Firestore;
using Google.Cloud.Firestore.V1;
using Mapster;
using backend.dtos;
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
        var docRef = db.Collection(Collection).Document(uid); // ← uid từ token, không từ request body

        var snapshot = await docRef.GetSnapshotAsync();
        if (snapshot.Exists)
            return snapshot.ConvertTo<User>().Adapt<UserResponse>();

        var user = new User
        {
            Id = uid,          // ← uid từ Firebase token
            Email = req.Email,
            FirstName = req.FirstName,
            LastName = req.LastName,
            DateOfBirth = req.DateOfBirth,
            Bio = req.Bio
        };

        await docRef.SetAsync(user);
        logger.LogInformation("User created: {UserId}", uid);
        // if (existing.Count > 0)
        //     throw new AppException(ErrorCode.EMAIL_ALREADY_EXISTS);

        // var user = request.Adapt<User>();
        // var docRef = await db.Collection(Collection)
        //                 .Document(request.Id)
        //                 .SetAsync(user);
        // // user.Id = docRef.Id;

        // logger.LogInformation("User created: {UserId}", user.Id);
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
        // xóa avatar trước
        if (!string.IsNullOrEmpty(user.AvatarPublicId))
            await cloudinaryService.DeleteAvatarAsync(user.AvatarPublicId);

        // xóa folder
        await cloudinaryService.DeleteUserFolderAsync(user.Id);
        await docRef.DeleteAsync();
        logger.LogInformation("User deleted: {UserId}", id);
    }

    public async Task<UserResponse> UpdateAvatarAsync(string userId, UpdateAvatarRequest request)
    {
        var docRef = db.Collection(Collection).Document(userId);
        var snapshot = await docRef.GetSnapshotAsync();

        if (!snapshot.Exists)
            throw new AppException(ErrorCode.USER_NOT_FOUND);

        var user = snapshot.ConvertTo<User>();

        // Xóa avatar cũ trên Cloudinary nếu có
        if (!string.IsNullOrEmpty(user.AvatarPublicId))
            await cloudinaryService.DeleteAvatarAsync(user.AvatarPublicId);

        // Upload avatar mới
        var (url, publicId) = await cloudinaryService.UploadAvatarAsync(request.File, userId);

        // Cập nhật Firestore 
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
        {
            return JsonSerializer.Deserialize<List<UserRequestDto>>(cached.ToString())!;
        }

        var snapshot = await db
            .Collection("users")
            .WhereGreaterThanOrEqualTo("email", keyword)
            .WhereLessThanOrEqualTo("email", keyword + "\uf8ff")
            .Limit(10)
            .GetSnapshotAsync();

        var users = snapshot.Documents
            .Select(x => x.ConvertTo<User>())
            .Where(user => user.Id != currentUserId) // loại bỏ bản thân
            .Select(user => new UserRequestDto
            {
                Email = user.Email,
                FullName = $"{user.FirstName} {user.LastName}".Trim(),
                Avatar = user.Avatar,
                Id = user.Id
            })
            .ToList();

        await _redis.StringSetAsync(
            cacheKey,
            JsonSerializer.Serialize(users),
            TimeSpan.FromSeconds(30));

        return users;
    }
}
