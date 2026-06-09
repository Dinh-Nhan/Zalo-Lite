import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/friend_hub_service.dart';
import '../services/friend_service.dart';

enum LoadingState { idle, loading, success, error }

class FriendProvider extends ChangeNotifier {
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
  final FriendHubService _hub = FriendHubService();
  StreamSubscription<FriendRealtimeEvent>? _hubSub;

  List<FriendSummaryModel> get friends => List.unmodifiable(_friends);
  List<FriendshipModel> get pendingReceived => List.unmodifiable(_pendingReceived);
  List<FriendshipModel> get pendingSent => List.unmodifiable(_pendingSent);
  List<UserSearchModel> get searchResults => List.unmodifiable(_searchResults);
  LoadingState get friendsState => _friendsState;
  LoadingState get requestsState => _requestsState;
  LoadingState get searchState => _searchState;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  int get pendingReceivedCount => _pendingReceived.length;
  bool isActionLoading(String userId) => _actionLoading[userId] ?? false;

  Future<void> setCurrentUid(String uid) async {
    if (_currentUid == uid) return;
    clear();
    _currentUid = uid;
    await loadAll();
    notifyListeners();
  }

  bool isFriend(String userId) {
    return _friends.any((f) => f.friendId == userId);
  }

  FriendshipModel? getSentRequest(String userId) {
    try {
      return _pendingSent.firstWhere(
        (f) => f.senderId == _currentUid && f.addresseeId == userId,
      );
    } catch (_) {
      return null;
    }
  }

