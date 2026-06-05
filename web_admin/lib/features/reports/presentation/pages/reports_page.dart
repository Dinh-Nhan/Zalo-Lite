import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/extensions/datetime_extension.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../providers/report_provider.dart';
import '../../domain/models/admin_report.dart';

// ============================================================
// REPORTS PAGE
// ============================================================

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsStreamProvider);
    final statusFilter = ref.watch(reportStatusFilterProvider);
    final targetFilter = ref.watch(reportTargetFilterProvider);

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reports & Moderation', style: AppTextStyles.displayMedium),
          const SizedBox(height: 4),
          reportsAsync.when(
            data: (List<AdminReport> r) => Text(
                '${r.where((x) => x.isPending).length} pending · ${r.length} total',
                style: AppTextStyles.bodySmall),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),

          // Filters
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              // Status filters
              _Chip(
                label: 'All',
                isSelected: statusFilter == null,
                onTap: () =>
                    ref.read(reportStatusFilterProvider.notifier).state = null,
              ),
              _Chip(
                label: 'Pending',
                isSelected: statusFilter == 'pending',
                color: AppColors.warning,
                onTap: () => ref
                    .read(reportStatusFilterProvider.notifier)
                    .state = 'pending',
              ),
              _Chip(
                label: 'Resolved',
                isSelected: statusFilter == 'resolved',
                color: AppColors.success,
                onTap: () => ref
                    .read(reportStatusFilterProvider.notifier)
                    .state = 'resolved',
              ),
              _Chip(
                label: 'Rejected',
                isSelected: statusFilter == 'rejected',
                color: AppColors.error,
                onTap: () => ref
                    .read(reportStatusFilterProvider.notifier)
                    .state = 'rejected',
              ),
              const VerticalDivider(width: 20),
              _Chip(
                label: 'All Targets',
                isSelected: targetFilter == null,
                onTap: () =>
                    ref.read(reportTargetFilterProvider.notifier).state = null,
              ),
              _Chip(
                label: 'Users',
                isSelected: targetFilter == 'user',
                onTap: () => ref
                    .read(reportTargetFilterProvider.notifier)
                    .state = 'user',
              ),
              _Chip(
                label: 'Posts',
                isSelected: targetFilter == 'post',
                onTap: () => ref
                    .read(reportTargetFilterProvider.notifier)
                    .state = 'post',
              ),
            ],
          ),
          const SizedBox(height: 16),

          SectionCard(
            child: reportsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(60),
                child: AppLoadingWidget(message: 'Loading reports...'),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(40),
                child: AppErrorWidget(message: e.toString()),
              ),
              data: (reports) {
                if (reports.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(60),
                    child: AppEmptyWidget(
                      title: 'No reports found',
                      subtitle: 'No reports match the current filter.',
                      icon: Icons.flag_outlined,
                    ),
                  );
                }
                return _ReportTable(reports: reports);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTable extends ConsumerWidget {
  final List<AdminReport> reports;
  const _ReportTable({required this.reports});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(100),
          1: FixedColumnWidth(120),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(1.5),
          4: FixedColumnWidth(110),
          5: FixedColumnWidth(200),
          6: FixedColumnWidth(120),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(color: AppColors.surfaceVariant),
            children: [
              _th('Target'),
              _th('Type'),
              _th('Target ID'),
              _th('Reason'),
              _th('Status'),
              _th('Reported'),
              _th('Actions'),
            ],
          ),
          ...reports.asMap().entries.map((e) {
            final i = e.key;
            final r = e.value;
            return TableRow(
              decoration: BoxDecoration(
                color: r.isPending
                    ? AppColors.warningContainer.withOpacity(0.2)
                    : i.isEven
                        ? AppColors.surface
                        : AppColors.surfaceVariant.withOpacity(0.3),
              ),
              children: [
                _td(Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: r.targetType == 'user'
                        ? AppColors.primaryContainer
                        : AppColors.infoContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    r.targetType.toUpperCase(),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: r.targetType == 'user'
                          ? AppColors.primary
                          : AppColors.info,
                    ),
                  ),
                )),
                _td(Text(r.reason, style: AppTextStyles.bodySmall)),
                _td(SelectableText(r.targetId, style: AppTextStyles.caption)),
                _td(Text(r.description,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis)),
                _td(StatusBadge.fromString(r.status)),
                _td(Text(r.createdAt.formattedWithTime,
                    style: AppTextStyles.caption)),
                _td(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'View details',
                      child: IconButton(
                        onPressed: () => context.go('/reports/${r.id}'),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                )),
              ],
            );
          }),
        ],
      ),
    );
  }

  static Widget _th(String label) => TableCell(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(label, style: AppTextStyles.labelMedium),
        ),
      );

  static Widget _td(Widget child) => TableCell(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: child,
        ),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? c.withOpacity(0.15) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? c : AppColors.border),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? c : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
