import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/extensions/datetime_extension.dart';
import '../../../../core/extensions/context_extension.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../providers/hidden_post_provider.dart';
import '../../domain/models/hidden_post.dart';

// ============================================================
// HIDDEN POSTS PAGE
// ============================================================

class HiddenPostsPage extends ConsumerWidget {
  const HiddenPostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hiddenAsync = ref.watch(hiddenPostsStreamProvider);

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hidden Posts', style: AppTextStyles.displayMedium),
          const SizedBox(height: 4),
          Text(
            'Posts hidden by users. You can restore visibility or delete them permanently.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 24),
          SectionCard(
            child: hiddenAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(60),
                child: AppLoadingWidget(message: 'Loading hidden posts...'),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(40),
                child: AppErrorWidget(message: e.toString()),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(60),
                    child: AppEmptyWidget(
                      title: 'No hidden posts',
                      subtitle: 'All posts are visible to users.',
                      icon: Icons.visibility_rounded,
                    ),
                  );
                }
                return _HiddenPostTable(items: items);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HiddenPostTable extends ConsumerWidget {
  final List<HiddenPost> items;
  const _HiddenPostTable({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(hiddenPostActionNotifierProvider.notifier);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(2),
          2: FixedColumnWidth(140),
          3: FixedColumnWidth(140),
        },
        children: [
          TableRow(
            decoration:
                const BoxDecoration(color: AppColors.surfaceVariant),
            children: [
              _th('User ID'),
              _th('Post ID'),
              _th('Hidden At'),
              _th('Actions'),
            ],
          ),
          ...items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            return TableRow(
              decoration: BoxDecoration(
                color: i.isEven
                    ? AppColors.surface
                    : AppColors.surfaceVariant.withOpacity(0.3),
              ),
              children: [
                _td(SelectableText(item.viewerId,
                    style: AppTextStyles.bodySmall)),
                _td(SelectableText(item.postId,
                    style: AppTextStyles.bodySmall)),
                _td(Text(item.createdAt.formattedWithTime,
                    style: AppTextStyles.caption)),
                _td(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'Restore (delete hidden record)',
                      child: IconButton(
                        onPressed: () async {
                          final ok = await ConfirmDialog.show(
                            context,
                            title: 'Restore Post',
                            message:
                                'Remove this hidden post record? The post will be visible again for this user.',
                            confirmLabel: 'Restore',
                          );
                          if (ok == true) {
                            await notifier.restore(item.id);
                            if (context.mounted) {
                              context.showSnackBar('Post restored',
                                  isSuccess: true);
                            }
                          }
                        },
                        icon: const Icon(Icons.restore_rounded, size: 18),
                        color: AppColors.success,
                      ),
                    ),
                    Tooltip(
                      message: 'Delete post permanently',
                      child: IconButton(
                        onPressed: () async {
                          final ok = await ConfirmDialog.show(
                            context,
                            title: 'Delete Post Permanently',
                            message:
                                'This will delete the actual post from Firestore. This action cannot be undone.',
                            confirmLabel: 'Delete',
                            isDanger: true,
                          );
                          if (ok == true) {
                            await notifier.permanentlyDelete(item.postId);
                            if (context.mounted) {
                              context.showSnackBar('Post deleted permanently',
                                  isSuccess: true);
                            }
                          }
                        },
                        icon: const Icon(Icons.delete_forever_rounded,
                            size: 18),
                        color: AppColors.error,
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
