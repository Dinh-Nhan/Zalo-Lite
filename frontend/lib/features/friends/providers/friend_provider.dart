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
  final String _searchQuery = '';
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

  void startRealtime() {
    _hubSub?.cancel();
    _hubSub = _hub.events.listen(_handleHubEvent);
    _hub.connect();
  }

  void _handleHubEvent(FriendRealtimeEvent event) {
    switch (event.type) {
      case FriendHubEvent.friendRequestReceived:
        _pendingReceived.insert(0, event.friendship);
        notifyListeners();
        break;
      case FriendHubEvent.friendRequestAccepted:
        _pendingSent.removeWhere((f) => f.addresseeId == event.friendship.addresseeId);
        loadFriends();
        break;
      case FriendHubEvent.friendRequestDeclined:
        _pendingSent.removeWhere((f) => f.addresseeId == event.friendship.addresseeId);
        notifyListeners();
        break;
    }
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
