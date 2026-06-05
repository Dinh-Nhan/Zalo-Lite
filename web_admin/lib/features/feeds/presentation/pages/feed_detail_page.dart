import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/extensions/datetime_extension.dart';
import '../../../../core/extensions/context_extension.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../providers/feed_provider.dart';

// ============================================================
// FEED DETAIL PAGE
// ============================================================

class FeedDetailPage extends ConsumerWidget {
  final String feedId;
  const FeedDetailPage({super.key, required this.feedId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedDetailStreamProvider(feedId));
    final notifier = ref.read(feedActionNotifierProvider.notifier);

    return feedAsync.when(
      loading: () =>
          const PageContainer(child: Center(child: AppLoadingWidget())),
      error: (e, _) => PageContainer(child: AppErrorWidget(message: e.toString())),
      data: (feed) {
        if (feed == null) {
          return PageContainer(
            child: AppEmptyWidget(
              title: 'Post not found',
              subtitle: 'This post may have been removed.',
              action: ElevatedButton(
                onPressed: () => context.go('/feeds'),
                child: const Text('Back to Feeds'),
              ),
            ),
          );
        }

        return PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back + Actions
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/feeds'),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text('Post Details', style: AppTextStyles.displayMedium),
                  const Spacer(),
                  // Enable / Disable toggle button
                  if (feed.isDisabled)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success),
                      onPressed: () async {
                        try {
                          await notifier.enableFeed(feed.id);
                          if (context.mounted) {
                            context.showSnackBar('Post enabled',
                                isSuccess: true);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            context.showSnackBar(e.toString(), isError: true);
                          }
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline_rounded,
                          size: 16),
                      label: const Text('Enable'),
                    )
                  else
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error),
                      onPressed: () async {
                        final ok = await ConfirmDialog.show(
                          context,
                          title: 'Disable Post',
                          message:
                              'This post will be hidden from all users. You can re-enable it at any time.',
                          confirmLabel: 'Disable',
                          isDanger: true,
                        );
                        if (ok == true) {
                          try {
                            await notifier.disableFeed(feed.id);
                            if (context.mounted) {
                              context.showSnackBar('Post disabled',
                                  isSuccess: true);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              context.showSnackBar(e.toString(), isError: true);
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.block_rounded, size: 16),
                      label: const Text('Disable'),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Content Card
              SectionCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusBadge.fromString(feed.type),
                          const SizedBox(width: 8),
                          StatusBadge.fromString(feed.privacy),
                          if (feed.isDisabled) ...[
                            const SizedBox(width: 8),
                            StatusBadge.fromString('disabled'),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        feed.caption.isNotEmpty
                            ? feed.caption
                            : '(No caption)',
                        style: AppTextStyles.bodyLarge
                            .copyWith(height: 1.6),
                      ),
                      if (feed.media.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: feed.media.take(4).map((m) {
                            return Container(
                              width: 160,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                                image: m.type == 'image'
                                    ? DecorationImage(
                                        image: NetworkImage(m.url),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: m.type == 'video'
                                  ? const Icon(Icons.play_circle_filled_rounded,
                                      color: AppColors.textSecondary, size: 40)
                                  : null,
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Stats
              SectionCard(
                title: 'Statistics',
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Wrap(
                    spacing: 32,
                    runSpacing: 16,
                    children: [
                      _StatItem(
                          label: 'Likes',
                          value: '${feed.likeCount}',
                          icon: Icons.favorite_rounded,
                          color: AppColors.error),
                      _StatItem(
                          label: 'Views',
                          value: '${feed.viewCount}',
                          icon: Icons.visibility_rounded,
                          color: AppColors.info),
                      _StatItem(
                          label: 'Media',
                          value: '${feed.media.length}',
                          icon: Icons.image_rounded,
                          color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Meta
              SectionCard(
                title: 'Metadata',
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 16,
                    children: [
                      _MetaItem(label: 'Post ID', value: feed.id),
                      _MetaItem(label: 'Author ID', value: feed.userId),
                      _MetaItem(
                          label: 'Created',
                          value: feed.createdAt.formattedWithTime),
                      _MetaItem(
                          label: 'Status',
                          value: feed.isEnabled ? 'Enabled' : 'Disabled'),
                      if (feed.expiresAt != null)
                        _MetaItem(
                            label: 'Expires At',
                            value: feed.expiresAt!.formattedWithTime),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: AppTextStyles.h2
                    .copyWith(color: AppColors.textPrimary)),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;
  const _MetaItem({required this.label, required this.value});

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
