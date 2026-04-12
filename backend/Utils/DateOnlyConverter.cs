using Google.Cloud.Firestore;
using backend.Utils;

namespace backend.Models;

[FirestoreData]
public class DateOnlyConverter : IFirestoreConverter<DateOnly>
{
    public object ToFirestore(DateOnly value)
    {
        // Convert DateOnly to string in dd-MM-yyyy format for Firestore storage
        return value.ToFormattedString();
    }

    public DateOnly FromFirestore(object value)
    {
        if (value == null)
        {
            return DateOnly.MinValue;
        }

        // Handle string format (dd-MM-yyyy or yyyy-MM-dd)
        if (value is string stringValue)
        {
            return DateFormatter.ParseToDateOnly(stringValue);
        }

        // Handle Timestamp format
        if (value is Google.Cloud.Firestore.Timestamp timestamp)
        {
            var dateTime = timestamp.ToDateTime();
            return DateOnly.FromDateTime(dateTime);
        }

        return DateOnly.MinValue;
    }
}
