using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Google.Cloud.Firestore;

namespace backend.Services
{
    public class StoryExpirationService(
    IServiceProvider serviceProvider,
    ILogger<StoryExpirationService> logger) : BackgroundService
{
    //  Run every hours
    private readonly TimeSpan _interval = TimeSpan.FromHours(1);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation("[StoryExpiration] Background service started");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await MarkExpiredStoriesAsync();
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "[StoryExpiration] Error while marking expired stories");
            }

            await Task.Delay(_interval, stoppingToken);
        }
    }

    private async Task MarkExpiredStoriesAsync()
    {
        // BackgroundService is singleton so we need create a scope to use FirestoreDb
        using var scope = serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<FirestoreDb>();

        var now = Timestamp.FromDateTime(DateTime.UtcNow);

        logger.LogInformation("[StoryExpiration] Scanning expired stories at {Time}", DateTime.Now);

        // Retrieve stories that haven't been marked as expired but have already passed their expiration date.
        var snap = await db.Collection("feeds")
            .WhereEqualTo("type", "story")
            .WhereEqualTo("settings.is_expired", false)
            .WhereLessThan("settings.expires_at", now)
            .GetSnapshotAsync();

        if (snap.Count == 0)
        {
            logger.LogInformation("[StoryExpiration] No expired stories found");
            return;
        }

        logger.LogInformation("[StoryExpiration] Found {Count} expired stories, updating...", snap.Count);

        // Use batch write to update multiple documents at once (up to 500 documents per batch).

        foreach (var chunk in snap.Documents.Chunk(500))
        {
            var batch = db.StartBatch();

            foreach (var doc in chunk)
            {
                batch.Update(doc.Reference, new Dictionary<string, object>
                {
                    ["settings.is_expired"] = true
                });
            }

            await batch.CommitAsync();
            logger.LogInformation("[StoryExpiration] Updated {Count} stories in batch", chunk.Length);
        }

        logger.LogInformation("[StoryExpiration] Done marking {Total} expired stories", snap.Count);
    }
}
}