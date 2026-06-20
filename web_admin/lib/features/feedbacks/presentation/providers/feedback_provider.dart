import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/feedback_repository_impl.dart';
import '../../domain/models/admin_feedback.dart';

// ============================================================
// FEEDBACKS FEATURE - Providers
// ============================================================

final feedbackStatusFilterProvider = StateProvider<String?>((ref) => null);

final feedbacksStreamProvider =
    StreamProvider<List<AdminFeedback>>((ref) {
  final filter = ref.watch(feedbackStatusFilterProvider);
  return ref.watch(feedbackRepositoryProvider).watchFeedbacks(
        statusFilter: filter,
      );
});

final feedbackDetailProvider =
    StreamProvider.family<AdminFeedback?, String>((ref, id) {
  return ref.watch(feedbackRepositoryProvider).watchFeedback(id);
});

// Notifier for actions
class FeedbackActionNotifier extends StateNotifier<AsyncValue<void>> {
  final dynamic _repo;
  FeedbackActionNotifier(this._repo) : super(const AsyncData(null));

  Future<void> reply(
    String feedbackId, {
    required String reply,
    required String repliedBy,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.replyFeedback(
          feedbackId,
          reply: reply,
          repliedBy: repliedBy,
        ));
  }

  Future<void> markResolved(String feedbackId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.markResolved(feedbackId));
  }

  Future<void> reopen(String feedbackId) async {
    state = const AsyncLoading();
    state =
        await AsyncValue.guard(() => _repo.reopenFeedback(feedbackId));
  }
}

final feedbackActionNotifierProvider =
    StateNotifierProvider<FeedbackActionNotifier, AsyncValue<void>>((ref) {
  return FeedbackActionNotifier(ref.watch(feedbackRepositoryProvider));
});
