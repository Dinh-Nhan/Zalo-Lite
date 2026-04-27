using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Google.Cloud.Firestore;

namespace backend.Models
{
    [FirestoreData]
    public class Stats
    {
        [FirestoreProperty("views")]
        public List<string> Views { get; set; } = null!;

        [FirestoreProperty("likes")]
        public List<string> Likes { get; set; } = null!;
    }
}