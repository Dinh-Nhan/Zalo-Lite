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
        {
            throw new InvalidOperationException("Missing Firebase:CredentialsFilePath in appsettings.json.");
        }

        if (string.IsNullOrWhiteSpace(projectId))
        {
            throw new InvalidOperationException("Missing Firebase:ProjectId in appsettings.json.");
        }

        var resolvedPath = Path.GetFullPath(credentialsFilePath, AppContext.BaseDirectory);
        if (!File.Exists(resolvedPath))
        {
            throw new FileNotFoundException($"Firebase credentials file not found: {resolvedPath}", resolvedPath);
        }

        if (FirebaseApp.DefaultInstance == null)
        {
            var credential = GoogleCredential.FromFile(resolvedPath);
            FirebaseApp.Create(new AppOptions
            {
                Credential = credential,
                ProjectId = projectId   // ← bắt buộc để VerifyIdTokenAsync hoạt động
            });
        }

        var firestoreCredential = GoogleCredential.FromFile(resolvedPath);
        FirestoreDb = new FirestoreDbBuilder
        {
            ProjectId = projectId,
            Credential = firestoreCredential
        }.Build();
    }

    /// <summary>
    /// Create or update user in Firebase Authentication with email
    /// </summary>
    public async Task<UserRecord> CreateOrUpdateAuthUserAsync(string userId, string email)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            throw new ArgumentException("User ID is required.", nameof(userId));
        }

        if (string.IsNullOrWhiteSpace(email))
        {
            throw new ArgumentException("Email is required.", nameof(email));
        }

        try
        {
            // Try to get existing user
            var userRecord = await FirebaseAuth.DefaultInstance.GetUserAsync(userId);
            
            // Update existing user
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
            // Create new user if not exists
            var args = new UserRecordArgs
            {
                Uid = userId,
                Email = email.Trim(),
                EmailVerified = false
            };
            
            return await FirebaseAuth.DefaultInstance.CreateUserAsync(args);
        }
    }

    /// <summary>
    /// Update email in Firebase Authentication
    /// </summary>
    public async Task<UserRecord?> UpdateAuthUserEmailAsync(string userId, string email)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            throw new ArgumentException("User ID is required.", nameof(userId));
        }

        if (string.IsNullOrWhiteSpace(email))
        {
            throw new ArgumentException("Email is required.", nameof(email));
        }

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
