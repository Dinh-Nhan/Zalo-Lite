using System;
using System.Collections.Generic;
using Google.Cloud.Firestore;

namespace backend.Models
{
    [FirestoreData]
    public class Comment
    {
        [FirestoreDocumentId]
        public string Id { get; set; } = null!;

        [FirestoreProperty("feed_id")]
        public string FeedId { get; set; } = string.Empty;

        [FirestoreProperty("user_id")]
        public string UserId { get; set; } = string.Empty;

        [FirestoreProperty("content")]
        public string Content { get; set; } = string.Empty;

        [FirestoreProperty("image_url")]
        public string ImageUrl { get; set; } = string.Empty;

        [FirestoreProperty("likes")]
        public List<string> Likes { get; set; } = new List<string>();

        [FirestoreProperty("created_at")]
        public DateTime CreatedAt { get; set; }
    }
}
