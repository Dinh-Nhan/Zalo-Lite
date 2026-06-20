import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/extensions/datetime_extension.dart';
import '../../../../core/extensions/context_extension.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../providers/user_provider.dart';
import '../../domain/models/admin_user.dart';

// ============================================================
// USERS PAGE - User Management
// ============================================================

class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersStreamProvider);
    final statusFilter = ref.watch(userStatusFilterProvider);

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
                    Text('User Management', style: AppTextStyles.displayMedium),
                    usersAsync.when(
                      data: (users) => Text(
                        '${users.length} users',
                        style: AppTextStyles.bodySmall,
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search + Filter Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchCtrl,
                  style: AppTextStyles.bodyMedium,
                  decoration: const InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon:
                        Icon(Icons.search_rounded, color: AppColors.textMuted),
                  ),
                  onChanged: (v) =>
                      ref.read(userSearchQueryProvider.notifier).state = v,
                ),
              ),
              const SizedBox(width: 12),
              _FilterDropdown(
                value: statusFilter,
                onChanged: (v) =>
                    ref.read(userStatusFilterProvider.notifier).state = v,
                items: const {
                  null: 'All Status',
                  'enabled': 'Enabled',
                  'disabled': 'Disabled',
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Data Table
          SectionCard(
            child: usersAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(60),
                child: AppLoadingWidget(message: 'Loading users...'),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(40),
                child: AppErrorWidget(message: e.toString()),
              ),
              data: (users) {
                if (users.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(60),
                    child: AppEmptyWidget(
                      title: 'No users found',
                      subtitle:
                          'Try adjusting your search or filter criteria',
                      icon: Icons.person_search,
                    ),
                  );
                }
                return _UserTable(users: users);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── User Table ──────────────────────────────────────────────

class _UserTable extends ConsumerWidget {
  final List<AdminUser> users;
  const _UserTable({required this.users});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(2.5),
          2: FixedColumnWidth(100),
          3: FixedColumnWidth(100),
          4: FixedColumnWidth(140),
          5: FixedColumnWidth(140),
        },
        children: [
          // Header
          TableRow(
            decoration: const BoxDecoration(color: AppColors.surfaceVariant),
            children: [
              _th('User'),
              _th('Email'),
              _th('Role'),
              _th('Status'),
              _th('Created'),
              _th('Actions'),
            ],
          ),
          // Data rows
          ...users.asMap().entries.map((entry) {
            final i = entry.key;
            final user = entry.value;
            return TableRow(
              decoration: BoxDecoration(
                color: i.isEven
                    ? AppColors.surface
                    : AppColors.surfaceVariant.withOpacity(0.3),
              ),
              children: [
                // User name + avatar
                _td(
                  InkWell(
                    onTap: () => context.go('/users/${user.id}'),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primaryContainer,
                          backgroundImage: user.avatar.isNotEmpty
                              ? NetworkImage(user.avatar)
                              : null,
                          child: user.avatar.isEmpty
                              ? Text(
                                  user.displayName.isNotEmpty
                                      ? user.displayName[0].toUpperCase()
                                      : '?',
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.primary),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            user.displayName,
                            style: AppTextStyles.labelLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _td(
                  Text(user.email,
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                _td(
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: user.role == 'admin'
                          ? AppColors.primaryContainer
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      user.role.toUpperCase(),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: user.role == 'admin'
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                _td(StatusBadge.fromString(
                    user.isEnable ? 'active' : 'disabled')),
                _td(Text(user.createdAt.dateOnly,
                    style: AppTextStyles.caption)),
                _td(_UserActions(user: user)),
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

// ─── User Action Buttons ──────────────────────────────────────

class _UserActions extends ConsumerWidget {
  final AdminUser user;
  const _UserActions({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(userActionNotifierProvider.notifier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // View detail
        Tooltip(
          message: 'View details',
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
            onPressed: () => context.go('/users/${user.id}'),
            icon: const Icon(Icons.visibility_outlined, size: 18),
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        // Enable / Disable
        Tooltip(
          message: user.isEnable ? 'Disable user' : 'Enable user',
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
            onPressed: () async {
              final confirmed = await ConfirmDialog.show(
                context,
                title: user.isEnable ? 'Disable User' : 'Enable User',
                message: user.isEnable
                    ? 'Disable ${user.displayName}? They will no longer be able to log in.'
                    : 'Enable ${user.displayName}? They will be able to log in again.',
                confirmLabel: user.isEnable ? 'Disable' : 'Enable',
                isDanger: user.isEnable,
              );
              if (confirmed == true) {
                try {
                  if (user.isEnable) {
                    await notifier.disableUser(user.id);
                  } else {
                    await notifier.enableUser(user.id);
                  }
                  if (context.mounted) {
                    context.showSnackBar(
                      user.isEnable ? 'User disabled' : 'User enabled',
                      isSuccess: true,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    context.showSnackBar(e.toString(), isError: true);
                  }
                }
              }
            },
            icon: Icon(
              user.isEnable
                  ? Icons.block_rounded
                  : Icons.check_circle_outline_rounded,
              size: 18,
            ),
            color: user.isEnable ? AppColors.warning : AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        // Delete permanently
        Tooltip(
          message: 'Delete user permanently',
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
            onPressed: () async {
              final confirmed = await ConfirmDialog.show(
                context,
                title: 'Delete User',
                message:
                    'This will permanently delete ${user.displayName}\'s account. This action cannot be undone.',
                confirmLabel: 'Delete',
                isDanger: true,
              );
              if (confirmed == true) {
                await notifier.deleteUser(user.id);
                if (context.mounted) {
                  context.showSnackBar('User deleted', isSuccess: true);
                }
              }
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: AppColors.error,
          ),
        ),
      ],
    );
  }
}

// ─── Filter Dropdown ─────────────────────────────────────────

class _FilterDropdown<T> extends StatelessWidget {
  final T? value;
  final ValueChanged<T?> onChanged;
  final Map<T?, String> items;

  const _FilterDropdown({
    required this.value,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          value: value,
          onChanged: onChanged,
          style: AppTextStyles.bodyMedium,
          dropdownColor: AppColors.surfaceElevated,
          items: items.entries
              .map((e) => DropdownMenuItem<T?>(
                    value: e.key,
                    child: Text(e.value),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
