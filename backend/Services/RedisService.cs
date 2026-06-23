using StackExchange.Redis;
using backend.Attributes;

namespace backend.Services
{
    [ScopedService]
    public class RedisService
    {
        private const string OnlineKeyPrefix = "online:";
        private const string LastSeenKeyPrefix = "last_seen:";
        private static readonly TimeSpan OnlineTtl = TimeSpan.FromMinutes(5);

        private readonly IConnectionMultiplexer _redis;

        public RedisService(IConnectionMultiplexer redis)
        {
            _redis = redis;
        }

        private IDatabase? Db => _redis.IsConnected ? _redis.GetDatabase() : null;

        // ── Generic ────────────────────────────────────────────

        public async Task<string?> GetAsync(string key)
        {
            var db = Db; if (db == null) return null;
            return await db.StringGetAsync(key);
        }

        public async Task SetAsync(string key, string value, TimeSpan expiry)
        {
            var db = Db; if (db == null) return;
            await db.StringSetAsync(key, value, expiry);
        }

        public async Task DeleteAsync(string key)
        {
            var db = Db; if (db == null) return;
            await db.KeyDeleteAsync(key);
        }

        public async Task<bool> KeyExistsAsync(string key)
        {
            var db = Db; if (db == null) return false;
            return await db.KeyExistsAsync(key);
        }

        // ── Online status ───────────────────────────────────────

        public async Task SetOnlineAsync(string userId)
        {
            var db = Db; if (db == null) return;
            await db.StringSetAsync($"{OnlineKeyPrefix}{userId}", "1", OnlineTtl);
        }

        public async Task RefreshOnlineTtlAsync(string userId)
        {
            var db = Db; if (db == null) return;
            await db.KeyExpireAsync($"{OnlineKeyPrefix}{userId}", OnlineTtl);
        }

        public async Task SetOfflineAsync(string userId)
        {
            var db = Db; if (db == null) return;
            await db.StringSetAsync($"{LastSeenKeyPrefix}{userId}", DateTime.UtcNow.ToString("O"));
            await db.KeyDeleteAsync($"{OnlineKeyPrefix}{userId}");
        }

        public async Task<bool> IsOnlineAsync(string userId)
        {
            var db = Db; if (db == null) return false;
            return await db.KeyExistsAsync($"{OnlineKeyPrefix}{userId}");
        }

        public async Task<DateTime?> GetLastSeenAsync(string userId)
        {
            var db = Db; if (db == null) return null;
            var raw = await db.StringGetAsync($"{LastSeenKeyPrefix}{userId}");
            if (raw.IsNullOrEmpty) return null;
            return DateTime.Parse(raw!, null, System.Globalization.DateTimeStyles.RoundtripKind);
        }
    }
}
