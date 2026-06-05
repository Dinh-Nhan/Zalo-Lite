import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

// ============================================================
// SHARED - Top Bar
// ============================================================

class AppTopbar extends ConsumerWidget {
  final VoidCallback? onMenuTap;

  const AppTopbar({super.key, this.onMenuTap});

  String _getTitle(String location) {
    if (location == '/') return 'Dashboard';
    if (location.startsWith('/users')) return 'User Management';
    if (location.startsWith('/feeds')) return 'Feed Management';
    if (location.startsWith('/hidden-posts')) return 'Hidden Posts';
    if (location.startsWith('/friendships')) return 'Friendships';
    if (location.startsWith('/reports')) return 'Reports & Moderation';
    return 'Admin';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final title = _getTitle(location);

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Menu toggle
          if (onMenuTap != null)
            IconButton(
              onPressed: onMenuTap,
              icon: const Icon(Icons.menu_rounded),
              color: AppColors.textSecondary,
              tooltip: 'Toggle sidebar',
            ),

          // Page Title
          Text(title, style: AppTextStyles.h2),

          const Spacer(),

          // Search shortcut
          _SearchButton(),

          const SizedBox(width: 8),

          // Notifications
          _NotificationButton(),

          const SizedBox(width: 8),

          // Admin Menu
          _AdminMenu(ref: ref),
        ],
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Global search',
      child: InkWell(
        onTap: () {}, // TODO: global search
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded,
                  size: 16, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Text('Search...', style: AppTextStyles.bodySmall),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('⌘K', style: AppTextStyles.caption),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Badge(
      label: const Text('3'),
      backgroundColor: AppColors.error,
      child: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.notifications_outlined),
        color: AppColors.textSecondary,
        tooltip: 'Notifications',
      ),
    );
  }
}

class _AdminMenu extends StatelessWidget {
  final WidgetRef ref;
  const _AdminMenu({required this.ref});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      tooltip: 'Admin menu',
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surfaceElevated,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin',
                    style: AppTextStyles.labelLarge.copyWith(fontSize: 13)),
                Text('admin@gmail.com',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          child: Row(
            children: [
              const Icon(Icons.logout_rounded,
                  size: 16, color: AppColors.error),
              const SizedBox(width: 10),
              Text('Sign out',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.error)),
            ],
          ),
          onTap: () {
            ref.read(authNotifierProvider.notifier).signOut();
          },
        ),
      ],
    );
  }
}
