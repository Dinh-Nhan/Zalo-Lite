import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/friend_hub_service.dart';
import '../services/friend_service.dart';

import '../../../services/auth_service.dart';

enum LoadingState {
  idle,
  loading,
  success,
  error,
}

class FriendProvider extends ChangeNotifier {
  // =========================================================
  // STATE
  // =========================================================
final Map<String, String?> _friendBirthdays = {};

  Map<String, String?> get friendBirthdays => Map.unmodifiable(_friendBirthdays);

  List<FriendSummaryModel> _friends = [];

  List<FriendshipModel> _pendingReceived = [];

  List<FriendshipModel> _pendingSent = [];

  List<UserSearchModel> _searchResults = [];

  LoadingState _friendsState = LoadingState.idle;

  LoadingState _requestsState = LoadingState.idle;

  LoadingState _searchState = LoadingState.idle;

  final Map<String, bool> _actionLoading = {};

  String? _errorMessage;

  String _searchQuery = '';

  String? _currentUid;


  void Function(String message, {bool isSuccess})? onRealtimeNotify;

  // =========================================================
  // REALTIME
  // =========================================================

  final FriendHubService _hub = FriendHubService();

  StreamSubscription<FriendRealtimeEvent>? _hubSub;

  // =========================================================
  // GETTERS
  // =========================================================

  List<FriendSummaryModel> get friends =>
      List.unmodifiable(_friends);

  List<FriendshipModel> get pendingReceived =>
      List.unmodifiable(_pendingReceived);

  List<FriendshipModel> get pendingSent =>
      List.unmodifiable(_pendingSent);

  List<UserSearchModel> get searchResults =>
      List.unmodifiable(_searchResults);

  LoadingState get friendsState => _friendsState;

  LoadingState get requestsState => _requestsState;

  LoadingState get searchState => _searchState;

  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;

  int get pendingReceivedCount =>
      _pendingReceived.length;

  bool isActionLoading(String userId) =>
      _actionLoading[userId] ?? false;

  // =========================================================
  // CURRENT USER
  // =========================================================

  Future<void> setCurrentUid (String uid) async {
    if (_currentUid == uid) return;
    clear();
    _currentUid = uid;
    await loadAll();
    notifyListeners();
  }

  // =========================================================
  // RELATION HELPERS
  // =========================================================

  bool isFriend(String userId) {
    return _friends.any(
      (f) => f.friendId == userId,
    );
  }

  FriendshipModel? getSentRequest(String userId) {
    try {
      return _pendingSent.firstWhere(
        (f) =>
            f.senderId == _currentUid &&
            f.addresseeId == userId,
      );
    } catch (_) {
      return null;
    }
  }
  

