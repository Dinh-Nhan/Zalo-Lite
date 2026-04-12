using System.Globalization;

namespace backend.Utils;

public static class DateFormatter
{
    // Format: dd-MM-yyyy
    public const string DateFormat = "dd-MM-yyyy";
    
    // Format: dd-MM-yyyy HH:mm:ss
    public const string DateTimeFormat = "dd-MM-yyyy HH:mm:ss";

    /// <summary>
    /// Convert DateOnly to string format dd-MM-yyyy
    /// </summary>
    public static string ToFormattedString(this DateOnly date)
    {
        return date.ToString(DateFormat, CultureInfo.InvariantCulture);
    }

    /// <summary>
    /// Convert DateTime to string format dd-MM-yyyy HH:mm:ss
    /// </summary>
    public static string ToFormattedString(this DateTime dateTime)
    {
        return dateTime.ToString(DateTimeFormat, CultureInfo.InvariantCulture);
    }

    /// <summary>
    /// Convert DateTime to string format dd-MM-yyyy
    /// </summary>
    public static string ToFormattedDateString(this DateTime dateTime)
    {
        return dateTime.ToString(DateFormat, CultureInfo.InvariantCulture);
    }

    /// <summary>
    /// Parse string dd-MM-yyyy to DateOnly
    /// </summary>
    public static DateOnly ParseToDateOnly(string dateString)
    {
        if (string.IsNullOrWhiteSpace(dateString))
        {
            return DateOnly.MinValue;
        }

        // Try parse with dd-MM-yyyy format
        if (DateOnly.TryParseExact(dateString, DateFormat, CultureInfo.InvariantCulture, DateTimeStyles.None, out var result))
        {
            return result;
        }

        // Try parse with ISO format yyyy-MM-dd
        if (DateOnly.TryParse(dateString, out var isoResult))
        {
            return isoResult;
        }

        return DateOnly.MinValue;
    }

    /// <summary>
    /// Parse string dd-MM-yyyy HH:mm:ss to DateTime
    /// </summary>
    public static DateTime ParseToDateTime(string dateTimeString)
    {
        if (string.IsNullOrWhiteSpace(dateTimeString))
        {
            return DateTime.MinValue;
        }

        // Try parse with dd-MM-yyyy HH:mm:ss format
        if (DateTime.TryParseExact(dateTimeString, DateTimeFormat, CultureInfo.InvariantCulture, DateTimeStyles.None, out var result))
        {
            return result;
        }

        // Try parse with ISO format
        if (DateTime.TryParse(dateTimeString, out var isoResult))
        {
            return isoResult;
        }

        return DateTime.MinValue;
    }

    /// <summary>
    /// Convert string to Firestore compatible format (ISO: yyyy-MM-dd)
    /// </summary>
    public static string ToFirestoreFormat(string dateString)
    {
        var dateOnly = ParseToDateOnly(dateString);
        if (dateOnly == DateOnly.MinValue)
        {
            return string.Empty;
        }
        return dateOnly.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
    }

    /// <summary>
    /// Convert Firestore format (yyyy-MM-dd) to display format (dd-MM-yyyy)
    /// </summary>
    public static string FromFirestoreFormat(string firestoreDateString)
    {
        if (string.IsNullOrWhiteSpace(firestoreDateString))
        {
            return string.Empty;
        }

        if (DateOnly.TryParse(firestoreDateString, out var dateOnly))
        {
            return dateOnly.ToFormattedString();
        }

        return string.Empty;
    }
}
