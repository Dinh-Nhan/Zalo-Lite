import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/report_repository_impl.dart';
import '../../domain/models/admin_report.dart';
import '../../domain/report_repository.dart';

final reportStatusFilterProvider = StateProvider<String?>((ref) => null);
final reportTargetFilterProvider = StateProvider<String?>((ref) => null);

final reportsStreamProvider = StreamProvider<List<AdminReport>>((ref) {
  final repo = ref.watch(reportRepositoryProvider);
  final status = ref.watch(reportStatusFilterProvider);
  final target = ref.watch(reportTargetFilterProvider);
  return repo.watchReports(statusFilter: status, targetTypeFilter: target);
});

final reportDetailStreamProvider =
    StreamProvider.family<AdminReport?, String>((ref, reportId) {
  return ref.watch(reportRepositoryProvider).watchReport(reportId);
});

class ReportActionNotifier extends StateNotifier<AsyncValue<void>> {
  final ReportRepository _repo;
  ReportActionNotifier(this._repo) : super(const AsyncData(null));

  Future<void> resolve(String reportId, String note) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.resolveReport(reportId, note));
  }

  Future<void> reject(String reportId, String note) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.rejectReport(reportId, note));
  }
}

final reportActionNotifierProvider =
    StateNotifierProvider<ReportActionNotifier, AsyncValue<void>>((ref) {
  return ReportActionNotifier(ref.watch(reportRepositoryProvider));
});
