import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/hidden_post_repository_impl.dart';
import '../../domain/models/hidden_post.dart';
import '../../domain/hidden_post_repository.dart';

final hiddenPostsStreamProvider = StreamProvider<List<HiddenPost>>((ref) {
  return ref.watch(hiddenPostRepositoryProvider).watchHiddenPosts();
});

class HiddenPostActionNotifier extends StateNotifier<AsyncValue<void>> {
  final HiddenPostRepository _repo;
  HiddenPostActionNotifier(this._repo) : super(const AsyncData(null));

  Future<void> restore(String docId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.restoreHiddenPost(docId));
  }

  Future<void> permanentlyDelete(String postId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.permanentlyDeletePost(postId));
  }
}

final hiddenPostActionNotifierProvider =
    StateNotifierProvider<HiddenPostActionNotifier, AsyncValue<void>>((ref) {
  return HiddenPostActionNotifier(ref.watch(hiddenPostRepositoryProvider));
});
