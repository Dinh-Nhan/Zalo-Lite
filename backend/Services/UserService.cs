using Google.Cloud.Firestore;
using backend.Models;

namespace backend.Services;

public class UserService
{
    private readonly FirebaseService _firebaseService;
    private CollectionReference UsersCollection => _firebaseService.FirestoreDb.Collection("users");

    public UserService(FirebaseService firebaseService)
    {
        _firebaseService = firebaseService;
    }

    public async Task<User?> GetUserAsync(string userId)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            return null;
        }

        var document = await UsersCollection.Document(userId.Trim()).GetSnapshotAsync();
        if (!document.Exists)
        {
            return null;
        }

        var user = document.ConvertTo<User>();
        user.Id = document.Id;
        return user;
    }

    public async Task<IEnumerable<User>> GetUsersAsync()
    {
        var snapshot = await UsersCollection.GetSnapshotAsync();
        return snapshot.Documents
            .Select(doc =>
            {
                var user = doc.ConvertTo<User>();
                user.Id = doc.Id;
                return user;
            })
            .ToList();
    }

    public async Task<User> EnsureUserExistsAsync(string userId, string displayName)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            throw new ArgumentException("User ID is required.", nameof(userId));
        }

        var trimmedId = userId.Trim();
        var user = await GetUserAsync(trimmedId);
        if (user != null)
        {
            return user;
        }

        var newUser = new User
        {
            Id = trimmedId,
            FirstName = string.IsNullOrWhiteSpace(displayName) ? trimmedId : displayName.Trim(),
            CreateAt = DateTime.UtcNow
        };

        await UsersCollection.Document(trimmedId).SetAsync(newUser);
        return newUser;
    }

    public async Task<User> CreateUserAsync(User user)
    {
        if (user == null)
        {
            throw new ArgumentNullException(nameof(user));
        }

        if (string.IsNullOrWhiteSpace(user.Id))
        {
            throw new ArgumentException("User ID is required.", nameof(user.Id));
        }

        user.CreateAt = DateTime.UtcNow;
        user.UpdateAt = DateTime.UtcNow;

        await UsersCollection.Document(user.Id).SetAsync(user);
        return user;
    }

    public async Task<User?> UpdateUserAsync(string userId, User updatedUser)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            throw new ArgumentException("User ID is required.", nameof(userId));
        }

        if (updatedUser == null)
        {
            throw new ArgumentNullException(nameof(updatedUser));
        }

        var existingUser = await GetUserAsync(userId);
        if (existingUser == null)
        {
            return null;
        }

        updatedUser.Id = userId;
        updatedUser.UpdateAt = DateTime.UtcNow;
        updatedUser.CreateAt = existingUser.CreateAt; // Preserve original creation time

        await UsersCollection.Document(userId).SetAsync(updatedUser);
        return updatedUser;
    }

    public async Task<bool> DeleteUserAsync(string userId)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            return false;
        }

        var user = await GetUserAsync(userId);
        if (user == null)
        {
            return false;
        }

        await UsersCollection.Document(userId).DeleteAsync();
        return true;
    }
}
