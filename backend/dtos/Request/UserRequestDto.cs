namespace backend.dtos.Request
{
    public class UserRequestDto
    {
        public string Id { get; set; } = default!;

        public string Email { get; set; } = default!;

        public string FullName { get; set; } = default!;

        public string Avatar { get; set; } = default!;
    }
}
