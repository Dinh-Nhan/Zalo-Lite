using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Google.Cloud.Firestore;

namespace backend.Models
{
    [FirestoreData]
    public class Media
    {
        [FirestoreProperty("url")]
        public string Url { get; set; } = null!;

        [FirestoreProperty("type")]
        public string Type { get; set; } = null!; // image | video
    }
}