using backend.common;
using backend.dtos.Request.Chat;
using backend.dtos.Response.Chat;
using backend.Enums;
using backend.Exceptions;
using backend.Extensions;
using backend.Hubs;
using backend.Services;
using backend.Utils;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.Controllers;

/// <summary>
/// Controller quản lý tất cả hoạt động chat, trò chuyện, nhắn tin và quản lý nhóm.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[FirebaseAuthorize]
public class ChatController(ChatService _chatService, ILogger<ChatController> _logger,
                            IHubContext<ChatHub> _hubContext, FcmService _fcm,
                             UserService _userService, CloudinaryService _cloudinaryService) : ControllerBase
{
    #region Conversations

    /// <summary>
    /// Lấy danh sách toàn bộ các cuộc hội thoại (private và nhóm) của người dùng hiện tại.
    /// </summary>
    /// <returns>Danh sách cuộc hội thoại</returns>
    /// <response code="200">Lấy danh sách thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    [HttpGet("conversations")]
    [ProducesResponseType(typeof(ApiResponse<List<ConversationResponse>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetConversations()
    {
        var conversations = await _chatService.GetUserConversationsAsync(User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(conversations, "Conversations retrieved successfully"));
    }

    /// <summary>
    /// Lấy thông tin chi tiết của một cuộc hội thoại cụ thể theo ID.
    /// </summary>
    /// <param name="conversationId">ID cuộc hội thoại</param>
    /// <returns>Hồ sơ chi tiết cuộc hội thoại</returns>
    /// <response code="200">Lấy thông tin thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="403">Người dùng không phải thành viên cuộc hội thoại này</response>
    /// <response code="404">Không tìm thấy cuộc hội thoại</response>
    [HttpGet("conversations/{conversationId}")]
    [ProducesResponseType(typeof(ApiResponse<ConversationResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetConversation(string conversationId)
    {
        var conversation = await _chatService.GetConversationByIdAsync(conversationId, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(conversation, "Conversation retrieved successfully"));
    }

    /// <summary>
    /// Tạo mới một cuộc hội thoại (Private 1-1 hoặc Chat Nhóm).
    /// </summary>
    /// <param name="request">Thông tin yêu cầu tạo hội thoại</param>
    /// <returns>Thông tin chi tiết cuộc hội thoại vừa tạo</returns>
    /// <response code="200">Tạo cuộc hội thoại thành công</response>
    /// <response code="400">Yêu cầu không hợp lệ (nhóm thiếu thành viên, chat với chính mình...)</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    [HttpPost("conversations")]
    [ProducesResponseType(typeof(ApiResponse<ConversationResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> CreateConversation([FromBody] CreateConversationRequest request)
    {
        var conversation = await _chatService.CreateConversationAsync(request, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(conversation, "Conversation created successfully"));
    }

    /// <summary>
    /// Cập nhật thông tin cơ bản của nhóm chat (Tên nhóm, ảnh đại diện, mô tả).
    /// </summary>
    /// <param name="request">Thông tin nhóm cập nhật</param>
    /// <returns>Hồ sơ nhóm chat sau khi cập nhật</returns>
    /// <response code="200">Cập nhật nhóm thành công</response>
    /// <response code="400">Không phải nhóm hoặc thông tin sai định dạng</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="403">Người dùng không có quyền quản trị/sửa đổi</response>
    [HttpPut("conversations/group")]
    [ProducesResponseType(typeof(ApiResponse<ConversationResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> UpdateGroup([FromBody] UpdateGroupRequest request)
    {
        var conversation = await _chatService.UpdateGroupAsync(request, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(conversation, "Group updated successfully"));
    }

    /// <summary>
    /// Thêm các thành viên mới vào nhóm chat hiện tại.
    /// </summary>
    /// <param name="request">Danh sách thành viên cần thêm</param>
    /// <returns>Hồ sơ nhóm chat sau khi thêm thành viên</returns>
    /// <response code="200">Thêm thành viên thành công</response>
    /// <response code="400">Không phải nhóm chat hoặc trùng lặp thành viên</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="403">Không có quyền thêm thành viên</response>
    [HttpPost("conversations/participants")]
    [ProducesResponseType(typeof(ApiResponse<ConversationResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> AddParticipants([FromBody] AddParticipantsRequest request)
    {
        var conversation = await _chatService.AddParticipantsAsync(request, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(conversation, "Participants added successfully"));
    }

    /// <summary>
    /// Xóa một thành viên khỏi nhóm chat (hoặc rời nhóm nếu tự xóa bản thân).
    /// </summary>
    /// <param name="conversationId">ID nhóm chat</param>
    /// <param name="userIdToRemove">UID của thành viên cần xóa</param>
    /// <returns>Kết quả xóa thành viên thành công</returns>
    /// <response code="200">Xóa thành viên khỏi nhóm thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="403">Không có quyền xóa thành viên</response>
    /// <response code="404">Không tìm thấy nhóm hoặc thành viên</response>
    [HttpDelete("conversations/{conversationId}/participants/{userIdToRemove}")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> RemoveParticipant(string conversationId, string userIdToRemove)
    {
        var userId = User.GetUid();
        await _chatService.RemoveParticipantAsync(conversationId, userIdToRemove, userId);

        return Ok(ApiResponse<object>.SuccessResponse(default(object), "Participant removed successfully"));
    }

    /// <summary>
    /// Rời khỏi hoặc xóa hoàn toàn cuộc hội thoại ở phía người dùng hiện tại.
    /// </summary>
    /// <param name="conversationId">ID cuộc hội thoại</param>
    /// <returns>Kết quả thực hiện thành công</returns>
    /// <response code="200">Xóa cuộc hội thoại thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="404">Không tìm thấy hội thoại</response>
    [HttpDelete("conversations/{conversationId}")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteConversation(string conversationId)
    {
        var userId = User.GetUid();
        await _chatService.DeleteConversationAsync(conversationId, userId);

        return Ok(ApiResponse<object>.SuccessResponse(default(object), "Conversation deleted successfully"));
    }

    #endregion

    #region Pin Message

    /// <summary>
    /// Ghim (Pin) một tin nhắn trong cuộc hội thoại để hiển thị nổi bật.
    /// </summary>
    /// <param name="conversationId">ID cuộc hội thoại</param>
    /// <param name="messageId">ID tin nhắn cần ghim</param>
    /// <returns>Hồ sơ cuộc hội thoại sau khi ghim tin nhắn</returns>
    /// <response code="200">Ghim tin nhắn thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="404">Không tìm thấy tin nhắn hoặc hội thoại</response>
    [HttpPost("conversations/{conversationId}/pin/{messageId}")]
    [ProducesResponseType(typeof(ApiResponse<ConversationResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> PinMessage(string conversationId, string messageId)
    {
        var conversation = await _chatService.PinMessageAsync(conversationId, messageId, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(conversation, "Message pinned successfully"));
    }

    /// <summary>
    /// Bỏ ghim (Unpin) tin nhắn đang được ghim trong cuộc hội thoại.
    /// </summary>
    /// <param name="conversationId">ID cuộc hội thoại</param>
    /// <returns>Hồ sơ cuộc hội thoại sau khi bỏ ghim</returns>
    /// <response code="200">Bỏ ghim thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="404">Không tìm thấy tin nhắn ghim nào</response>
    [HttpDelete("conversations/{conversationId}/pin")]
    [ProducesResponseType(typeof(ApiResponse<ConversationResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UnpinMessage(string conversationId)
    {
        var conversation = await _chatService.UnpinMessageAsync(conversationId, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(conversation, "Message unpinned successfully"));
    }

    #endregion

    #region Conversation Settings

    /// <summary>
    /// Lấy cấu hình cá nhân của cuộc hội thoại (chủ đề, hình nền, emoji, tự tải, tự hủy...).
    /// </summary>
    /// <param name="conversationId">ID cuộc hội thoại</param>
    /// <returns>Cấu hình chi tiết cuộc hội thoại</returns>
    /// <response code="200">Lấy cấu hình thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    [HttpGet("conversations/{conversationId}/settings")]
    [ProducesResponseType(typeof(ApiResponse<ConversationSettingsResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetConversationSettings(string conversationId)
    {
        var settings = await _chatService.GetConversationSettingsAsync(conversationId, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(settings, "Settings retrieved successfully"));
    }

    /// <summary>
    /// Cập nhật cấu hình cuộc hội thoại (theme, ảnh nền, emoji mặc định, tự động tải...).
    /// </summary>
    /// <param name="conversationId">ID cuộc hội thoại</param>
    /// <param name="request">Nội dung cấu hình thay đổi</param>
    /// <returns>Cấu hình cuộc hội thoại sau cập nhật</returns>
    /// <response code="200">Cập nhật thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    [HttpPut("conversations/{conversationId}/settings")]
    [ProducesResponseType(typeof(ApiResponse<ConversationSettingsResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> UpdateConversationSettings(
        string conversationId, [FromBody] ConversationSettingsRequest request)
    {
        var settings = await _chatService.UpdateConversationSettingsAsync(conversationId, request, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(settings, "Settings updated successfully"));
    }

    /// <summary>
    /// Thiết lập thời gian tự động xóa/tự hủy tin nhắn (Disappearing Messages).
    /// </summary>
    /// <param name="conversationId">ID cuộc hội thoại</param>
    /// <param name="request">Thời gian đếm ngược (0 = tắt, >0 = giây)</param>
    /// <returns>Cấu hình cuộc hội thoại sau cập nhật</returns>
    /// <response code="200">Thiết lập thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    [HttpPut("conversations/{conversationId}/settings/disappearing")]
    [ProducesResponseType(typeof(ApiResponse<ConversationSettingsResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> SetDisappearingDuration(
        string conversationId, [FromBody] DisappearingSettingRequest request)
    {
        var settings = await _chatService.SetDisappearingDurationAsync(conversationId, request, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(settings, "Disappearing messages setting updated"));
    }

    #endregion

    #region Nickname

    /// <summary>
    /// Đặt biệt danh (Nickname) cho một thành viên trong cuộc hội thoại.
    /// </summary>
    /// <param name="conversationId">ID cuộc hội thoại</param>
    /// <param name="userId">UID của thành viên cần đặt biệt danh</param>
    /// <param name="request">Nội dung biệt danh mới</param>
    /// <returns>Thông tin thành viên sau cập nhật biệt danh</returns>
    /// <response code="200">Đặt biệt danh thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    [HttpPut("conversations/{conversationId}/members/{userId}/nickname")]
    [ProducesResponseType(typeof(ApiResponse<ParticipantResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> SetNickname(
        string conversationId, string userId, [FromBody] SetNicknameRequest request)
    {
        var participant = await _chatService.SetNicknameAsync(conversationId, userId, request, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(participant, "Nickname updated successfully"));
    }

    #endregion

    #region Group Settings

    /// <summary>
    /// Cập nhật quyền kiểm duyệt nhóm chat (chỉ quản trị viên mới được thực hiện).
    /// </summary>
    /// <param name="conversationId">ID nhóm chat</param>
    /// <param name="request">Cấu hình quyền hạn mới của nhóm</param>
    /// <returns>Hồ sơ cuộc hội thoại nhóm</returns>
    /// <response code="200">Cập nhật quyền thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="403">Người dùng không phải quản trị viên nhóm</response>
    [HttpPut("conversations/{conversationId}/group-settings")]
    [ProducesResponseType(typeof(ApiResponse<ConversationResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> UpdateGroupSettings(
        string conversationId, [FromBody] GroupSettingsRequest request)
    {
        var conversation = await _chatService.UpdateGroupSettingsAsync(conversationId, request, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(conversation, "Group settings updated successfully"));
    }

    /// <summary>
    /// Gửi yêu cầu xin tham gia vào nhóm chat (khi nhóm yêu cầu phê duyệt thành viên).
    /// </summary>
    /// <param name="conversationId">ID nhóm chat</param>
    /// <returns>Thông tin yêu cầu tham gia vừa tạo</returns>
    /// <response code="200">Gửi yêu cầu thành công</response>
    /// <response code="400">Yêu cầu đã tồn tại hoặc đã là thành viên</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    [HttpPost("conversations/{conversationId}/join-requests")]
    [ProducesResponseType(typeof(ApiResponse<JoinRequestResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> CreateJoinRequest(string conversationId)
    {
        var joinRequest = await _chatService.CreateJoinRequestAsync(conversationId, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(joinRequest, "Join request submitted successfully"));
    }

    /// <summary>
    /// Lấy danh sách các yêu cầu đang chờ phê duyệt tham gia nhóm (chỉ dành cho quản trị viên).
    /// </summary>
    /// <param name="conversationId">ID nhóm chat</param>
    /// <returns>Danh sách yêu cầu phê duyệt</returns>
    /// <response code="200">Lấy danh sách thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="403">Người dùng không phải quản trị viên nhóm</response>
    [HttpGet("conversations/{conversationId}/join-requests")]
    [ProducesResponseType(typeof(ApiResponse<List<JoinRequestResponse>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetJoinRequests(string conversationId)
    {
        var requests = await _chatService.GetJoinRequestsAsync(conversationId, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(requests, "Join requests retrieved successfully"));
    }

    /// <summary>
    /// Phê duyệt (Approve) đồng ý cho một thành viên vào nhóm.
    /// </summary>
    /// <param name="conversationId">ID nhóm chat</param>
    /// <param name="userId">UID của người xin gia nhập</param>
    /// <returns>Không có dữ liệu trả về</returns>
    /// <response code="200">Phê duyệt đồng ý thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="403">Người dùng không phải quản trị viên nhóm</response>
    [HttpPost("conversations/{conversationId}/join-requests/{userId}/approve")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> ApproveJoinRequest(string conversationId, string userId)
    {
        await _chatService.ReviewJoinRequestAsync(conversationId, userId, approve: true, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(null, "Join request approved"));
    }

    /// <summary>
    /// Từ chối (Reject) không cho người dùng gia nhập nhóm chat.
    /// </summary>
    /// <param name="conversationId">ID nhóm chat</param>
    /// <param name="userId">UID của người xin gia nhập</param>
    /// <returns>Không có dữ liệu trả về</returns>
    /// <response code="200">Từ chối thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="403">Người dùng không phải quản trị viên nhóm</response>
    [HttpPost("conversations/{conversationId}/join-requests/{userId}/reject")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> RejectJoinRequest(string conversationId, string userId)
    {
        await _chatService.ReviewJoinRequestAsync(conversationId, userId, approve: false, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(null, "Join request rejected"));
    }

    #endregion

    #region Messages

    /// <summary>
    /// Lấy danh sách tin nhắn cũ trong cuộc hội thoại (hỗ trợ phân trang ngược bằng Cursor pagination).
    /// </summary>
    /// <param name="conversationId">ID cuộc hội thoại</param>
    /// <param name="limit">Số lượng tin nhắn cần lấy (Mặc định 50)</param>
    /// <param name="beforeMessageId">ID tin nhắn làm mốc để lấy các tin nhắn cũ hơn nó</param>
    /// <returns>Danh sách tin nhắn (MessageResponse)</returns>
    /// <response code="200">Lấy tin nhắn thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    [HttpGet("conversations/{conversationId}/messages")]
    [ProducesResponseType(typeof(ApiResponse<List<MessageResponse>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetMessages(
        string conversationId,
        [FromQuery] int limit = 50,
        [FromQuery] string? beforeMessageId = null)
    {
        var messages = await _chatService.GetMessagesAsync(conversationId, User.GetUid(), limit, beforeMessageId);
        return Ok(ApiResponse<object>.SuccessResponse(messages, "Messages retrieved successfully"));
    }

    /// <summary>
    /// Tải lên một tệp đa phương tiện (Ảnh/Video/Audio) phục vụ gửi tin nhắn.
    /// </summary>
    /// <param name="request">File đính kèm và ID cuộc hội thoại tương ứng</param>
    /// <returns>URL lưu trữ CDN trên Cloudinary và định dạng tài nguyên</returns>
    /// <response code="200">Tải lên tệp thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="422">File tải lên quá giới hạn kích thước hoặc sai định dạng MIME</response>
    [HttpPost("upload")]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(ApiResponse<MediaUploadResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status422UnprocessableEntity)]
    public async Task<IActionResult> UploadMedia([FromForm] UploadMediaRequest request)
    {
        var userId = User.GetUid();
        _logger.LogInformation("[UploadMedia] User {UserId} bắt đầu upload file '{FileName}' (ContentType: {ContentType}, Size: {Size} bytes) cho Conversation {ConversationId}", userId, request.File.FileName, request.File.ContentType, request.File.Length, request.ConversationId);

        // Ensure the caller is a participant of the conversation before accepting the upload
        await _chatService.GetConversationByIdAsync(request.ConversationId, userId);

        var (url, _, mediaType) = await _cloudinaryService.UploadChatMediaAsync(request.File, userId, request.ConversationId);
        _logger.LogInformation("[UploadMedia] Upload thành công lên Cloudinary. URL: {Url}, MediaType: {MediaType}", url, mediaType);

        var response = new MediaUploadResponse
        {
            MediaUrl = url,
            MediaType = mediaType,
            FileName = request.File.FileName,
            FileSize = request.File.Length,
        };
        return Ok(ApiResponse<MediaUploadResponse>.SuccessResponse(response, "Media uploaded successfully"));
    }

    /// <summary>
    /// Gửi một tin nhắn mới trong cuộc hội thoại (Real-time qua SignalR + Notification FCM).
    /// </summary>
    /// <param name="request">Nội dung tin nhắn và cấu hình đính kèm</param>
    /// <returns>Chi tiết tin nhắn vừa gửi thành công</returns>
    /// <response code="200">Gửi tin nhắn thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="422">Nội dung tin nhắn không hợp lệ</response>
    [HttpPost("messages")]
    [ProducesResponseType(typeof(ApiResponse<MessageResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status422UnprocessableEntity)]
    public async Task<IActionResult> SendMessage([FromBody] SendMessageRequest request)
    {
        var userId = User.GetUid();
        var message = await _chatService.SendMessageAsync(request, userId);

        // Broadcast to other participants so they receive the message in real-time
        var participantIds = message.ParticipantIds ?? new List<string>();
        var broadcastTasks = participantIds
            .Where(id => id != userId)
            .Select(id => _hubContext.Clients.Group($"user_{id}").SendAsync("ReceiveMessage", message))
            .ToList();
        if (broadcastTasks.Count > 0)
            await Task.WhenAll(broadcastTasks);

        // FCM for offline participants — fire and forget
        _ = Task.Run(async () =>
        {
            var body = message.Type == "call" ? message.Content : message.Content;
            var offlineIds = participantIds.Where(id => id != userId && !ChatHub.IsUserOnlineStatic(id));
            foreach (var id in offlineIds)
            {
                var token = await _userService.GetFcmTokenAsync(id);
                if (!string.IsNullOrEmpty(token))
                    await _fcm.SendMessageNotificationAsync(
                        token,
                        message.NotificationTitle ?? message.SenderName,
                        body,
                        message.ConversationId,
                        message.SenderName,
                        message.IsGroupConversation);
            }
        });

        return Ok(ApiResponse<object>.SuccessResponse(message, "Message sent successfully"));
    }

    /// <summary>
    /// Sửa đổi nội dung tin nhắn (chỉ người gửi mới có quyền thực hiện).
    /// </summary>
    /// <param name="request">Nội dung cập nhật tin nhắn</param>
    /// <returns>Chi tiết tin nhắn sau cập nhật</returns>
    /// <response code="200">Cập nhật tin nhắn thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="403">Không có quyền sửa tin nhắn này</response>
    [HttpPut("messages")]
    [ProducesResponseType(typeof(ApiResponse<MessageResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> UpdateMessage([FromBody] UpdateMessageRequest request)
    {
        var message = await _chatService.UpdateMessageAsync(request, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(message, "Message updated successfully"));
    }

    /// <summary>
    /// Thu hồi tin nhắn đối với tất cả thành viên trong phòng chat (chỉ người gửi mới thực hiện được).
    /// </summary>
    /// <param name="conversationId">ID cuộc hội thoại</param>
    /// <param name="messageId">ID tin nhắn cần thu hồi</param>
    /// <returns>Kết quả thực hiện thành công</returns>
    /// <response code="200">Thu hồi tin nhắn thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    /// <response code="403">Không phải người gửi tin nhắn này</response>
    [HttpDelete("conversations/{conversationId}/messages/{messageId}")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> DeleteMessage(string conversationId, string messageId)
    {
        var userId = User.GetUid();
        await _chatService.DeleteMessageAsync(conversationId, messageId, userId);

        return Ok(ApiResponse<object>.SuccessResponse(default(object), "Message deleted successfully"));
    }

    /// <summary>
    /// Ẩn tin nhắn chỉ ở phía hiển thị của bản thân (phía người kia vẫn thấy bình thường).
    /// </summary>
    /// <param name="conversationId">ID cuộc hội thoại</param>
    /// <param name="messageId">ID tin nhắn cần ẩn</param>
    /// <returns>Không có dữ liệu trả về</returns>
    /// <response code="200">Ẩn tin nhắn thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    [HttpPost("conversations/{conversationId}/messages/{messageId}/hide")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> HideMessageForMe(string conversationId, string messageId)
    {
        await _chatService.HideMessageForMeAsync(conversationId, messageId, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(null, "Message hidden"));
    }

    /// <summary>
    /// Thêm hoặc hủy bày tỏ cảm xúc (React emoji) đối với một tin nhắn (Toggle react).
    /// </summary>
    /// <param name="request">Loại cảm xúc emoji và ID tin nhắn</param>
    /// <returns>Chi tiết tin nhắn kèm danh sách cảm xúc cập nhật</returns>
    /// <response code="200">Bày tỏ cảm xúc thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    [HttpPost("messages/react")]
    [ProducesResponseType(typeof(ApiResponse<MessageResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> ReactToMessage([FromBody] ReactToMessageRequest request)
    {
        var message = await _chatService.ReactToMessageAsync(request, User.GetUid());
        return Ok(ApiResponse<object>.SuccessResponse(message, "Reaction updated successfully"));
    }

    /// <summary>
    /// Đánh dấu tin nhắn là ĐÃ ĐỌC (Read) bởi người dùng hiện tại.
    /// </summary>
    /// <param name="conversationId">ID cuộc hội thoại</param>
    /// <param name="messageId">ID tin nhắn</param>
    /// <returns>Kết quả cập nhật thành công</returns>
    /// <response code="200">Cập nhật thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    [HttpPost("conversations/{conversationId}/messages/{messageId}/read")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> MarkAsRead(string conversationId, string messageId)
    {
        var userId = User.GetUid();
        await _chatService.MarkAsReadAsync(conversationId, messageId, userId);

        return Ok(ApiResponse<object>.SuccessResponse(default(object), "Message marked as read"));
    }

    /// <summary>
    /// Đánh dấu tin nhắn là ĐÃ NHẬN (Delivered) bởi thiết bị người dùng.
    /// </summary>
    /// <param name="conversationId">ID cuộc hội thoại</param>
    /// <param name="messageId">ID tin nhắn</param>
    /// <returns>Kết quả cập nhật thành công</returns>
    /// <response code="200">Cập nhật thành công</response>
    /// <response code="401">Người dùng chưa xác thực</response>
    [HttpPost("conversations/{conversationId}/messages/{messageId}/delivered")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> MarkAsDelivered(string conversationId, string messageId)
    {
        var userId = User.GetUid();
        await _chatService.MarkAsDeliveredAsync(conversationId, messageId, userId);

        return Ok(ApiResponse<object>.SuccessResponse(default(object), "Message marked as delivered"));
    }

    #endregion
}
