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
    public class UserMappingConfig :IRegister
    {
        public void Register(TypeAdapterConfig config)
    {
        // User → UserResponse
        config.NewConfig<User, UserResponse>()
            .Map(dest => dest.FullName,
                 src => $"{src.LastName} {src.FirstName}"); // Họ Tên

        // CreateUserRequest → User
        config.NewConfig<CreateUserRequest, User>()
            .Map(dest => dest.Role, _ => "client")          // default role
            .Map(dest => dest.Status, _ => true)            // default active
            .Map(dest => dest.CreateAt, _ => DateTime.UtcNow)
            .Map(dest => dest.UpdateAt, _ => DateTime.UtcNow)
            .Ignore(dest => dest.Id)
            .Ignore(dest => dest.Avatar);                   // avatar set sau khi upload

        // UpdateUserRequest → User (chỉ update field có giá trị)
        config.NewConfig<UpdateUserRequest, User>()
            .Map(dest => dest.UpdateAt, _ => DateTime.UtcNow)
            .IgnoreNullValues(true);
    }
    }
}