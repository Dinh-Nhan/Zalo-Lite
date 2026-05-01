using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Google.Cloud.Firestore;

namespace backend.Models
{
    [FirestoreData]
    public class Settings
    {
        [FirestoreProperty("is_expired")]
        public bool IsExpired { get; set; }

        [FirestoreProperty("expires_at")]
        public DateTime? ExpiresAt { get; set; }
    }
}