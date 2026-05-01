using Google.Cloud.Firestore;
using backend.Models;
using backend.Attributes;
using backend.dtos.Response;
using backend.Exceptions;
using backend.Enums;
using Mapster;
using backend.dtos.Request;

namespace backend.Services;

[ScopedService]
public class UserService(FirestoreDb db, ILogger<UserService> logger)
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

    public async Task<UserResponse> CreateAsync(CreateUserRequest request)
    {
        var existing = await db.Collection(Collection)
            .WhereEqualTo("email", request.Email)
            .GetSnapshotAsync();

        if (existing.Count > 0)
            throw new AppException(ErrorCode.EMAIL_ALREADY_EXISTS);

        var user = request.Adapt<User>();
        var docRef = await db.Collection(Collection)
                        .Document(request.Id)
                        .SetAsync(user);
        // user.Id = docRef.Id;

        logger.LogInformation("User created: {UserId}", user.Id);
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

        await docRef.DeleteAsync();
        logger.LogInformation("User deleted: {UserId}", id);
    }
}
