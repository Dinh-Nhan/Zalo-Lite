using FirebaseAdmin;
using FirebaseAdmin.Auth;
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
            throw new InvalidOperationException("Missing Firebase:CredentialsFilePath in appsettings.json.");

        if (string.IsNullOrWhiteSpace(projectId))
            throw new InvalidOperationException("Missing Firebase:ProjectId in appsettings.json.");

        var resolvedPath = Path.GetFullPath(credentialsFilePath, AppContext.BaseDirectory);
        Console.WriteLine($"[FIREBASE] Resolved path: {resolvedPath}");
        Console.WriteLine($"[FIREBASE] File exists: {File.Exists(resolvedPath)}");
        if (!File.Exists(resolvedPath))
            throw new FileNotFoundException($"Firebase credentials file not found: {resolvedPath}");

#pragma warning disable CS0618 // GoogleCredential.FromFile is deprecated; no replacement that works with FirestoreDbBuilder
        if (FirebaseApp.DefaultInstance == null)
        {
            FirebaseApp.Create(new AppOptions
            {
                Credential = GoogleCredential.FromFile(resolvedPath),
                ProjectId = projectId
            });
        }

        var databaseId = section.GetValue<string>("DatabaseId");
        var builder = new FirestoreDbBuilder
        {
            ProjectId = projectId,
            Credential = GoogleCredential.FromFile(resolvedPath)
        };
#pragma warning restore CS0618

        if (!string.IsNullOrWhiteSpace(databaseId))
            builder.DatabaseId = databaseId;

        FirestoreDb = builder.Build();
    }

    public async Task<UserRecord> CreateOrUpdateAuthUserAsync(string userId, string email)
    {
        if (string.IsNullOrWhiteSpace(userId))
            throw new ArgumentException("User ID is required.", nameof(userId));
        if (string.IsNullOrWhiteSpace(email))
            throw new ArgumentException("Email is required.", nameof(email));

        try
        {
            await FirebaseAuth.DefaultInstance.GetUserAsync(userId);
            var args = new UserRecordArgs
            {
                Uid = userId,
                Email = email.Trim(),
                EmailVerified = false
            };
            return await FirebaseAuth.DefaultInstance.UpdateUserAsync(args);
        }
        catch (FirebaseAuthException ex) when (ex.AuthErrorCode == AuthErrorCode.UserNotFound)
        {
            var args = new UserRecordArgs
            {
                Uid = userId,
                Email = email.Trim(),
                EmailVerified = false
            };
            return await FirebaseAuth.DefaultInstance.CreateUserAsync(args);
        }
    }

    public async Task<UserRecord?> UpdateAuthUserEmailAsync(string userId, string email)
    {
        if (string.IsNullOrWhiteSpace(userId))
            throw new ArgumentException("User ID is required.", nameof(userId));
        if (string.IsNullOrWhiteSpace(email))
            throw new ArgumentException("Email is required.", nameof(email));

        try
        {
            var args = new UserRecordArgs
            {
                Uid = userId,
                Email = email.Trim(),
                EmailVerified = false
            };
            return await FirebaseAuth.DefaultInstance.UpdateUserAsync(args);
        }
        catch (FirebaseAuthException ex) when (ex.AuthErrorCode == AuthErrorCode.UserNotFound)
        {
            return null;
        }
    }
}
