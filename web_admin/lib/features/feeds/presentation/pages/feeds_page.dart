import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/extensions/datetime_extension.dart';
import '../../../../core/extensions/context_extension.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../providers/feed_provider.dart';
import '../../domain/models/admin_feed.dart';

// ============================================================
// FEEDS PAGE - Feed Management
// ============================================================

class FeedsPage extends ConsumerWidget {
  const FeedsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedsAsync = ref.watch(feedsStreamProvider);
    final typeFilter = ref.watch(feedTypeFilterProvider);
    final enabledFilter = ref.watch(feedEnabledFilterProvider);

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Feed Management', style: AppTextStyles.displayMedium),
                    feedsAsync.when(
                      data: (feeds) => Text('${feeds.length} posts',
                          style: AppTextStyles.bodySmall),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filters
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'All Types',
                isSelected: typeFilter == null,
                onTap: () =>
                    ref.read(feedTypeFilterProvider.notifier).state = null,
              ),
              _FilterChip(
                label: 'Posts',
                isSelected: typeFilter == 'post',
                onTap: () =>
                    ref.read(feedTypeFilterProvider.notifier).state = 'post',
              ),
              _FilterChip(
                label: 'Stories',
                isSelected: typeFilter == 'story',
                onTap: () =>
                    ref.read(feedTypeFilterProvider.notifier).state = 'story',
              ),
              const VerticalDivider(width: 20),
              _FilterChip(
                label: 'Enabled',
                isSelected: enabledFilter == true,
                onTap: () =>
                    ref.read(feedEnabledFilterProvider.notifier).state = true,
              ),
              _FilterChip(
                label: 'Disabled',
                isSelected: enabledFilter == false,
                color: AppColors.error,
                onTap: () =>
                    ref.read(feedEnabledFilterProvider.notifier).state = false,
              ),
              _FilterChip(
                label: 'All',
                isSelected: enabledFilter == null,
                onTap: () =>
                    ref.read(feedEnabledFilterProvider.notifier).state = null,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Table
          SectionCard(
            child: feedsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(60),
                child: AppLoadingWidget(message: 'Loading feeds...'),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(40),
                child: AppErrorWidget(message: e.toString()),
              ),
              data: (feeds) {
                if (feeds.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(60),
                    child: AppEmptyWidget(
                      title: 'No posts found',
                      subtitle: 'Try changing the filter',
                      icon: Icons.article_outlined,
                    ),
                  );
                }
                return _FeedTable(feeds: feeds);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedTable extends ConsumerWidget {
  final List<AdminFeed> feeds;
  const _FeedTable({required this.feeds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FixedColumnWidth(80),
          2: FixedColumnWidth(100),
          3: FixedColumnWidth(80),
          4: FixedColumnWidth(80),
          5: FixedColumnWidth(120),
          6: FixedColumnWidth(100),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(color: AppColors.surfaceVariant),
            children: [
              _th('Caption'),
              _th('Type'),
              _th('Privacy'),
              _th('Likes'),
              _th('Views'),
              _th('Created'),
              _th('Actions'),
            ],
          ),
          ...feeds.asMap().entries.map((e) {
            final i = e.key;
            final feed = e.value;
            return TableRow(
              decoration: BoxDecoration(
                color: feed.isDisabled
                    ? AppColors.errorContainer.withOpacity(0.3)
                    : i.isEven
                        ? AppColors.surface
                        : AppColors.surfaceVariant.withOpacity(0.3),
              ),
              children: [
                _td(
                  InkWell(
                    onTap: () => context.go('/feeds/${feed.id}'),
                    child: Row(
                      children: [
                        if (feed.isDisabled) ...[
                          const Icon(Icons.block_rounded,
                              size: 14, color: AppColors.error),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            feed.caption.isNotEmpty
                                ? feed.caption
                                : '(No caption)',
                            style: AppTextStyles.labelLarge.copyWith(
                              color:
                                  feed.isDisabled ? AppColors.textMuted : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _td(Text(feed.type, style: AppTextStyles.bodySmall)),
                _td(StatusBadge.fromString(feed.privacy)),
                _td(Text('${feed.likeCount}', style: AppTextStyles.bodySmall)),
                _td(Text('${feed.viewCount}', style: AppTextStyles.bodySmall)),
                _td(Text(feed.createdAt.dateOnly,
                    style: AppTextStyles.caption)),
                _tdActions(_FeedActions(feed: feed)),
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

  static Widget _tdActions(Widget child) => TableCell(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: child,
        ),
      );
}

class _FeedActions extends ConsumerWidget {
  final AdminFeed feed;
  const _FeedActions({required this.feed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(feedActionNotifierProvider.notifier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // View
        Tooltip(
          message: 'View details',
          child: IconButton(
            onPressed: () => context.go('/feeds/${feed.id}'),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            color: AppColors.textSecondary,
          ),
        ),
        // Toggle enable / disable
        if (feed.isEnabled)
          Tooltip(
            message: 'Disable post',
            child: IconButton(
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
                      context.showSnackBar('Post disabled', isSuccess: true);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      context.showSnackBar(e.toString(), isError: true);
                    }
                  }
                }
              },
              icon: const Icon(Icons.block_rounded, size: 18),
              color: AppColors.warning,
            ),
          )
        else
          Tooltip(
            message: 'Enable post',
            child: IconButton(
              onPressed: () async {
                try {
                  await notifier.enableFeed(feed.id);
                  if (context.mounted) {
                    context.showSnackBar('Post enabled', isSuccess: true);
                  }
                } catch (e) {
                  if (context.mounted) {
                    context.showSnackBar(e.toString(), isError: true);
                  }
                }
              },
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              color: AppColors.success,
            ),
          ),
      ],
    );
  }
}

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
    final activeColor = color ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.15)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? activeColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