  FriendshipModel? getReceivedRequest(String userId) {
    try {
      return _pendingReceived.firstWhere(
        (f) => f.senderId == userId && f.addresseeId == _currentUid,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> loadFriends() async {
    debugPrint('loadFriends called');
    _friendsState = LoadingState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _friends = await FriendService.getFriends();
      for (final f in friends) {
        debugPrint('Friend: ${f.friendId}, Name: ${f.fullName}, Avatar: ${f.avatar}');
      }
      _friendsState = LoadingState.success;
    } catch (e) {
      debugPrint('loadFriends error: $e');
      _friendsState = LoadingState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

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
      _requestsState = LoadingState.success;
    } catch (e) {
      debugPrint('loadRequests error: $e');
      _requestsState = LoadingState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadAll() async {
    await Future.wait([loadFriends(), loadRequests()]);
  }
  // =========================================================
  // REALTIME START
  // =========================================================

  Future<void> startRealtime() async {
    if (_hubSub != null) return;

    await _hub.connect();

    _hubSub = _hub.events.listen((event) {
      debugPrint('PROVIDER RECEIVED EVENT');

      debugPrint(event.type.toString());

      debugPrint(event.friendship.senderId);

      debugPrint(event.friendship.addresseeId);

      _handleHubEvent(event);
    });
  }

  // =========================================================
  // HANDLE REALTIME EVENT
  // =========================================================

  Future<void> _handleHubEvent(FriendRealtimeEvent event) async {
    switch (event.type) {
      // =====================================================
      // REQUEST RECEIVED
      // =====================================================

      case FriendHubEvent.friendRequestReceived:

        // mình là người nhận
        if (event.friendship.addresseeId == _currentUid) {
          // final exists = _pendingReceived.any(
          //   (f) => f.id == event.friendship.id,
          // );
          final exists = _pendingReceived.any(
            (f) =>
                f.senderId == event.friendship.senderId &&
                f.addresseeId == event.friendship.addresseeId,
          );
          if (!exists) {
            _pendingReceived = [event.friendship, ..._pendingReceived];
          }
        }

        // mình là người gửi
        if (event.friendship.senderId == _currentUid) {
          // final exists = _pendingSent.any(
          //   (f) => f.id == event.friendship.id,
          // );
          final exists = _pendingSent.any(
            (f) =>
                f.senderId == event.friendship.senderId &&
                f.addresseeId == event.friendship.addresseeId,
          );
          if (!exists) {
            _pendingSent = [event.friendship, ..._pendingSent];
          }
        }

        notifyListeners();

        break;

      // =====================================================
      // REQUEST ACCEPTED
      // =====================================================

      case FriendHubEvent.friendRequestAccepted:
        _pendingSent.removeWhere(
          (f) =>
              f.senderId == event.friendship.senderId &&
              f.addresseeId == event.friendship.addresseeId,
        );

        _pendingReceived.removeWhere((f) => f.id == event.friendship.id);

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
          (f) =>
              f.senderId == event.friendship.senderId &&
              f.addresseeId == event.friendship.addresseeId,
        );

        _pendingReceived.removeWhere((f) => f.id == event.friendship.id);

        notifyListeners();

        onRealtimeNotify?.call('❌ Lời mời kết bạn đã bị từ chối');

        break;

      // =====================================================
      // REQUEST CANCELLED (sender huỷ lời mời đã gửi cho mình)
      // =====================================================

      case FriendHubEvent.friendRequestCancelled:
        _pendingReceived.removeWhere(
          (f) =>
              f.senderId == event.friendship.senderId &&
              f.addresseeId == event.friendship.addresseeId,
        );

        notifyListeners();
        break;

      // =====================================================
      // UNFRIENDED (bị bên kia unfriend)
      // =====================================================

      case FriendHubEvent.friendUnfriended:
        _friends.removeWhere(
          (f) =>
              f.friendId == event.friendship.senderId ||
              f.friendId == event.friendship.addresseeId,
        );

        notifyListeners();

        onRealtimeNotify?.call('Đã bị xoá khỏi danh sách bạn bè');

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
      _searchResults = await FriendService.searchUsers(query.trim());

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
  Future<UserSearchModel?> findUserByEmail(String email) async {
    try {
      final results = await FriendService.searchUsers(email);
      if (results.isEmpty) return null;
      return results.first;
    } catch (e) {
      debugPrint('findUserByEmail error: $e');
      return null;
    }
  }

  Future<void> sendFriendRequest(String addresseeId) async {
    _actionLoading[addresseeId] = true;
    notifyListeners();
    try {
      final result = await FriendService.sendRequest(addresseeId: addresseeId);
      if (result.status == 'pending') {
        _pendingSent.add(result);
      }
      notifyListeners();
    } finally {
      _actionLoading[addresseeId] = false;
      notifyListeners();
    }
  }

  Future<void> acceptFriendRequest(String senderId) async {
    _actionLoading[senderId] = true;
    notifyListeners();
    try {
      final request = getReceivedRequest(senderId);
      if (request == null) return;
      await FriendService.respondRequest(friendshipId: request.id, accept: true);
      _pendingReceived.removeWhere((f) => f.senderId == senderId);
      await loadFriends();
      notifyListeners();
    } finally {
      _actionLoading[senderId] = false;
      notifyListeners();
    }
  }

  Future<void> declineFriendRequest(String senderId) async {
    _actionLoading[senderId] = true;
    notifyListeners();
    try {
      final request = getReceivedRequest(senderId);
      if (request == null) return;
      await FriendService.respondRequest(friendshipId: request.id, accept: false);
      _pendingReceived.removeWhere((f) => f.senderId == senderId);
      notifyListeners();
    } finally {
      _actionLoading[senderId] = false;
      notifyListeners();
    }
  }

  Future<void> cancelFriendRequest(String addresseeId) async {
    try {
      final request = getSentRequest(addresseeId);
      if (request == null) return;
      await FriendService.cancelRequest(request.id);
      _pendingSent.removeWhere((f) => f.addresseeId == addresseeId);
      notifyListeners();
    } catch (e) {
      debugPrint('cancelFriendRequest error: $e');
    }
  }

  Future<void> loadFriendBirthdays() async {
    _friendBirthdays
      ..clear()
      ..addEntries(
        _friends.map(
          (friend) => MapEntry(friend.friendId, null),
        ),
      );
    notifyListeners();
  }

  Future<void> disposeRealtime() async {
    await _hubSub?.cancel();
    _hubSub = null;
    _hub.dispose();
  }



  void clear() {
    _friends = [];
    _pendingReceived = [];
    _pendingSent = [];
    _searchResults = [];
    _friendsState = LoadingState.idle;
    _requestsState = LoadingState.idle;
    _searchState = LoadingState.idle;
  }

  @override
  void dispose() {
    _hubSub?.cancel();
    _hub.dispose();
    super.dispose();
  }
}
