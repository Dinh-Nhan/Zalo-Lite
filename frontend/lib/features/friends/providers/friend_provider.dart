import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/friend_hub_service.dart';
import '../services/friend_service.dart';

/// Trạng thái của một thao tác async
enum LoadingState { idle, loading, success, error }

/// Provider quản lý toàn bộ state liên quan đến kết bạn.
/// Tích hợp realtime qua SignalR FriendHub.
class FriendProvider extends ChangeNotifier {
  // ── State ─────────────────────────────────────────────────────
  List<FriendSummaryModel> _friends = [];
  List<FriendshipModel> _pendingReceived = [];
  List<FriendshipModel> _pendingSent = [];
  List<UserSearchModel> _searchResults = [];

  LoadingState _friendsState = LoadingState.idle;
  LoadingState _requestsState = LoadingState.idle;
  LoadingState _searchState = LoadingState.idle;

  /// Map<userId, actionLoading> — theo dõi từng nút đang xử lý
  final Map<String, bool> _actionLoading = {};

  String? _errorMessage;
  String _searchQuery = '';

  // Snackbar callback — được gán bởi widget khi cần notify realtime
  void Function(String message, {bool isSuccess})? onRealtimeNotify;

  // ── Realtime hub ───────────────────────────────────────────────
  final FriendHubService _hub = FriendHubService();
  StreamSubscription<FriendRealtimeEvent>? _hubSub;

  // ── Getters ───────────────────────────────────────────────────
  List<FriendSummaryModel> get friends => List.unmodifiable(_friends);
  List<FriendshipModel> get pendingReceived =>
      List.unmodifiable(_pendingReceived);
  List<FriendshipModel> get pendingSent => List.unmodifiable(_pendingSent);
  List<UserSearchModel> get searchResults => List.unmodifiable(_searchResults);

  LoadingState get friendsState => _friendsState;
  LoadingState get requestsState => _requestsState;
  LoadingState get searchState => _searchState;

  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  int get pendingReceivedCount => _pendingReceived.length;

  bool isActionLoading(String userId) => _actionLoading[userId] ?? false;

  /// Kiểm tra xem userId có phải bạn bè không
  bool isFriend(String userId) => _friends.any((f) => f.friendId == userId);

  /// Lấy friendship đã gửi đến userId (nếu có)
  FriendshipModel? getSentRequest(String userId) {
    try {
      return _pendingSent.firstWhere((f) => f.addresseeId == userId);
    } catch (_) {
      return null;
    }
  }

  /// Lấy friendship đã nhận từ userId (nếu có)
  FriendshipModel? getReceivedRequest(String userId) {
    try {
      return _pendingReceived.firstWhere((f) => f.senderId == userId);
    } catch (_) {
      return null;
    }
  }

  // ── Load data ─────────────────────────────────────────────────

  /// Tải danh sách bạn bè
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

  /// Tải lời mời kết bạn (nhận + đã gửi)
  Future<void> loadRequests() async {
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
      _requestsState = LoadingState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Tải tất cả dữ liệu (gọi khi mở màn hình lần đầu)
  Future<void> loadAll() async {
    await Future.wait([loadFriends(), loadRequests()]);
  }

  // ── Realtime ──────────────────────────────────────────────────

  /// Khởi tạo kết nối SignalR. Gọi một lần sau khi Provider được tạo.
  Future<void> startRealtime() async {
    if (_hubSub != null) return; // đã connect

    await _hub.connect();

    _hubSub = _hub.events.listen(_handleHubEvent);
    debugPrint('[FriendProvider] Realtime started');
  }

  void _handleHubEvent(FriendRealtimeEvent event) {
    switch (event.type) {
      case FriendHubEvent.friendRequestReceived:
        // Thêm vào pending received nếu chưa có
        final exists = _pendingReceived.any((f) => f.id == event.friendship.id);
        if (!exists) {
          _pendingReceived = [event.friendship, ..._pendingReceived];
          notifyListeners();

          final name =
              event.friendship.senderName?.isNotEmpty == true
                  ? event.friendship.senderName!
                  : 'Ai đó';
          onRealtimeNotify?.call('📩 $name đã gửi lời mời kết bạn');
        }

      case FriendHubEvent.friendRequestAccepted:
        // Xoá khỏi pendingSent + reload friends
        _pendingSent.removeWhere((f) => f.id == event.friendship.id);
        notifyListeners();
        loadFriends(); // async — reload danh sách bạn bè
        onRealtimeNotify?.call(
          '✅ Lời mời kết bạn đã được chấp nhận!',
          isSuccess: true,
        );

      case FriendHubEvent.friendRequestDeclined:
        // Xoá khỏi pendingSent
        _pendingSent.removeWhere((f) => f.id == event.friendship.id);
        notifyListeners();
        onRealtimeNotify?.call('❌ Lời mời kết bạn đã bị từ chối');
    }
  }

  // ── Search ────────────────────────────────────────────────────

  /// Tìm kiếm người dùng
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

  // ── Actions ───────────────────────────────────────────────────

  /// Gửi lời mời kết bạn
  Future<void> sendFriendRequest(String targetUserId) async {
    _setActionLoading(targetUserId, true);

    try {
      final friendship = await FriendService.sendRequest(
        addresseeId: targetUserId,
        sourceType: 'search',
      );
      _pendingSent.add(friendship);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setActionLoading(targetUserId, false);
    }
  }

  /// Huỷ lời mời đã gửi
  Future<void> cancelFriendRequest(String targetUserId) async {
    final friendship = getSentRequest(targetUserId);
    if (friendship == null) return;

    _setActionLoading(targetUserId, true);

    try {
      await FriendService.cancelRequest(friendship.id);
      _pendingSent.removeWhere((f) => f.id == friendship.id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setActionLoading(targetUserId, false);
    }
  }

  /// Chấp nhận lời mời kết bạn
  Future<void> acceptFriendRequest(String senderId) async {
    final friendship = getReceivedRequest(senderId);
    if (friendship == null) return;

    _setActionLoading(senderId, true);

    try {
      await FriendService.respondRequest(
        friendshipId: friendship.id,
        accept: true,
      );
      _pendingReceived.removeWhere((f) => f.id == friendship.id);
      // Reload friends list để cập nhật
      await loadFriends();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setActionLoading(senderId, false);
    }
  }

  /// Từ chối lời mời kết bạn
  Future<void> declineFriendRequest(String senderId) async {
    final friendship = getReceivedRequest(senderId);
    if (friendship == null) return;

    _setActionLoading(senderId, true);

    try {
      await FriendService.respondRequest(
        friendshipId: friendship.id,
        accept: false,
      );
      _pendingReceived.removeWhere((f) => f.id == friendship.id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setActionLoading(senderId, false);
    }
  }

  /// Huỷ kết bạn
  Future<void> unfriend(String targetUserId) async {
    _setActionLoading(targetUserId, true);

    try {
      await FriendService.unfriend(targetUserId);
      _friends.removeWhere((f) => f.friendId == targetUserId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setActionLoading(targetUserId, false);
    }
  }

  // ── Private helpers ───────────────────────────────────────────
  void _setActionLoading(String userId, bool value) {
    _actionLoading[userId] = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _hubSub?.cancel();
    _hub.dispose();
    super.dispose();
  }
}
