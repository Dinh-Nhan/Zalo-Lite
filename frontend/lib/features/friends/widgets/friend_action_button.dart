import 'package:flutter/material.dart';

enum FriendActionStyle { primary, secondary, danger, ghost }

/// Nút hành động chuẩn dùng trong danh sách bạn bè / tìm kiếm.
/// Hỗ trợ loading state và 4 style khác nhau.
class FriendActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading;
  final FriendActionStyle style;
  final double height;
  final double? minWidth;

  const FriendActionButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.isLoading = false,
    this.style = FriendActionStyle.primary,
    this.height = 32,
    this.minWidth,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = _styleConfig();

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: height,
        constraints: BoxConstraints(minWidth: minWidth ?? 0),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: cfg.bg,
          border: cfg.border,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(cfg.fg),
                ),
              )
            else ...[
              if (icon != null) ...[
                Icon(icon, size: 15, color: cfg.fg),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cfg.fg,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _BtnConfig _styleConfig() {
    switch (style) {
      case FriendActionStyle.primary:
        return _BtnConfig(bg: const Color(0xFF0068FF), fg: Colors.white);
      case FriendActionStyle.secondary:
        return _BtnConfig(
          bg: const Color(0xFFEBF2FF),
          fg: const Color(0xFF0068FF),
        );
      case FriendActionStyle.danger:
        return _BtnConfig(
          bg: const Color(0xFFFFEBEB),
          fg: const Color(0xFFE53935),
        );
      case FriendActionStyle.ghost:
        return _BtnConfig(
          bg: Colors.transparent,
          fg: const Color(0xFF666666),
          border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
        );
    }
  }
}

class _BtnConfig {
  final Color bg;
  final Color fg;
  final BoxBorder? border;
  const _BtnConfig({required this.bg, required this.fg, this.border});
}
