import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/extensions/datetime_extension.dart';
import '../../../../core/extensions/context_extension.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../providers/report_provider.dart';
import '../../../feeds/presentation/providers/feed_provider.dart';
import '../../../users/presentation/providers/user_provider.dart';

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
                      _InfoItem(label: 'Report ID', value: report.id),
                      _InfoItem(label: 'Reporter ID', value: report.reporterId),
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

              // // Reporter Details
              // _UserProfileCard(
              //   userId: report.reporterId,
              //   title: 'Reporter Details (Thông tin người gửi báo cáo)',
              // ),
              // const SizedBox(height: 16),

              // Target Detail Card
              if (report.targetType == 'post') ...[
                SectionCard(
                  title: 'Reported Content (Post)',
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _ReportedFeedContent(feedId: report.targetId),
                  ),
                ),
                const SizedBox(height: 16),
                _FeedAuthorCard(feedId: report.targetId),
                const SizedBox(height: 16),
              ] else if (report.targetType == 'user') ...[
                _UserProfileCard(
                  userId: report.targetId,
                  title: 'Reported User Details (Thông tin người bị báo cáo)',
                ),
                const SizedBox(height: 16),
              ],

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
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary, height: 1.6),
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
                                  message: 'Mark this report as resolved?',
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
                                  message: 'Mark this report as rejected?',
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

class _ReportedFeedContent extends ConsumerWidget {
  final String feedId;
  const _ReportedFeedContent({required this.feedId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedDetailStreamProvider(feedId));

    return feedAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Text(
        'Error loading feed: $e',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
      ),
      data: (feed) {
        if (feed == null) {
          return Text(
            'Feed not found or has been deleted.',
            style: AppTextStyles.bodyMedium,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (feed.caption.isNotEmpty) ...[
              SelectableText(
                feed.caption,
                style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
              ),
              const SizedBox(height: 16),
            ],
            if (feed.media.isNotEmpty)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: feed.media.map((item) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.url,
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 150,
                          height: 150,
                          color: AppColors.surface,
                          child: const Icon(
                            Icons.broken_image,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }
}

class _UserProfileCard extends ConsumerWidget {
  final String userId;
  final String title;

  const _UserProfileCard({required this.userId, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDetailStreamProvider(userId));

    return SectionCard(
      title: title,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: userAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (e, _) => Text(
            'Error loading user info: $e',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
          ),
          data: (user) {
            if (user == null) {
              return Text(
                'User not found (ID: $userId)',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryContainer,
                  backgroundImage:
                      user.avatar.isNotEmpty ? NetworkImage(user.avatar) : null,
                  child: user.avatar.isEmpty
                      ? Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : '?',
                          style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            user.displayName,
                            style: AppTextStyles.bodyLarge
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge.fromString(
                              user.isActive ? 'active' : 'banned'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Email: ${user.email.isNotEmpty ? user.email : "N/A"}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      SelectableText(
                        'User ID: ${user.id}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMuted),
                      ),
                      if (user.bio.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Bio: ${user.bio}',
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FeedAuthorCard extends ConsumerWidget {
  final String feedId;
  const _FeedAuthorCard({required this.feedId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedDetailStreamProvider(feedId));

    return feedAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (feed) {
        if (feed == null || feed.userId.isEmpty) return const SizedBox.shrink();
        return _UserProfileCard(
          userId: feed.userId,
          title: 'Post Author Details (Thông tin người đăng bài)',
        );
      },
    );
  }
}
