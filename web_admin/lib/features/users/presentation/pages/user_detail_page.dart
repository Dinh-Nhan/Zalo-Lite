import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/extensions/datetime_extension.dart';
import '../../../../core/extensions/context_extension.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../providers/user_provider.dart';

// ============================================================
// USER DETAIL PAGE
// ============================================================

class UserDetailPage extends ConsumerWidget {
  final String userId;
  const UserDetailPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDetailStreamProvider(userId));

    return userAsync.when(
      loading: () =>
          const PageContainer(child: Center(child: AppLoadingWidget())),
      error: (e, _) => PageContainer(
          child: AppErrorWidget(
              message: e.toString(), onRetry: () => context.pop())),
      data: (user) {
        if (user == null) {
          return PageContainer(
            child: AppEmptyWidget(
              title: 'User not found',
              subtitle: 'This user may have been deleted.',
              action: ElevatedButton(
                onPressed: () => context.go('/users'),
                child: const Text('Back to Users'),
              ),
            ),
          );
        }

        return PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back + Header
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/users'),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text('User Details', style: AppTextStyles.displayMedium),
                ],
              ),
              const SizedBox(height: 24),

              // Profile Card
              SectionCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primaryContainer,
                        backgroundImage: user.avatar.isNotEmpty
                            ? NetworkImage(user.avatar)
                            : null,
                        child: user.avatar.isEmpty
                            ? Text(
                                user.displayName.isNotEmpty
                                    ? user.displayName[0].toUpperCase()
                                    : '?',
                                style: AppTextStyles.displayMedium
                                    .copyWith(color: AppColors.primary),
                              )
                            : null,
                      ),
                      const SizedBox(width: 24),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(user.displayName,
                                    style: AppTextStyles.h1),
                                const SizedBox(width: 12),
                                StatusBadge.fromString(
                                    user.isActive ? 'active' : 'banned'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(user.email,
                                style: AppTextStyles.bodySmall),
                            const SizedBox(height: 8),
                            if (user.bio.isNotEmpty)
                              Text(user.bio,
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(
                                          color: AppColors.textSecondary)),
                          ],
                        ),
                      ),

                      // Actions
                      _UserDetailActions(userId: user.id, isActive: user.isActive),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Details Grid
              _DetailGrid(items: {
                'User ID': user.id,
                'Role': user.role.toUpperCase(),
                'Email': user.email,
                'Status': user.isActive ? 'Active' : 'Banned',
                'Joined': user.createdAt.formattedWithTime,
                'Last Updated': user.updatedAt.formattedWithTime,
              }),
            ],
          ),
        );
      },
    );
  }
}

class _UserDetailActions extends ConsumerWidget {
  final String userId;
  final bool isActive;
  const _UserDetailActions({required this.userId, required this.isActive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(userActionNotifierProvider.notifier);

    return Column(
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? AppColors.error : AppColors.success,
          ),
          onPressed: () async {
            final confirmed = await ConfirmDialog.show(
              context,
              title: isActive ? 'Ban User' : 'Unban User',
              message: isActive
                  ? 'Ban this user from the platform?'
                  : 'Restore access for this user?',
              confirmLabel: isActive ? 'Ban' : 'Unban',
              isDanger: isActive,
            );
            if (confirmed == true) {
              if (isActive) {
                await notifier.banUser(userId);
              } else {
                await notifier.unbanUser(userId);
              }
              if (context.mounted) {
                context.showSnackBar(
                  isActive ? 'User banned' : 'User unbanned',
                  isSuccess: true,
                );
              }
            }
          },
          icon: Icon(
            isActive ? Icons.block_rounded : Icons.check_circle_rounded,
            size: 16,
          ),
          label: Text(isActive ? 'Ban User' : 'Unban User'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
          onPressed: () async {
            final confirmed = await ConfirmDialog.show(
              context,
              title: 'Delete User',
              message: 'Permanently delete this user? This cannot be undone.',
              confirmLabel: 'Delete',
              isDanger: true,
            );
            if (confirmed == true) {
              await notifier.deleteUser(userId);
              if (context.mounted) {
                context.go('/users');
              }
            }
          },
          icon: const Icon(Icons.delete_rounded, size: 16),
          label: const Text('Delete'),
        ),
      ],
    );
  }
}

class _DetailGrid extends StatelessWidget {
  final Map<String, String> items;
  const _DetailGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Account Details',
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 24,
          runSpacing: 20,
          children: items.entries.map((e) => SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.key, style: AppTextStyles.labelSmall),
                const SizedBox(height: 4),
                Text(e.value,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }
}
