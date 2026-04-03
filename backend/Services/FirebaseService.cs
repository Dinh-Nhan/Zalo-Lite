using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Google.Cloud.Firestore;
using backend.Models;
using System.IO;

namespace backend.Services;

public class FirebaseService
{
    public FirestoreDb FirestoreDb { get; }

    public FirebaseService(IConfiguration configuration)
    {
        var section = configuration.GetSection("Firebase");
        var credentialsFilePath = section.GetValue<string>("CredentialsFilePath");
        var projectId = section.GetValue<string>("ProjectId");

        if (string.IsNullOrWhiteSpace(credentialsFilePath))
        {
            throw new InvalidOperationException("Missing Firebase:CredentialsFilePath in appsettings.json.");
        }

        if (string.IsNullOrWhiteSpace(projectId))
        {
            throw new InvalidOperationException("Missing Firebase:ProjectId in appsettings.json.");
        }

        if (FirebaseApp.DefaultInstance == null)
        {
            FirebaseApp.Create(new AppOptions
            {
                Credential = GoogleCredential.FromFile(credentialsFilePath)
            });
        }

        var resolvedPath = Path.GetFullPath(credentialsFilePath, AppContext.BaseDirectory);
        if (!File.Exists(resolvedPath))
        {
            throw new FileNotFoundException($"Firebase credentials file not found: {resolvedPath}", resolvedPath);
        }

        FirestoreDb = new FirestoreDbBuilder
        {
            ProjectId = projectId,
            CredentialsPath = resolvedPath
        }.Build();
    }

    private CollectionReference UsersCollection => FirestoreDb.Collection("users");

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
            DisplayName = string.IsNullOrWhiteSpace(displayName) ? trimmedId : displayName.Trim(),
            CreatedAt = DateTime.UtcNow
        };

        await UsersCollection.Document(trimmedId).SetAsync(newUser);
        return newUser;
    }

    public static string GetConversationId(string userId1, string userId2)
    {
        if (string.IsNullOrWhiteSpace(userId1) || string.IsNullOrWhiteSpace(userId2))
        {
            throw new ArgumentException("Both user IDs must be provided.");
        }

        var participants = new[] { userId1.Trim(), userId2.Trim() };
        return string.Join("_", participants.OrderBy(x => x, StringComparer.OrdinalIgnoreCase));
    }

    private CollectionReference GetChatCollection(string conversationId)
    {
        if (string.IsNullOrWhiteSpace(conversationId))
        {
            throw new ArgumentException("ConversationId is required.", nameof(conversationId));
        }

        return FirestoreDb.Collection("chats").Document(conversationId).Collection("messages");
    }

    public async Task<string> SendChatMessageAsync(string conversationId, ChatMessage message)
    {
        if (message == null)
        {
            throw new ArgumentNullException(nameof(message));
        }

        message.Timestamp = message.Timestamp == default ? DateTime.UtcNow : message.Timestamp;
        var docRef = await GetChatCollection(conversationId).AddAsync(message);
        return docRef.Id;
    }

    public async Task<IEnumerable<ChatMessage>> GetChatMessagesAsync(string conversationId)
    {
        var snapshot = await GetChatCollection(conversationId)
            .OrderBy("timestamp")
            .GetSnapshotAsync();

        return snapshot.Documents
            .Select(doc =>
            {
                var chatMessage = doc.ConvertTo<ChatMessage>();
                chatMessage.Id = doc.Id;
                return chatMessage;
            })
            .ToList();
    }

    public async Task<IEnumerable<Dictionary<string, object>>> GetCollectionAsync(string collectionName)
    {
        var snapshot = await FirestoreDb.Collection(collectionName).GetSnapshotAsync();
        return snapshot.Documents.Select(doc => doc.ToDictionary()).ToList();
    }
}
