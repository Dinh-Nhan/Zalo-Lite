using Google.Cloud.Firestore;
using System.ComponentModel.DataAnnotations;

namespace backend.Models;

[FirestoreData]
public class User
{
    [FirestoreDocumentId]
    public string Id { get; set; } = null!;

    [FirestoreProperty("role")]
    public string Role { get; set; } = "client"; // "client" or "admin"

    [FirestoreProperty("first_name")]
    public string FirstName { get; set; } = string.Empty;

    [FirestoreProperty("last_name")]
    public string LastName { get; set; } = string.Empty;

    [FirestoreProperty("email"), MaxLength(100)]
    public string Email { get; set; } = string.Empty;

    [FirestoreProperty("avatar")]
    public string Avatar { get; set; } = string.Empty;

    [FirestoreProperty("dob", ConverterType = typeof(DateOnlyConverter))]
    public DateOnly DateOfBirth { get; set; }

    [FirestoreProperty("bio")]
    public string Bio { get; set; } = string.Empty;

    [FirestoreProperty("status")]
    public bool Status { get; set; } = true; // true for "active", false for "inactive"

    [FirestoreProperty("created_at")]
    public DateTime CreateAt { get; set; } = DateTime.UtcNow;

    [FirestoreProperty("updated_at")]
    public DateTime UpdateAt { get; set; } = DateTime.UtcNow;
    
    [FirestoreProperty("avatar_public_id")]
    public string? AvatarPublicId {get; set;}

    [FirestoreProperty("fcm_token")]
    public string? FcmToken { get; set; }
}