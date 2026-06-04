import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/user_repository_impl.dart';
import '../../domain/models/admin_user.dart';
import '../../domain/user_repository.dart';

// ============================================================
// USERS FEATURE - Manual Providers (no code generation)
// ============================================================

/// Search query state
final userSearchQueryProvider = StateProvider<String>((ref) => '');

/// Status filter state ('active' | 'banned' | null)
final userStatusFilterProvider = StateProvider<String?>((ref) => null);

/// Stream of users list
final usersStreamProvider = StreamProvider<List<AdminUser>>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  final search = ref.watch(userSearchQueryProvider);
  final filter = ref.watch(userStatusFilterProvider);
  return repo.watchUsers(
    searchQuery: search.isEmpty ? null : search,
    statusFilter: filter,
  );
});

/// Single user stream by ID
final userDetailStreamProvider =
    StreamProvider.family<AdminUser?, String>((ref, userId) {
  return ref.watch(userRepositoryProvider).watchUser(userId);
});

/// New users for dashboard
final newUsersStreamProvider = StreamProvider<List<AdminUser>>((ref) {
  return ref.watch(userRepositoryProvider).watchNewUsers();
});

/// User action notifier
class UserActionNotifier extends StateNotifier<AsyncValue<void>> {
  final UserRepository _repo;

  UserActionNotifier(this._repo) : super(const AsyncData(null));

  Future<void> banUser(String userId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.banUser(userId));
  }

  Future<void> unbanUser(String userId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.unbanUser(userId));
  }

  Future<void> deleteUser(String userId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.deleteUser(userId));
  }
}

final userActionNotifierProvider =
    StateNotifierProvider<UserActionNotifier, AsyncValue<void>>((ref) {
  return UserActionNotifier(ref.watch(userRepositoryProvider));
});
