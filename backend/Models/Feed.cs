using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Google.Cloud.Firestore;

namespace backend.Models
{
    [FirestoreData]
    public class Feeds
    {
    [FirestoreDocumentId]
    public string Id { get; set; } = null!;

    [FirestoreProperty("user_id")]
    public string UserId { get; set; } = string.Empty;

    [FirestoreProperty("type")]
    public string Type { get; set; } =string.Empty; // post | story

    [FirestoreProperty("content")]
    public Content Content { get; set; } = null!;

    [FirestoreProperty("privacy")]
    public string Privacy { get; set; } = string.Empty;

    [FirestoreProperty("settings")]
    public Settings Settings { get; set; } = null!;

    [FirestoreProperty("stats")]
    public Stats Stats { get; set; } = null!;

    [FirestoreProperty("create_at")]
    public DateTime CreateAt { get; set; }

    [FirestoreProperty("deleted_at")]
    public DateTime? DeletedAt { get; set; }

    
    }
}