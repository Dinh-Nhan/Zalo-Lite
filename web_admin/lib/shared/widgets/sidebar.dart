import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/router.dart';

// ============================================================
// SHARED - Sidebar (updated with new modules)
// ============================================================

class AppSidebar extends StatelessWidget {
  final bool collapsed;
  final VoidCallback? onToggle;

  const AppSidebar({
    super.key,
    required this.collapsed,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Brand
          _buildBrand(context),
          const Divider(height: 1, color: AppColors.border),

          // Nav Items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!collapsed) _buildSectionLabel('OVERVIEW'),
                  _NavItem(
                    icon: Icons.dashboard_outlined,
                    iconActive: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    path: AppRoutes.dashboard,
                    currentPath: location,
                    collapsed: collapsed,
                  ),

                  if (!collapsed) const SizedBox(height: 8),
                  if (!collapsed) _buildSectionLabel('MANAGEMENT'),
                  _NavItem(
                    icon: Icons.people_outline,
                    iconActive: Icons.people_rounded,
                    label: 'Users',
                    path: AppRoutes.users,
                    currentPath: location,
                    collapsed: collapsed,
                  ),
                  _NavItem(
                    icon: Icons.article_outlined,
                    iconActive: Icons.article_rounded,
                    label: 'Feeds',
                    path: AppRoutes.feeds,
                    currentPath: location,
                    collapsed: collapsed,
                  ),
                  _NavItem(
                    icon: Icons.visibility_off_outlined,
                    iconActive: Icons.visibility_off_rounded,
                    label: 'Hidden Posts',
                    path: AppRoutes.hiddenPosts,
                    currentPath: location,
                    collapsed: collapsed,
                  ),
                  _NavItem(
                    icon: Icons.group_outlined,
                    iconActive: Icons.group_rounded,
                    label: 'Friendships',
                    path: AppRoutes.friendships,
                    currentPath: location,
                    collapsed: collapsed,
                  ),

                  if (!collapsed) const SizedBox(height: 8),
                  if (!collapsed) _buildSectionLabel('ADMIN'),
                  _NavItem(
                    icon: Icons.admin_panel_settings_outlined,
                    iconActive: Icons.admin_panel_settings_rounded,
                    label: 'Admins',
                    path: AppRoutes.admins,
                    currentPath: location,
                    collapsed: collapsed,
                  ),

                  if (!collapsed) const SizedBox(height: 8),
                  if (!collapsed) _buildSectionLabel('MODERATION'),
                  _NavItem(
                    icon: Icons.flag_outlined,
                    iconActive: Icons.flag_rounded,
                    label: 'Reports',
                    path: AppRoutes.reports,
                    currentPath: location,
                    collapsed: collapsed,
                    badgeCount: 0,
                  ),
                  _NavItem(
                    icon: Icons.feedback_outlined,
                    iconActive: Icons.feedback_rounded,
                    label: 'Feedback',
                    path: AppRoutes.feedbacks,
                    currentPath: location,
                    collapsed: collapsed,
                    badgeCount: 0,
                  ),

                  if (!collapsed) const SizedBox(height: 8),
                  if (!collapsed) _buildSectionLabel('COMMUNICATIONS'),
                  _NavItem(
                    icon: Icons.notifications_outlined,
                    iconActive: Icons.notifications_rounded,
                    label: 'Notifications',
                    path: AppRoutes.notifications,
                    currentPath: location,
                    collapsed: collapsed,
                  ),
                ],
              ),
            ),
          ),

          // Collapse toggle (desktop)
          if (onToggle != null) ...[
            const Divider(height: 1, color: AppColors.border),
            _buildCollapseButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildBrand(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 64,
      padding: EdgeInsets.symmetric(
        horizontal: collapsed ? 16 : 20,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield_rounded,
                color: Colors.white, size: 18),
          ),
          if (!collapsed) ...[
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Zalo Lite', style: AppTextStyles.h3),
                Text('Admin',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.primary)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Text(label, style: AppTextStyles.sidebarSection),
    );
  }

  Widget _buildCollapseButton() {
    return InkWell(
      onTap: onToggle,
      child: Container(
        height: 52,
        padding: EdgeInsets.symmetric(horizontal: collapsed ? 20 : 20),
        child: Row(
          mainAxisAlignment:
              collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(
              collapsed
                  ? Icons.chevron_right_rounded
                  : Icons.chevron_left_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
            if (!collapsed) ...[
              const SizedBox(width: 12),
              Text('Collapse', style: AppTextStyles.labelMedium),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Nav Item ──────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData iconActive;
  final String label;
  final String path;
  final String currentPath;
  final bool collapsed;
  final int? badgeCount;

  const _NavItem({
    required this.icon,
    required this.iconActive,
    required this.label,
    required this.path,
    required this.currentPath,
    required this.collapsed,
    this.badgeCount,
  });

  bool get _isActive {
    if (path == '/') return currentPath == '/';
    return currentPath.startsWith(path);
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _isActive;

    final childWidget = collapsed
        ? Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? iconActive : icon,
                  color: isActive ? AppColors.primary : AppColors.textMuted,
                  size: 20,
                ),
                if (badgeCount != null && badgeCount! > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isActive ? iconActive : icon,
                    color: isActive ? AppColors.primary : AppColors.textMuted,
                    size: 20,
                  ),
                  if (badgeCount != null && badgeCount! > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: isActive
                      ? AppTextStyles.sidebarItemActive
                      : AppTextStyles.sidebarItem,
                ),
              ),
            ],
          );

    return Tooltip(
      message: collapsed ? label : '',
      preferBelow: false,
      child: InkWell(
        onTap: () => context.go(path),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? 8 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isActive ? AppColors.sidebarSelected : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? Border.all(color: AppColors.primary.withOpacity(0.3))
                : null,
          ),
          child: childWidget,
        ),
      ),
    );
  }
}
