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
      final reportDoc = await _col.doc(reportId).get();
      if (!reportDoc.exists) return;

      final data = reportDoc.data();
      final targetType = data?['target_type'] as String?;
      final targetId = data?['target_id'] as String?;

      final batch = _db.batch();

      batch.update(_col.doc(reportId), {
        'status': AppConstants.reportResolved,
        'admin_note': adminNote,
        'resolved_at': FieldValue.serverTimestamp(),
      });

      if (targetType != null && targetId != null) {
        if (targetType == 'post') {
          batch.update(_db.collection('feeds').doc(targetId), {
            'is_enable': false,
            'moderation_status': 'flagged',
          });
        } else if (targetType == 'user') {
          batch.update(_db.collection('users').doc(targetId), {
            'is_enable': false,
          });
        }
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to resolve report');
    }
  }

  @override
  Future<void> rejectReport(String reportId, String adminNote) async {
    try {
      final reportDoc = await _col.doc(reportId).get();
      if (!reportDoc.exists) return;

      final data = reportDoc.data();
      final targetType = data?['target_type'] as String?;
      final targetId = data?['target_id'] as String?;

      final batch = _db.batch();

      batch.update(_col.doc(reportId), {
        'status': AppConstants.reportRejected,
        'admin_note': adminNote,
        'resolved_at': FieldValue.serverTimestamp(),
      });

      if (targetType != null && targetId != null) {
        if (targetType == 'post') {
          batch.update(_db.collection('feeds').doc(targetId), {
            'is_enable': true,
            'moderation_status': 'approved',
          });
        } else if (targetType == 'user') {
          batch.update(_db.collection('users').doc(targetId), {
            'is_enable': true,
          });
        }
      }

      await batch.commit();
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