  FriendshipModel? getReceivedRequest(String userId) {
    try {
      return _pendingReceived.firstWhere(
        (f) =>
            f.senderId == userId &&
            f.addresseeId == _currentUid,
      );
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // LOAD FRIENDS
  // =========================================================

  Future<void> loadFriends() async {
    _friendsState = LoadingState.loading;

    _errorMessage = null;

    notifyListeners();

    try {
      _friends = await FriendService.getFriends();

      _friendsState = LoadingState.success;
    } catch (e) {
      _friendsState = LoadingState.error;

      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  // =========================================================
  // LOAD REQUESTS
  // =========================================================

  Future<void> loadRequests() async {
    debugPrint('LOAD REQUESTS');

    _requestsState = LoadingState.loading;

    notifyListeners();

    try {
      final results = await Future.wait([
        FriendService.getPendingReceived(),
        FriendService.getPendingSent(),
      ]);

      _pendingReceived = results[0];

      _pendingSent = results[1];

      // =========================
      // DEBUG RECEIVED
      // =========================

      debugPrint(
        '========== RECEIVED =========='
      );

      for (final f in _pendingReceived) {
        debugPrint('ID: ${f.id}');
        debugPrint(
          'senderId: ${f.senderId}',
        );
        debugPrint(
          'senderName: ${f.senderName}',
        );
        debugPrint(
          'senderAvatar: ${f.senderAvatar}',
        );
        debugPrint(
          'addresseeId: ${f.addresseeId}',
        );
        debugPrint(
          'status: ${f.status}',
        );
        debugPrint('----------------');
      }

      // =========================
      // DEBUG SENT
      // =========================

      debugPrint(
        '========== SENT =========='
      );

      for (final f in _pendingSent) {
        debugPrint('ID: ${f.id}');
        debugPrint(
          'senderId: ${f.senderId}',
        );
        debugPrint(
          'senderName: ${f.senderName}',
        );
        debugPrint(
          'addresseeId: ${f.addresseeId}',
        );
        debugPrint(
          'status: ${f.status}',
        );
        debugPrint('----------------');
      }

      _requestsState =
          LoadingState.success;
    } catch (e) {
      debugPrint(
        'LOAD REQUEST ERROR: $e',
      );

      _requestsState =
          LoadingState.error;

      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  // =========================================================
  // LOAD ALL
  // =========================================================

  Future<void> loadAll() async {
    await Future.wait([
      loadFriends(),
      loadRequests(),
    ]);
  }

  // =========================================================
  // REALTIME START
  // =========================================================

  Future<void> startRealtime() async {
    if (_hubSub != null) return;

    await _hub.connect();

    _hubSub = _hub.events.listen(
      (event) {
        debugPrint('PROVIDER RECEIVED EVENT');

        debugPrint(event.type.toString());

        debugPrint(event.friendship.senderId);

        debugPrint(event.friendship.addresseeId);

        _handleHubEvent(event);
      },
    );
  }

  // =========================================================
  // HANDLE REALTIME EVENT
  // =========================================================

  Future<void> _handleHubEvent(
    FriendRealtimeEvent event,
  ) async {
    switch (event.type) {
      // =====================================================
      // REQUEST RECEIVED
      // =====================================================

      case FriendHubEvent.friendRequestReceived:

        // mình là người nhận
        if (event.friendship.addresseeId ==
            _currentUid) {
          // final exists = _pendingReceived.any(
          //   (f) => f.id == event.friendship.id,
          // );
          final exists = _pendingReceived.any(
            (f) =>
                f.senderId == event.friendship.senderId &&
                f.addresseeId == event.friendship.addresseeId,
          );
          if (!exists) {
            _pendingReceived = [
              event.friendship,
              ..._pendingReceived,
            ];
          }
        }

        // mình là người gửi
        if (event.friendship.senderId ==
            _currentUid) {
          // final exists = _pendingSent.any(
          //   (f) => f.id == event.friendship.id,
          // );
          final exists = _pendingSent.any(
            (f) =>
                f.senderId == event.friendship.senderId &&
                f.addresseeId == event.friendship.addresseeId,
          );
          if (!exists) {
            _pendingSent = [
              event.friendship,
              ..._pendingSent,
            ];
          }
        }

        notifyListeners();

        break;

      // =====================================================
      // REQUEST ACCEPTED
      // =====================================================

      case FriendHubEvent.friendRequestAccepted:

        _pendingSent.removeWhere(
          (f) =>  f.senderId == event.friendship.senderId && f.addresseeId == event.friendship.addresseeId
        );

        _pendingReceived.removeWhere(
          (f) => f.id == event.friendship.id ,
        );

        await loadFriends();

        notifyListeners();

        onRealtimeNotify?.call(
          '✅ Lời mời kết bạn đã được chấp nhận!',
          isSuccess: true,
        );

        break;

      // =====================================================
      // REQUEST DECLINED
      // =====================================================

      case FriendHubEvent.friendRequestDeclined:

        _pendingSent.removeWhere(
          (f) =>  f.senderId == event.friendship.senderId && f.addresseeId == event.friendship.addresseeId
        );

        _pendingReceived.removeWhere(
          (f) => f.id == event.friendship.id,
        );

        notifyListeners();

        onRealtimeNotify?.call(
          '❌ Lời mời kết bạn đã bị từ chối',
        );

        break;
    }
  }

  // =========================================================
  // SEARCH USERS
  // =========================================================

  Future<void> searchUsers(String query) async {
    _searchQuery = query;

    if (query.trim().isEmpty) {
      _searchResults = [];

      _searchState = LoadingState.idle;

      notifyListeners();

      return;
    }

    _searchState = LoadingState.loading;

    notifyListeners();

    try {
      _searchResults =
          await FriendService.searchUsers(
        query.trim(),
      );

      _searchState = LoadingState.success;
    } catch (e) {
      _searchState = LoadingState.error;

      _errorMessage = e.toString();

      _searchResults = [];
    }

    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';

    _searchResults = [];

    _searchState = LoadingState.idle;

    notifyListeners();
  }

  // =========================================================
  // FIND USER BY EMAIL
  // =========================================================

  Future<UserSearchModel?> findUserByEmail(
    String email,
  ) async {
    try {
      _searchState = LoadingState.loading;

      notifyListeners();

      final results =
          await FriendService.searchUsers(email);

      final user =
          results.cast<UserSearchModel?>().firstWhere(
        (u) =>
            u?.email.toLowerCase() ==
            email.toLowerCase(),
        orElse: () => null,
      );

      _searchState = LoadingState.success;

      notifyListeners();

      return user;
    } catch (e) {
      _searchState = LoadingState.error;

      _errorMessage = e.toString();

      notifyListeners();

      return null;
    }
  }

  // =========================================================
  // SEND FRIEND REQUEST
  // =========================================================

  Future<void> sendFriendRequest(
    String targetUserId,
  ) async {
    _setActionLoading(targetUserId, true);

    try {
      final friendship =
          await FriendService.sendRequest(
        addresseeId: targetUserId,
        sourceType: 'search',
      );

      _pendingSent = [
        friendship,
        ..._pendingSent,
      ];

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();

      notifyListeners();
    } finally {
      _setActionLoading(targetUserId, false);
    }
  }

  // =========================================================
  // CANCEL FRIEND REQUEST
  // =========================================================
  // Future<void> cancelFriendRequest(
  //   String targetUserId,
  // ) async {
  //   final friendship =
  //       getSentRequest(targetUserId);

  //   if (friendship == null) return;

  //   _setActionLoading(targetUserId, true);

  //   try {
  //     await FriendService.cancelRequest(
  //       friendship.id,
  //     );

  //     _pendingSent.removeWhere(
  //       (f) =>  f.senderId == friendship.senderId && f.addresseeId == friendship.addresseeId
  //     );

  //     notifyListeners();
  //   } catch (e) {
  //     _errorMessage = e.toString();

  //     notifyListeners();
  //   } finally {
  //     _setActionLoading(targetUserId, false);
  //   }
  // }
  Future<void> cancelFriendRequest(String targetUserId) async {
    final friendship = getSentRequest(targetUserId);
    if (friendship == null) return;

    _setActionLoading(targetUserId, true);

    try {
      await FriendService.cancelRequest(friendship.id);

      // CHỈ UPDATE STATE THẬT
      _pendingSent.removeWhere(
        (f) => f.id == friendship.id,
      );

      notifyListeners();
    } finally {
      _setActionLoading(targetUserId, false);
    }
  }
  // =========================================================
  // RESEND FRIEND REQUEST
  // =========================================================
  // Future<void> resendFriendRequest({
  //   required FriendshipModel oldRequest,
  // }) async {
  //   try {
  //     // Gửi request mới
  //     final newRequest =
  //         await FriendService.sendRequest(
  //       addresseeId:
  //           oldRequest.addresseeId,
  //     );

  //     // Xóa request cũ fake
  //     _pendingSent.removeWhere(
  //       (f) => f.id == oldRequest.id,
  //     );

  //     // Add request mới thật
  //     _pendingSent.insert(0, newRequest);

  //     notifyListeners();
  //   } catch (e) {
  //     _errorMessage = e.toString();
  //     notifyListeners();
  //     rethrow;
  //   }
  // }
  Future<void> resendFriendRequest({
    required FriendshipModel oldRequest,
  }) async {
    final newRequest = await FriendService.sendRequest(
      addresseeId: oldRequest.addresseeId,
    );

    _pendingSent.removeWhere(
      (f) => f.id == oldRequest.id,
    );

    _pendingSent.insert(0, newRequest);

    notifyListeners();
  }
    // =========================================================
    // ACCEPT FRIEND REQUEST
    // =========================================================

    Future<void> acceptFriendRequest(String targetUserId) async {
      final friendship =
          getReceivedRequest(targetUserId);

      if (friendship == null) return;

      _setActionLoading(targetUserId, true);

      try {
        await FriendService.respondRequest(
          friendshipId: friendship.id,
          accept: true,
        );

        // _pendingReceived.removeWhere(
        //   (f) => f.id == friendship.id,
        // );
        final index = _pendingReceived.indexWhere(
          (f) => f.id == friendship.id,
        );

        if (index != -1) {
          final old = _pendingReceived[index];

          _pendingReceived[index] = FriendshipModel(
            id: old.id,
            senderId: old.senderId,
            addresseeId: old.addresseeId,
            status: 'accepted',
            sourceType: old.sourceType,
            createdAt: old.createdAt,
            updatedAt: DateTime.now(),
            senderName: old.senderName,
            senderAvatar: old.senderAvatar,
            addresseeName: old.addresseeName,
          );
        }
        _pendingSent.removeWhere(
          (f) =>  f.senderId == friendship.senderId && f.addresseeId == friendship.addresseeId
        );
        notifyListeners();
        await loadFriends();
      } catch (e) {
        _errorMessage = e.toString();

        notifyListeners();
      } finally {
        _setActionLoading(targetUserId, false);
      }
    }
  
  // =========================================================
  // DECLINE FRIEND REQUEST
  // =========================================================

  Future<void> declineFriendRequest(
    String targetUserId,
  ) async {
    final friendship =
        getReceivedRequest(targetUserId);

    if (friendship == null) return;

    _setActionLoading(targetUserId, true);

    try {
      await FriendService.respondRequest(
        friendshipId: friendship.id,
        accept: false,
      );

      _pendingReceived.removeWhere(
        (f) => f.id == friendship.id,
      );

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();

      notifyListeners();
    } finally {
      _setActionLoading(targetUserId, false);
    }
  }

  // =========================================================
  // UNFRIEND
  // =========================================================

  Future<void> unfriend(
    String targetUserId,
  ) async {
    _setActionLoading(targetUserId, true);

    try {
      await FriendService.unfriend(
        targetUserId,
      );

      _friends.removeWhere(
        (f) => f.friendId == targetUserId,
      );

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();

      notifyListeners();
    } finally {
      _setActionLoading(targetUserId, false);
    }
  }

  // =========================================================
  // PRIVATE
  // =========================================================

  void _setActionLoading(
    String userId,
    bool value,
  ) {
    _actionLoading[userId] = value;

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;

    notifyListeners();
  }

  // =========================================================
  // CLEAR
  // =========================================================

  void clear() {
    _friends.clear();

    _pendingReceived.clear();

    _pendingSent.clear();

    _searchResults.clear();

    _actionLoading.clear();

    _friendsState = LoadingState.idle;

    _requestsState = LoadingState.idle;

    _searchState = LoadingState.idle;

    _errorMessage = null;

    _searchQuery = '';

    onRealtimeNotify = null;

    notifyListeners();
  }

  // =========================================================
  // DISPOSE REALTIME
  // =========================================================

  Future<void> disposeRealtime() async {
    await _hubSub?.cancel();

    _hubSub = null;

    await _hub.disconnect();
  }

  Future<void> loadFriendBirthdays() async {
    for (final friend in _friends) {
      try {
        final user =
            await AuthService.getUserById(friend.friendId);

        _friendBirthdays[friend.friendId] =
            user.dateOfBirth;
        debugPrint(
          'Loaded birthday for ${friend.friendId}: ${user.dateOfBirth}',
        );
      } catch (e) {
        debugPrint(
          'Lỗi lấy ngày sinh ${friend.friendId}: $e',
        );
      }
    }

    notifyListeners();
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _hubSub?.cancel();

    _hub.dispose();

    super.dispose();
  }
}
