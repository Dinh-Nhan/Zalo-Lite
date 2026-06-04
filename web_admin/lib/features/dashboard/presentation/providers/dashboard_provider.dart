import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../users/data/user_repository_impl.dart';
import '../../../feeds/data/feed_repository_impl.dart';
import '../../../friendships/data/friendship_repository_impl.dart';

// ============================================================
// DASHBOARD FEATURE - Stats Model
// ============================================================

class DashboardStats {
  final int totalUsers;
  final int totalPosts;
  final int totalFriendships;
  final int totalAccepted;

  const DashboardStats({
    required this.totalUsers,
    required this.totalPosts,
    required this.totalFriendships,
    required this.totalAccepted,
  });
}

// ============================================================
// DASHBOARD FEATURE - Manual Provider
// Cost: 4 AggregateQuery reads only ✅
// ============================================================

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final userRepo = ref.watch(userRepositoryProvider);
  final feedRepo = ref.watch(feedRepositoryProvider);
  final friendRepo = ref.watch(friendshipRepositoryProvider);

  final results = await Future.wait([
    userRepo.getUserCount(),
    feedRepo.getPostCount(),
    friendRepo.getFriendshipCount(),
    friendRepo.getAcceptedFriendshipCount(),
  ]);

  return DashboardStats(
    totalUsers: results[0],
    totalPosts: results[1],
    totalFriendships: results[2],
    totalAccepted: results[3],
  );
});
