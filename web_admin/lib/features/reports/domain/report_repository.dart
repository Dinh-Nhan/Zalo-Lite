import 'models/admin_report.dart';

abstract interface class ReportRepository {
  Stream<List<AdminReport>> watchReports({
    String? statusFilter,
    String? targetTypeFilter,
    int limit = 20,
  });
  Stream<AdminReport?> watchReport(String reportId);
  Future<void> resolveReport(String reportId, String adminNote);
  Future<void> rejectReport(String reportId, String adminNote);
  Future<int> getPendingReportCount();
}
