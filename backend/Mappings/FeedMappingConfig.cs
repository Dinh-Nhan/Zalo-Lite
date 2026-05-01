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
            // map nested object similiar field
            // request -> entity
            config.NewConfig<CreateMediaRequest, Media>();
            config.NewConfig<Media, MediaResponse>();

            // Content
            config.NewConfig<CreateContentRequest, Content>();
            config.NewConfig<Content, ContentResponse>();

            config.NewConfig<Settings, SettingResponse>();

            // Stats → StatsResponse (tính toán thêm)
            config.NewConfig<Stats, StatsResponse>()
                .Map(dest => dest.ViewCount, src => src.Views.Count)
                .Map(dest => dest.LikeCount, src => src.Likes.Count)
                .Ignore(dest => dest.IsLiked); // service tự tính

            // Feed
            config.NewConfig<CreateFeedRequest, Feeds>()
                .Ignore(dest => dest.Id)
                .Ignore(dest => dest.UserId)    // lấy từ token
                .Ignore(dest => dest.Stats)     // service khởi tạo
                .Ignore(dest => dest.Settings)  // service khởi tạo
                .Ignore(dest => dest.CreateAt)
                .Ignore(dest => dest.DeletedAt!);

            // Feeds → FeedResponse
            config.NewConfig<Feeds, FeedResponse>();
        }
    }
}