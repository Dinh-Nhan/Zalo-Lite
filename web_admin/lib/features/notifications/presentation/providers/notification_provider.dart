import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/notification_repository_impl.dart';
import '../../domain/models/admin_notification.dart';

// ============================================================
// NOTIFICATIONS FEATURE - Providers
// ============================================================

final notifStatusFilterProvider = StateProvider<String?>((ref) => null);

final notificationsStreamProvider =
    StreamProvider<List<AdminNotification>>((ref) {
  final filter = ref.watch(notifStatusFilterProvider);
  return ref
      .watch(notificationRepositoryProvider)
      .watchNotifications(statusFilter: filter);
});

class NotificationActionNotifier extends StateNotifier<AsyncValue<void>> {
  final dynamic _repo;
  NotificationActionNotifier(this._repo) : super(const AsyncData(null));

  Future<void> sendNow({
    required String title,
    required String body,
    required String targetAudience,
    String? targetUserId,
    String createdBy = 'Admin',
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.sendNow(
          title: title,
          body: body,
          targetAudience: targetAudience,
          targetUserId: targetUserId,
          createdBy: createdBy,
        ));
  }

  Future<void> schedule({
    required String title,
    required String body,
    required String targetAudience,
    String? targetUserId,
    required DateTime scheduledAt,
    String createdBy = 'Admin',
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.scheduleNotification(
          title: title,
          body: body,
          targetAudience: targetAudience,
          targetUserId: targetUserId,
          scheduledAt: scheduledAt,
          createdBy: createdBy,
        ));
  }

  Future<void> saveDraft({
    required String title,
    required String body,
    required String targetAudience,
    String? targetUserId,
    String createdBy = 'Admin',
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.saveDraft(
          title: title,
          body: body,
          targetAudience: targetAudience,
          targetUserId: targetUserId,
          createdBy: createdBy,
        ));
  }

  Future<void> delete(String notifId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.deleteNotification(notifId));
  }
}

final notificationActionNotifierProvider =
    StateNotifierProvider<NotificationActionNotifier, AsyncValue<void>>(
        (ref) {
  return NotificationActionNotifier(
      ref.watch(notificationRepositoryProvider));
});
