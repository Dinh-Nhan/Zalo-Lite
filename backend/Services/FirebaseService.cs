using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Google.Cloud.Firestore;
using backend.Models;
using System.IO;
using Microsoft.Extensions.Configuration;
using System;

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
            var credential = GoogleCredential.FromFile(credentialsFilePath);
            FirebaseApp.Create(new AppOptions
            {
                Credential = credential
            });
        }

        var resolvedPath = Path.GetFullPath(credentialsFilePath, AppContext.BaseDirectory);
        if (!File.Exists(resolvedPath))
        {
            throw new FileNotFoundException($"Firebase credentials file not found: {resolvedPath}", resolvedPath);
        }

        var firestoreCredential = GoogleCredential.FromFile(resolvedPath);
        FirestoreDb = new FirestoreDbBuilder
        {
            ProjectId = projectId,
            Credential = firestoreCredential
        }.Build();
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
