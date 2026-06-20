import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/extensions/context_extension.dart';
import 'sidebar.dart';
import 'topbar.dart';

// ============================================================
// SHARED - Admin Scaffold (Shell Layout)
// ============================================================

class AdminScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const AdminScaffold({super.key, required this.child});

  @override
  ConsumerState<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends ConsumerState<AdminScaffold> {
  bool _sidebarCollapsed = false;

  static const double _sidebarWidth = 240;
  static const double _sidebarCollapsedWidth = 72;

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: AppColors.sidebar,
              child: AppSidebar(collapsed: false),
            ),
      body: Row(
        children: [
          // Sidebar (desktop only)
          if (isDesktop)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width:
                  _sidebarCollapsed ? _sidebarCollapsedWidth : _sidebarWidth,
              child: AppSidebar(
                collapsed: _sidebarCollapsed,
                onToggle: () =>
                    setState(() => _sidebarCollapsed = !_sidebarCollapsed),
              ),
            ),

          // Main content
          Expanded(
            child: Column(
              children: [
                AppTopbar(
                  onMenuTap: isDesktop
                      ? () => setState(
                          () => _sidebarCollapsed = !_sidebarCollapsed)
                      : () => Scaffold.of(context).openDrawer(),
                ),
                Expanded(
                  child: ClipRect(
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
