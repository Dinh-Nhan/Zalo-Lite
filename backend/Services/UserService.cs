using backend.Attributes;
using backend.dtos.Request;
using backend.dtos.Response;
using backend.Enums;
using backend.Exceptions;
using backend.Models;
using Google.Cloud.Firestore;
using Google.Cloud.Firestore.V1;
using Mapster;
using StackExchange.Redis;
using System.Text.Json;

namespace backend.Services;

[ScopedService]
public class UserService(FirestoreDb db, ILogger<UserService> logger, RedisService _redis)
{
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
        user.UpdateAt = DateTime.UtcNow;
        await docRef.SetAsync(user, SetOptions.MergeAll);

        return user.Adapt<UserResponse>();
    }

    public async Task DeleteAsync(string id)
    {
        var docRef = db.Collection(Collection).Document(id);
        var snapshot = await docRef.GetSnapshotAsync();

        if (!snapshot.Exists)
            throw new AppException(ErrorCode.USER_NOT_FOUND);

        await docRef.DeleteAsync();
        logger.LogInformation("User deleted: {UserId}", id);
    }

    public async Task<List<UserRequestDto>> SearchUser(string keyword)
    {
        keyword = keyword.Trim();

        if (keyword.Length < 2)
            return new();

        // Chuyển keyword sang Title Case: "đình nhân" -> "Đình Nhân"
        var titleCase = System.Globalization.CultureInfo
            .CurrentCulture.TextInfo.ToTitleCase(keyword.ToLower());

        // Prefix query: "Đình" -> ("Đình", "Đìn~")
        string cacheKey = $"search:user:{titleCase}";

        var cached = await _redis.GetAsync(cacheKey);

        if (!string.IsNullOrEmpty(cached))
        {
            return JsonSerializer.Deserialize<List<UserRequestDto>>(cached)!;
        }

        // Query song song 3 trường: email, firstName, lastName
        var emailTask = db.Collection("users")
            .WhereGreaterThanOrEqualTo("email", titleCase.ToLower())
            .WhereLessThanOrEqualTo("email", titleCase.ToLower() + "\uf8ff")
            .Limit(10)
            .GetSnapshotAsync();

        var firstNameTask = db.Collection("users")
            .WhereGreaterThanOrEqualTo("first_name", titleCase)
            .WhereLessThanOrEqualTo("first_name", titleCase + "\uf8ff")
            .Limit(10)
            .GetSnapshotAsync();

        var lastNameTask = db.Collection("users")
            .WhereGreaterThanOrEqualTo("last_name", titleCase)
            .WhereLessThanOrEqualTo("last_name", titleCase + "\uf8ff")
            .Limit(10)
            .GetSnapshotAsync();

        await Task.WhenAll(emailTask, firstNameTask, lastNameTask);

        var usersByEmail = emailTask.Result.Documents;
        var usersByFirstName = firstNameTask.Result.Documents;
        var usersByLastName = lastNameTask.Result.Documents;

        // Gộp kết quả, loại trùng theo Id
        var allDocs = usersByEmail
            .Concat(usersByFirstName)
            .Concat(usersByLastName)
            .GroupBy(x => x.Id)
            .Select(g => g.First())
            .Take(20)
            .Select(x => x.ConvertTo<User>())
            .Select(user => new UserRequestDto
            {
                Email = user.Email,
                FullName = $"{user.FirstName} {user.LastName}".Trim(),
                Avatar = user.Avatar,
                Id = user.Id
            })
            .ToList();

        if (allDocs.Any())
        {
            await _redis.SetAsync(
                cacheKey,
                JsonSerializer.Serialize(allDocs),
                TimeSpan.FromSeconds(30));
        }
        else
        {
            await _redis.SetAsync(cacheKey, "[]", TimeSpan.FromSeconds(30));
        }

        return allDocs;
    }
}
