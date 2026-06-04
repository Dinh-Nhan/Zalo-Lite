import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/extensions/datetime_extension.dart';
import '../../../../core/extensions/context_extension.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../providers/report_provider.dart';

// ============================================================
// REPORT DETAIL PAGE
// ============================================================

class ReportDetailPage extends ConsumerStatefulWidget {
  final String reportId;
  const ReportDetailPage({super.key, required this.reportId});

  @override
  ConsumerState<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends ConsumerState<ReportDetailPage> {
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(reportDetailStreamProvider(widget.reportId));
    final notifier = ref.read(reportActionNotifierProvider.notifier);

    return reportAsync.when(
      loading: () =>
          const PageContainer(child: Center(child: AppLoadingWidget())),
      error: (e, _) =>
          PageContainer(child: AppErrorWidget(message: e.toString())),
      data: (report) {
        if (report == null) {
          return PageContainer(
            child: AppEmptyWidget(
              title: 'Report not found',
              subtitle: 'This report may have been removed.',
              action: ElevatedButton(
                onPressed: () => context.go('/reports'),
                child: const Text('Back to Reports'),
              ),
            ),
          );
        }

        return PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/reports'),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text('Report Details', style: AppTextStyles.displayMedium),
                  const Spacer(),
                  StatusBadge.fromString(report.status),
                ],
              ),
              const SizedBox(height: 24),

              // Report Info Card
              SectionCard(
                title: 'Report Information',
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 16,
                    children: [
                      _InfoItem(
                          label: 'Report ID', value: report.id),
                      _InfoItem(
                          label: 'Reporter ID', value: report.reporterId),
                      _InfoItem(
                          label: 'Target Type',
                          value: report.targetType.toUpperCase()),
                      _InfoItem(label: 'Target ID', value: report.targetId),
                      _InfoItem(label: 'Reason', value: report.reason),
                      _InfoItem(
                          label: 'Submitted',
                          value: report.createdAt.formattedWithTime),
                      if (report.resolvedAt != null)
                        _InfoItem(
                            label: 'Resolved At',
                            value: report.resolvedAt!.formattedWithTime),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              SectionCard(
                title: 'Description',
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    report.description.isNotEmpty
                        ? report.description
                        : '(No description provided)',
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Admin Note (existing)
              if (report.adminNote.isNotEmpty)
                SectionCard(
                  title: 'Admin Note',
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      report.adminNote,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary, height: 1.6),
                    ),
                  ),
                ),
              if (report.adminNote.isNotEmpty) const SizedBox(height: 16),

              // Action Panel (only for pending)
              if (report.isPending) ...[
                SectionCard(
                  title: 'Moderation Action',
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _noteCtrl,
                          style: AppTextStyles.bodyMedium,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText:
                                'Add an admin note (required before resolving or rejecting)...',
                            labelText: 'Admin Note',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success),
                              onPressed: () async {
                                if (_noteCtrl.text.trim().isEmpty) {
                                  context.showSnackBar(
                                    'Please add a note before resolving',
                                    isError: true,
                                  );
                                  return;
                                }
                                final ok = await ConfirmDialog.show(
                                  context,
                                  title: 'Resolve Report',
                                  message:
                                      'Mark this report as resolved?',
                                  confirmLabel: 'Resolve',
                                );
                                if (ok == true) {
                                  await notifier.resolve(
                                      report.id, _noteCtrl.text.trim());
                                  if (context.mounted) {
                                    context.showSnackBar('Report resolved',
                                        isSuccess: true);
                                  }
                                }
                              },
                              icon: const Icon(Icons.check_rounded, size: 16),
                              label: const Text('Resolve'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                              ),
                              onPressed: () async {
                                if (_noteCtrl.text.trim().isEmpty) {
                                  context.showSnackBar(
                                    'Please add a note before rejecting',
                                    isError: true,
                                  );
                                  return;
                                }
                                final ok = await ConfirmDialog.show(
                                  context,
                                  title: 'Reject Report',
                                  message:
                                      'Mark this report as rejected?',
                                  confirmLabel: 'Reject',
                                  isDanger: true,
                                );
                                if (ok == true) {
                                  await notifier.reject(
                                      report.id, _noteCtrl.text.trim());
                                  if (context.mounted) {
                                    context.showSnackBar('Report rejected',
                                        isSuccess: true);
                                  }
                                }
                              },
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: const Text('Reject'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelSmall),
          const SizedBox(height: 4),
          SelectableText(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
