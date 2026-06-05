using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using backend.dtos.Response.Feeds;

namespace backend.dtos.Response
{
    // record auto init a construct full args
    public record FeedResponse
    {
        public string Id { get; init; } = string.Empty;
        public string Type { get; init; } = string.Empty;
        public string Privacy { get; init; } = string.Empty;
        public StatsResponse Stats { get; set; } = null!;

        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
        public SettingResponse Settings { get; init; } = null!;
        public AuthorResponse Author { get; set; } = null!;
        public ContentResponse Content { get; init; } = null!;
        public DateTime CreatedAt { get; init; }
        public DateTime? DeletedAt { get; init; }
    }
}