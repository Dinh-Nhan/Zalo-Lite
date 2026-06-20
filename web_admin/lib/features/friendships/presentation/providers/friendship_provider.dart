import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/friendship_repository_impl.dart';
import '../../domain/models/admin_friendship.dart';
import '../../domain/friendship_repository.dart';

final friendshipStatusFilterProvider = StateProvider<String?>((ref) => null);
final friendshipSearchQueryProvider = StateProvider<String>((ref) => '');

final friendshipsStreamProvider = StreamProvider<List<AdminFriendship>>((ref) {
  final repo = ref.watch(friendshipRepositoryProvider);
  final status = ref.watch(friendshipStatusFilterProvider);
  final search = ref.watch(friendshipSearchQueryProvider);
  return repo.watchFriendships(
    statusFilter: status,
    searchQuery: search.isEmpty ? null : search,
  );
});

class FriendshipActionNotifier extends StateNotifier<AsyncValue<void>> {
  final FriendshipRepository _repo;
  FriendshipActionNotifier(this._repo) : super(const AsyncData(null));

  Future<void> delete(String docId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.deleteFriendship(docId));
  }
}

final friendshipActionNotifierProvider =
    StateNotifierProvider<FriendshipActionNotifier, AsyncValue<void>>((ref) {
  return FriendshipActionNotifier(ref.watch(friendshipRepositoryProvider));
});
