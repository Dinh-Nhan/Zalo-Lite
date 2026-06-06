import 'package:dio/dio.dart';

import '../../../services/auth_service.dart';
import '../../../services/dio_client.dart';

class FriendshipModel {
  final String id;
  final String senderId;
  final String addresseeId;
  final String status;
  final String sourceType;
  final DateTime createdAt;
  final DateTime updatedAt;
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

  factory FriendshipModel.fromJson(Map<String, dynamic> json) => FriendshipModel(
        id: json['id'] ?? '',
        senderId: json['senderId'] ?? json['sender_id'] ?? '',
        addresseeId: json['addresseeId'] ?? json['addressee_id'] ?? '',
        status: json['status'] ?? 'pending',
        sourceType: json['sourceType'] ?? json['source_type'] ?? 'search',
        createdAt: DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] ?? json['updated_at'] ?? '') ?? DateTime.now(),
        senderName: json['senderName'] as String?,
        senderAvatar: json['senderAvatar'] as String?,
        addresseeName: json['addresseeName'] ?? json['addressee_name'] ?? '',
      );

  bool isSender(String currentUid) => senderId == currentUid;
  bool isReceiver(String currentUid) => addresseeId == currentUid;
}

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

  factory FriendSummaryModel.fromJson(Map<String, dynamic> json) => FriendSummaryModel(
        friendshipId: json['friendshipId'] ?? json['friendship_id'] ?? '',
        friendId: json['friendId'] ?? json['friend_id'] ?? '',
        firstName: json['firstName'] ?? json['first_name'] ?? '',
        lastName: json['lastName'] ?? json['last_name'] ?? '',
        avatar: json['avatar'] ?? '',
        friendsSince: DateTime.tryParse(json['friendsSince'] ?? json['friends_since'] ?? '') ?? DateTime.now(),
      );
}

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

  factory UserSearchModel.fromJson(Map<String, dynamic> json) => UserSearchModel(
        id: json['id'] ?? '',
        fullName: json['fullName'] ?? json['full_name'] ?? '',
        email: json['email'] ?? '',
        avatar: json['avatar'] ?? '',
        status: json['status'] ?? false,
        dob: json['dob'] ?? json['dateOfBirth'] ?? '',
      );
}

class FriendService {
  static final _dio = DioClient.instance;

  static Future<List<FriendSummaryModel>> getFriends() async {
    try {
      final res = await _dio.get('/api/friends');
      final data = res.data as Map<String, dynamic>;
      final list = (data['result'] as List? ?? []);
      return list
          .map((e) => FriendSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<FriendSummaryModel>> getFriendsByUserId(String userId) async {
    try {
      final res = await _dio.get('/api/friends/user/$userId');
      final data = res.data as Map<String, dynamic>;
      final list = (data['result'] as List? ?? []);
      return list
          .map((e) => FriendSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

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

  static Future<FriendshipModel?> getRelationshipStatus(String targetUserId) async {
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

  static Future<FriendshipModel> sendRequest({
    required String addresseeId,
    String sourceType = 'search',
  }) async {
    try {
      final res = await _dio.post(
        '/api/friends/requests',
        data: {'addresseeId': addresseeId, 'sourceType': sourceType},
      );
      final data = res.data as Map<String, dynamic>;
      return FriendshipModel.fromJson(data['result'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<FriendshipModel> respondRequest({
    required String friendshipId,
    required bool accept,
  }) async {
    try {
      final res = await _dio.patch(
        '/api/friends/requests/$friendshipId',
        data: {'Accept': accept},
      );
      final data = res.data as Map<String, dynamic>;
      return FriendshipModel.fromJson(data['result'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> cancelRequest(String friendshipId) async {
    try {
      await _dio.delete('/api/friends/requests/$friendshipId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> unfriend(String friendshipId) async {
    try {
      await _dio.delete('/api/friends/$friendshipId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<UserSearchModel>> searchUsers(String keyword) async {
    try {
      final res = await _dio.get('/api/user/search/$keyword');
      final data = res.data as Map<String, dynamic>;
      final list = (data['result'] as List? ?? []);
      return list.map((e) => UserSearchModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<UserSearchModel> getUserById(String userId) async {
    final user = await AuthService.getUserById(userId);
    return UserSearchModel(
      id: userId,
      fullName: user.fullName,
      email: user.email,
      avatar: user.avatar ?? '',
      status: true,
    );
  }

  static String _handleError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'] ?? e.message;
      return message?.toString() ?? 'Có lỗi xảy ra';
    }
    return e.message ?? 'Có lỗi xảy ra';
  }
}
