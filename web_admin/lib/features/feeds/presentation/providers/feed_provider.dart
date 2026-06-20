import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/feed_repository_impl.dart';
import '../../domain/models/admin_feed.dart';
import '../../domain/feed_repository.dart';

final feedTypeFilterProvider = StateProvider<String?>((ref) => null);
final feedPrivacyFilterProvider = StateProvider<String?>((ref) => null);

/// null = all, true = enabled only (default), false = disabled only
final feedEnabledFilterProvider = StateProvider<bool?>((ref) => true);

final feedsStreamProvider = StreamProvider<List<AdminFeed>>((ref) {
  final repo = ref.watch(feedRepositoryProvider);
  final type = ref.watch(feedTypeFilterProvider);
  final privacy = ref.watch(feedPrivacyFilterProvider);
  final enabledFilter = ref.watch(feedEnabledFilterProvider);
  return repo.watchFeeds(
    typeFilter: type,
    privacyFilter: privacy,
    enabledFilter: enabledFilter,
  );
});

final feedDetailStreamProvider =
    StreamProvider.family<AdminFeed?, String>((ref, feedId) {
  return ref.watch(feedRepositoryProvider).watchFeed(feedId);
});

final recentFeedsStreamProvider = StreamProvider<List<AdminFeed>>((ref) {
  return ref.watch(feedRepositoryProvider).watchRecentFeeds();
});

class FeedActionNotifier extends StateNotifier<AsyncValue<void>> {
  final FeedRepository _repo;

  FeedActionNotifier(this._repo) : super(const AsyncData(null));

  Future<void> disableFeed(String feedId) async {
    state = const AsyncLoading();
    try {
      await _repo.disableFeed(feedId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> enableFeed(String feedId) async {
    state = const AsyncLoading();
    try {
      await _repo.enableFeed(feedId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final feedActionNotifierProvider =
    StateNotifierProvider<FeedActionNotifier, AsyncValue<void>>((ref) {
  return FeedActionNotifier(ref.watch(feedRepositoryProvider));
});
