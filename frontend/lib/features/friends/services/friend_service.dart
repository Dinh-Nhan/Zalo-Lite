import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../services/dio_client.dart';

/// Model cho một friendship record từ API
class FriendshipModel {
  final String id;
  final String senderId;
  final String addresseeId;
  final String status; // pending | accepted | declined | blocked
  final String sourceType;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Enriched fields (có trong received requests)
  final String? senderName;
  final String? senderAvatar;
  final String addresseeName;

  const FriendshipModel({
    required this.id,
    required this.senderId,
    required this.addresseeId,
    required this.status,
    required this.sourceType,
    required this.createdAt,
    required this.updatedAt,
    required this.addresseeName,
    this.senderName,
    this.senderAvatar,
  });

  factory FriendshipModel.fromJson(Map<String, dynamic> json) =>
      FriendshipModel(
        id: json['id'] ?? '',
        senderId: json['sender_id'] ?? '',
        addresseeId: json['addressee_id'] ?? '',
        status: json['status'] ?? 'pending',
        sourceType: json['source_type'] ?? 'search',
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
        senderName: json['sender_name'] as String?,
        senderAvatar: json['sender_avatar'] as String?,
        addresseeName: json['addressee_name'] ?? '',
      );
  bool isSender(String currentUid) => senderId == currentUid;
  bool isReceiver(String currentUid) => addresseeId == currentUid;
}

/// Model cho danh sách bạn bè (có kèm tên + avatar)
class FriendSummaryModel {
  final String friendshipId;
  final String friendId;
  final String firstName;
  final String lastName;
  final String avatar;
  final DateTime friendsSince;

  const FriendSummaryModel({
    required this.friendshipId,
    required this.friendId,
    required this.firstName,
    required this.lastName,
    required this.avatar,
    required this.friendsSince,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory FriendSummaryModel.fromJson(Map<String, dynamic> json) =>
      FriendSummaryModel(
        friendshipId: json['friendship_id'] ?? '',
        friendId: json['friend_id'] ?? '',
        firstName: json['first_name'] ?? '',
        lastName: json['last_name'] ?? '',
        avatar: json['avatar'] ?? '',
        friendsSince:
            DateTime.tryParse(json['friends_since'] ?? '') ?? DateTime.now(),
      );
}

/// Model cho user search result
class UserSearchModel {
  final String id;
  final String fullName;
  final String email;
  final String avatar;
  final bool status;
  final String dob;

  const UserSearchModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.avatar,
    required this.status,
    this.dob = '',
  });

  factory UserSearchModel.fromJson(Map<String, dynamic> json) =>
      UserSearchModel(
        id: json['id'] ?? '',
        fullName: json['full_name'] ?? '',
        email: json['email'] ?? '',
        avatar: json['avatar'] ?? '',
        status: json['status'] ?? false,
      );
}

/// Service xử lý toàn bộ nghiệp vụ kết bạn — wrap các endpoint /api/friends
class FriendService {
  static final _dio = DioClient.instance;

  // ── GET /api/friends ──────────────────────────────────────────
  /// Lấy danh sách bạn bè
  static Future<List<FriendSummaryModel>> getFriends() async {
    try {
      final res = await _dio.get('/api/friends');
      debugPrint('getFriends response: ${res.data}');
      final data = res.data as Map<String, dynamic>;
      final list = (data['result'] as List? ?? []);
      return list
          .map((e) => FriendSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── GET /api/friends/requests/received ───────────────────────
  /// Lấy lời mời kết bạn đã nhận (đang pending)
  static Future<List<FriendshipModel>> getPendingReceived() async {
    try {
      final res = await _dio.get('/api/friends/requests/received');
      final data = res.data as Map<String, dynamic>;
      final list = (data['result'] as List? ?? []);
      return list
          .map((e) => FriendshipModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── GET /api/friends/requests/sent ───────────────────────────
  /// Lấy lời mời kết bạn đã gửi (đang pending)
  static Future<List<FriendshipModel>> getPendingSent() async {
    try {
      final res = await _dio.get('/api/friends/requests/sent');
      final data = res.data as Map<String, dynamic>;
      final list = (data['result'] as List? ?? []);
      return list
          .map((e) => FriendshipModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── GET /api/friends/status/{targetUserId} ───────────────────
  /// Kiểm tra trạng thái quan hệ với một user
  static Future<FriendshipModel?> getRelationshipStatus(
    String targetUserId,
  ) async {
    try {
      final res = await _dio.get('/api/friends/status/$targetUserId');
      final data = res.data as Map<String, dynamic>;
      if (data['result'] == null) return null;
      return FriendshipModel.fromJson(data['result'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _handleError(e);
    }
  }

  // ── POST /api/friends/requests ───────────────────────────────
  /// Gửi lời mời kết bạn
  static Future<FriendshipModel> sendRequest({
    required String addresseeId,
    String sourceType = 'search',
  }) async {
    try {
      final res = await _dio.post(
        '/api/friends/requests',
        data: {'addressee_id': addresseeId, 'source_type': sourceType},
      );
      final data = res.data as Map<String, dynamic>;
      return FriendshipModel.fromJson(data['result'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── PATCH /api/friends/requests/{friendshipId} ───────────────
  /// Chấp nhận hoặc từ chối lời mời
  static Future<FriendshipModel> respondRequest({
    required String friendshipId,
    required bool accept,
  }) async {
    try {
      final res = await _dio.patch(
        '/api/friends/requests/$friendshipId',
        data: {'accept': accept},
      );
      final data = res.data as Map<String, dynamic>;
      return FriendshipModel.fromJson(data['result'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── DELETE /api/friends/requests/{friendshipId} ──────────────
  /// Huỷ lời mời kết bạn đã gửi
  static Future<void> cancelRequest(String friendshipId) async {
    try {
      await _dio.delete('/api/friends/requests/$friendshipId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── DELETE /api/friends/{targetUserId} ───────────────────────
  /// Huỷ kết bạn
  static Future<void> unfriend(String targetUserId) async {
    try {
      await _dio.delete('/api/friends/$targetUserId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── GET /api/user/{id} ──────────────────────────────────────────
  /// Lấy thông tin user theo ID (dùng cho QR scan)
  static Future<UserSearchModel> getUserById(String userId) async {
    try {
      final res = await _dio.get('/api/user/$userId');
      final data = res.data as Map<String, dynamic>;
      return UserSearchModel.fromJson(data['result'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── GET /api/user/search/{keyword} ──────────────────────────────
  /// Tìm kiếm người dùng theo tên hoặc email
  static Future<List<UserSearchModel>> searchUsers(String query) async {
    try {
      final res = await _dio.get('/api/user/search/$query');
      final data = res.data as Map<String, dynamic>;
      final list = (data['result'] as List? ?? []);
      return list
          .map((e) => UserSearchModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Helper ────────────────────────────────────────────────────
  static Exception _handleError(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    if (status == 401) return Exception('Chưa đăng nhập hoặc token hết hạn');
    if (status == 403) return Exception('Không có quyền truy cập');
    if (status == 404) return Exception('Không tìm thấy dữ liệu');
    if (status == 409) return Exception('Lời mời kết bạn đã tồn tại');
    if (status != null) return Exception('Lỗi server $status: $body');
    return Exception('Lỗi kết nối: ${e.message}');
  }
}
