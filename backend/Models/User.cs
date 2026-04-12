using Google.Cloud.Firestore;
using System.ComponentModel.DataAnnotations;

namespace backend.Models;

[FirestoreData]
public class User
{
    [FirestoreDocumentId]
    public string Id { get; set; } = null!;

    [FirestoreProperty("first_name")] // Tên
    public string FirstName { get; set; } = string.Empty;

    [FirestoreProperty("last_name")] // Họ
    public string LastName { get; set; } = string.Empty;

    [FirestoreProperty("phone"), MaxLength(10)]
    public string Phone { get; set; } = string.Empty;

    [FirestoreProperty("password_hash")]
    public string PasswordHash { get; set; } = string.Empty;

    [FirestoreProperty("avatar")]
    public string Avatar { get; set; } = string.Empty;

    [FirestoreProperty("dob", ConverterType = typeof(DateOnlyConverter))]
    public DateOnly DateOfBirth { get; set; }

    [FirestoreProperty("bio")]
    public string Bio { get; set; } = string.Empty;

    [FirestoreProperty("status")]
    public bool Status { get; set; } = true; // true: active, false: inactive

    [FirestoreProperty("create_at")]
    public DateTime CreateAt { get; set; } = DateTime.UtcNow;

    [FirestoreProperty("upload_at")]
    public DateTime UpdateAt { get; set; } = DateTime.UtcNow;
}


