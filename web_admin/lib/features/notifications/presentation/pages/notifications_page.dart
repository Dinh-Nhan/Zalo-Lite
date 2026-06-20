import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/extensions/datetime_extension.dart';
import '../../../../core/extensions/context_extension.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../providers/notification_provider.dart';
import '../../domain/models/admin_notification.dart';

// ============================================================
// NOTIFICATIONS PAGE
// ============================================================

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsStreamProvider);
    final statusFilter = ref.watch(notifStatusFilterProvider);

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notification Management',
                      style: AppTextStyles.displayMedium),
                  Text('Send push notifications to users',
                      style: AppTextStyles.bodySmall),
                ],
              ),
              FilledButton.icon(
                onPressed: () => context.go('/notifications/new'),
                icon: const Icon(Icons.add_alert_rounded, size: 18),
                label: const Text('New Notification'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Status Filters
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'All',
                isSelected: statusFilter == null,
                onTap: () => ref
                    .read(notifStatusFilterProvider.notifier)
                    .state = null,
              ),
              _FilterChip(
                label: 'Sent',
                isSelected: statusFilter == 'sent',
                color: AppColors.success,
                onTap: () => ref
                    .read(notifStatusFilterProvider.notifier)
                    .state = 'sent',
              ),
              _FilterChip(
                label: 'Scheduled',
                isSelected: statusFilter == 'scheduled',
                color: AppColors.info,
                onTap: () => ref
                    .read(notifStatusFilterProvider.notifier)
                    .state = 'scheduled',
              ),
              _FilterChip(
                label: 'Draft',
                isSelected: statusFilter == 'draft',
                color: AppColors.textMuted,
                onTap: () => ref
                    .read(notifStatusFilterProvider.notifier)
                    .state = 'draft',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Table
          SectionCard(
            child: notifsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(60),
                child: AppLoadingWidget(message: 'Loading notifications...'),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(40),
                child: AppErrorWidget(message: e.toString()),
              ),
              data: (notifs) {
                if (notifs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(60),
                    child: AppEmptyWidget(
                      title: 'No notifications yet',
                      subtitle: 'Create a notification to send to users.',
                      icon: Icons.notifications_outlined,
                    ),
                  );
                }
                return _NotifTable(notifs: notifs);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Notification Table ───────────────────────────────────────

class _NotifTable extends ConsumerWidget {
  final List<AdminNotification> notifs;
  const _NotifTable({required this.notifs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.5),
          1: FlexColumnWidth(2),
          2: FixedColumnWidth(100),
          3: FixedColumnWidth(100),
          4: FixedColumnWidth(140),
          5: FixedColumnWidth(100),
        },
        children: [
          TableRow(
            decoration:
                const BoxDecoration(color: AppColors.surfaceVariant),
            children: [
              _th('Title'),
              _th('Body'),
              _th('Audience'),
              _th('Status'),
              _th('Date'),
              _th('Actions'),
            ],
          ),
          ...notifs.asMap().entries.map((e) {
            final i = e.key;
            final n = e.value;
            return TableRow(
              decoration: BoxDecoration(
                color: i.isEven
                    ? AppColors.surface
                    : AppColors.surfaceVariant.withOpacity(0.3),
              ),
              children: [
                _td(Text(n.title,
                    style: AppTextStyles.labelMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis)),
                _td(Text(n.body,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis)),
                _td(_AudienceBadge(audience: n.targetAudience)),
                _td(StatusBadge.fromString(n.status)),
                _td(Text(
                  n.isSent
                      ? (n.sentAt?.dateOnly ?? '—')
                      : n.isScheduled
                          ? (n.scheduledAt != null
                              ? DateFormat('dd/MM/yy HH:mm')
                                  .format(n.scheduledAt!)
                              : '—')
                          : n.createdAt.dateOnly,
                  style: AppTextStyles.caption,
                )),
                _td(IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    final confirmed = await ConfirmDialog.show(
                      context,
                      title: 'Delete Notification',
                      message: 'Delete "${n.title}"?',
                      confirmLabel: 'Delete',
                      isDanger: true,
                    );
                    if (confirmed == true) {
                      await ref
                          .read(notificationActionNotifierProvider.notifier)
                          .delete(n.id);
                      if (context.mounted) {
                        context.showSnackBar('Deleted', isSuccess: true);
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  color: AppColors.error,
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

class _AudienceBadge extends StatelessWidget {
  final String audience;
  const _AudienceBadge({required this.audience});

  @override
  Widget build(BuildContext context) {
    final isAll = audience == 'all';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isAll ? AppColors.primaryContainer : AppColors.infoContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isAll ? 'ALL' : 'USER',
        style: AppTextStyles.labelSmall.copyWith(
          color: isAll ? AppColors.primary : AppColors.info,
        ),
      ),
    );
  }
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
