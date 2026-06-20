import 'models/admin_friendship.dart';

abstract interface class FriendshipRepository {
  Stream<List<AdminFriendship>> watchFriendships({
    String? statusFilter,
    String? searchQuery,
    int limit = 20,
  });
  Future<void> deleteFriendship(String docId);
  Future<int> getFriendshipCount();
  Future<int> getAcceptedFriendshipCount();
}
