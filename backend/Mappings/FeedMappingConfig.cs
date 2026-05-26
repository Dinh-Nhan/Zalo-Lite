using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.dtos.Request;
using backend.dtos.Response;
using backend.Models;
using Mapster;

namespace backend.Mappings
{
    public class FeedMappingConfig : IRegister
    {
        public void Register(TypeAdapterConfig config)
    {
        // Feed → FeedResponse
        config.NewConfig<Feeds, FeedResponse>()
            .Map(dest => dest.CreatedAt, src => src.CreatedAt)
            .Map(dest => dest.Settings, src => new SettingResponse
            {
                IsExpired = src.Settings.IsExpired,
                ExpiresAt = src.Settings.ExpiresAt.HasValue
                    ? src.Settings.ExpiresAt.Value
                    : null
            })
            .Map(dest => dest.Stats, src => new StatsResponse
            {
                ViewCount = src.Stats.Views.Count,
                LikeCount = src.Stats.Likes.Count,
                IsLiked = false 
            });

        config.NewConfig<Content, ContentResponse>();
        config.NewConfig<Media, MediaResponse>();
    }
    }
}