using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Google.Cloud.Firestore;

namespace backend.Services
{
    public class FeedService
    {
        public FirestoreDb firestoreDb {get;}

        public FeedService(FirestoreDb firestoreDb)
        {
            this.firestoreDb = firestoreDb;
        }

        
    }
}