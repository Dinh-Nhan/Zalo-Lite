using Google.Cloud.Firestore;

namespace backend.Services;

/// <summary>
/// Background service that soft-deletes messages whose expires_at has passed.
/// Requires a Firestore composite index on the "messages" collection group:
///   (is_deleted ASC, expires_at ASC)
/// </summary>
public class DisappearingMessageService(
    IServiceProvider serviceProvider,
    ILogger<DisappearingMessageService> logger) : BackgroundService
{
    private readonly TimeSpan _interval = TimeSpan.FromMinutes(5);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation("[DisappearingMessages] Background service started");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await DeleteExpiredMessagesAsync();
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "[DisappearingMessages] Error while deleting expired messages");
            }

            await Task.Delay(_interval, stoppingToken);
        }
    }

    private async Task DeleteExpiredMessagesAsync()
    {
        using var scope = serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<FirestoreDb>();

        var now = Timestamp.FromDateTime(DateTime.UtcNow);

        logger.LogInformation("[DisappearingMessages] Scanning at {Time}", DateTime.UtcNow);

        // Firestore inequality queries exclude documents where the field is absent,
        // so this naturally skips non-disappearing messages.
        var snap = await db.CollectionGroup("messages")
            .WhereEqualTo("is_deleted", false)
            .WhereLessThanOrEqualTo("expires_at", now)
            .GetSnapshotAsync();

        if (snap.Count == 0)
        {
            logger.LogInformation("[DisappearingMessages] No expired messages found");
            return;
        }

        logger.LogInformation("[DisappearingMessages] Deleting {Count} expired messages", snap.Count);

        foreach (var chunk in snap.Documents.Chunk(500))
        {
            var batch = db.StartBatch();
            foreach (var doc in chunk)
            {
                batch.Update(doc.Reference, new Dictionary<string, object>
                {
                    ["is_deleted"] = true,
                    ["deleted_at"] = DateTime.UtcNow,
                    ["content"] = "This message has disappeared",
                    ["media_url"] = FieldValue.Delete,
                    ["thumbnail_url"] = FieldValue.Delete,
                    ["updated_at"] = DateTime.UtcNow
                });
            }
            await batch.CommitAsync();
        }

        logger.LogInformation("[DisappearingMessages] Done deleting {Count} messages", snap.Count);
    }
}
