using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Google.Cloud.Firestore;

namespace backend.Models
{
    [FirestoreData]
    public class Content
    {
        [FirestoreProperty("caption")]
        public string Caption { get; set; } = null!;

        [FirestoreProperty("media")]
        public List<Media> Media { get; set; } = null!;
    }
}