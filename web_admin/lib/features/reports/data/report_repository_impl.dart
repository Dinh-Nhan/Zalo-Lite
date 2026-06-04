import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/models/admin_report.dart';
import '../domain/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  final FirebaseFirestore _db;
  ReportRepositoryImpl(this._db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.reportsCollection);

  @override
  Stream<List<AdminReport>> watchReports({
    String? statusFilter,
    String? targetTypeFilter,
    int limit = 20,
  }) {
    Query<Map<String, dynamic>> query =
        _col.orderBy('created_at', descending: true);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }
    if (targetTypeFilter != null) {
      query = query.where('target_type', isEqualTo: targetTypeFilter);
    }

    query = query.limit(limit);

    return query.snapshots().map(
        (snap) => snap.docs.map(AdminReport.fromFirestore).toList());
  }

  @override
  Stream<AdminReport?> watchReport(String reportId) {
    return _col.doc(reportId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AdminReport.fromFirestore(snap);
    });
  }

  @override
  Future<void> resolveReport(String reportId, String adminNote) async {
    try {
      await _col.doc(reportId).update({
        'status': AppConstants.reportResolved,
        'admin_note': adminNote,
        'resolved_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to resolve report');
    }
  }

  @override
  Future<void> rejectReport(String reportId, String adminNote) async {
    try {
      await _col.doc(reportId).update({
        'status': AppConstants.reportRejected,
        'admin_note': adminNote,
        'resolved_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to reject report');
    }
  }

  @override
  Future<int> getPendingReportCount() async {
    final snap = await _col
        .where('status', isEqualTo: AppConstants.reportPending)
        .count()
        .get();
    return snap.count ?? 0;
  }
}

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepositoryImpl(FirebaseFirestore.instance);
});
