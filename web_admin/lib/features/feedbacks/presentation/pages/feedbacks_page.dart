import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/extensions/datetime_extension.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../providers/feedback_provider.dart';
import '../../domain/models/admin_feedback.dart';

// ============================================================
// FEEDBACKS PAGE
// ============================================================

class FeedbacksPage extends ConsumerWidget {
  const FeedbacksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbacksAsync = ref.watch(feedbacksStreamProvider);
    final statusFilter = ref.watch(feedbackStatusFilterProvider);

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Feedback Management', style: AppTextStyles.displayMedium),
          const SizedBox(height: 4),
          feedbacksAsync.when(
            data: (list) => Text(
              '${list.where((f) => f.isOpen).length} open · ${list.length} total',
              style: AppTextStyles.bodySmall,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),

          // Filters
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'All',
                isSelected: statusFilter == null,
                onTap: () =>
                    ref.read(feedbackStatusFilterProvider.notifier).state =
                        null,
              ),
              _FilterChip(
                label: 'Open',
                isSelected: statusFilter == 'open',
                color: AppColors.warning,
                onTap: () =>
                    ref.read(feedbackStatusFilterProvider.notifier).state =
                        'open',
              ),
              _FilterChip(
                label: 'Resolved',
                isSelected: statusFilter == 'resolved',
                color: AppColors.success,
                onTap: () =>
                    ref.read(feedbackStatusFilterProvider.notifier).state =
                        'resolved',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Table
          SectionCard(
            child: feedbacksAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(60),
                child: AppLoadingWidget(message: 'Loading feedback...'),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(40),
                child: AppErrorWidget(message: e.toString()),
              ),
              data: (feedbacks) {
                if (feedbacks.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(60),
                    child: AppEmptyWidget(
                      title: 'No feedback found',
                      subtitle: 'User feedback will appear here.',
                      icon: Icons.feedback_outlined,
                    ),
                  );
                }
                return _FeedbackTable(feedbacks: feedbacks);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feedback Table ───────────────────────────────────────────

class _FeedbackTable extends StatelessWidget {
  final List<AdminFeedback> feedbacks;
  const _FeedbackTable({required this.feedbacks});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(2),
          2: FixedColumnWidth(90),
          3: FixedColumnWidth(140),
          4: FixedColumnWidth(120),
        },
        children: [
          TableRow(
            decoration:
                const BoxDecoration(color: AppColors.surfaceVariant),
            children: [
              _th('User'),
              _th('Subject'),
              _th('Status'),
              _th('Received'),
              _th('Actions'),
            ],
          ),
          ...feedbacks.asMap().entries.map((e) {
            final i = e.key;
            final fb = e.value;
            return TableRow(
              decoration: BoxDecoration(
                color: fb.isOpen
                    ? AppColors.warningContainer.withOpacity(0.12)
                    : i.isEven
                        ? AppColors.surface
                        : AppColors.surfaceVariant.withOpacity(0.3),
              ),
              children: [
                _td(Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primaryContainer,
                      backgroundImage: fb.userAvatar.isNotEmpty
                          ? NetworkImage(fb.userAvatar)
                          : null,
                      child: fb.userAvatar.isEmpty
                          ? Text(
                              fb.userDisplayName.isNotEmpty
                                  ? fb.userDisplayName[0].toUpperCase()
                                  : '?',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.primary),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(fb.userDisplayName,
                          style: AppTextStyles.labelMedium,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                )),
                _td(Text(fb.subject,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis)),
                _td(StatusBadge.fromString(fb.status)),
                _td(Text(fb.createdAt.dateOnly,
                    style: AppTextStyles.caption)),
                _td(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'View & Reply',
                      child: IconButton(
                        onPressed: () =>
                            context.go('/feedbacks/${fb.id}'),
                        icon: const Icon(Icons.reply_rounded, size: 18),
                        color: AppColors.primary,
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

// ─── Filter Chip ──────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
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
