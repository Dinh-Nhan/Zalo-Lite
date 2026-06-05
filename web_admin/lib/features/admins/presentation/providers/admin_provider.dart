import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_repository_impl.dart';
import '../../domain/models/admin_account.dart';

// ============================================================
// ADMINS FEATURE - Providers
// ============================================================

/// Stream of all admin accounts
final adminsStreamProvider = StreamProvider<List<AdminAccount>>((ref) {
  return ref.watch(adminRepositoryProvider).watchAdmins();
});

/// Notifier for admin CRUD actions
class AdminActionNotifier extends StateNotifier<AsyncValue<void>> {
  final dynamic _repo;
  AdminActionNotifier(this._repo) : super(const AsyncData(null));

  Future<void> createAdmin({
    required String id,
    required String email,
    required String displayName,
    required String role,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.createAdmin(
          id: id,
          email: email,
          displayName: displayName,
          role: role,
        ));
  }

  Future<void> updateAdmin(
    String adminId, {
    String? displayName,
    String? role,
    bool? isActive,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.updateAdmin(
          adminId,
          displayName: displayName,
          role: role,
          isActive: isActive,
        ));
  }

  Future<void> deleteAdmin(String adminId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.deleteAdmin(adminId));
  }

  Future<void> assignRole(String adminId, String role) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.assignRole(adminId, role));
  }
}

final adminActionNotifierProvider =
    StateNotifierProvider<AdminActionNotifier, AsyncValue<void>>((ref) {
  return AdminActionNotifier(ref.watch(adminRepositoryProvider));
});
