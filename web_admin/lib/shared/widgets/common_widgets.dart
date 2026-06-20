import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

// ============================================================
// SHARED - Loading & Error Widgets
// ============================================================

class AppLoadingWidget extends StatelessWidget {
  final String? message;
  const AppLoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }
}

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text('Something went wrong', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Try Again'),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// SHARED - Empty State Widget
// ============================================================

class AppEmptyWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? action;

  const AppEmptyWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: 24),
            action!,
          ],
        ],
      ),
    );
  }
}

// ============================================================
// SHARED - Confirm Dialog
// ============================================================

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final bool isDanger;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.isDanger = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        isDanger: isDanger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          if (isDanger)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.error, size: 18),
            ),
          if (isDanger) const SizedBox(width: 10),
          Expanded(child: Text(title, style: AppTextStyles.h2)),
        ],
      ),
      content: Text(message, style: AppTextStyles.bodyMedium),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isDanger ? AppColors.error : AppColors.primary,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

// ============================================================
// SHARED - Status Badge
// ============================================================

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  factory StatusBadge.active() => const StatusBadge(
        label: 'Active',
        color: AppColors.success,
        bgColor: AppColors.successContainer,
      );

  factory StatusBadge.banned() => const StatusBadge(
        label: 'Banned',
        color: AppColors.error,
        bgColor: AppColors.errorContainer,
      );

  factory StatusBadge.pending() => const StatusBadge(
        label: 'Pending',
        color: AppColors.warning,
        bgColor: AppColors.warningContainer,
      );

  factory StatusBadge.resolved() => const StatusBadge(
        label: 'Resolved',
        color: AppColors.success,
        bgColor: AppColors.successContainer,
      );

  factory StatusBadge.rejected() => const StatusBadge(
        label: 'Rejected',
        color: AppColors.error,
        bgColor: AppColors.errorContainer,
      );

  factory StatusBadge.fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return StatusBadge.active();
      case 'banned':
      case 'blocked':
        return StatusBadge.banned();
      case 'pending':
        return StatusBadge.pending();
      case 'resolved':
      case 'accepted':
        return StatusBadge.resolved();
      case 'rejected':
      case 'declined':
        return StatusBadge.rejected();
      default:
        return StatusBadge(
          label: status,
          color: AppColors.textSecondary,
          bgColor: AppColors.surfaceVariant,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

// ============================================================
// SHARED - Page Container
// ============================================================

class PageContainer extends StatelessWidget {
  final Widget child;
  const PageContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }
}

// ============================================================
// SHARED - Section Card
// ============================================================

class SectionCard extends StatelessWidget {
  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets? padding;

  const SectionCard({
    super.key,
    this.title,
    this.trailing,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(child: Text(title!, style: AppTextStyles.h3)),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          if (title != null) const SizedBox(height: 16),
          Padding(
            padding: padding ?? const EdgeInsets.fromLTRB(0, 0, 0, 0),
            child: child,
          ),
        ],
      ),
    );
  }
}
