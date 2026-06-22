using backend.dtos.Response;
using backend.Models;
using Mapster;

namespace backend.Mappings
{
    public class FriendshipMappingConfig : IRegister
    {
        public void Register(TypeAdapterConfig config)
        {
            // Cấu hình mapping từ Friendship sang FriendshipResponse
            // Các trường có tên trùng khớp sẽ tự động được ánh xạ bởi Mapster.
            config.NewConfig<Friendship, FriendshipResponse>();
        }
    }
}
