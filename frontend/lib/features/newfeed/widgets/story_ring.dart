import 'package:flutter/material.dart';

class StoryRing extends StatelessWidget {
  final bool hasUnseen;
  final bool isOwner;
  final double size;
  final Widget child;

  const StoryRing({
    super.key,
    required this.hasUnseen,
    required this.isOwner,
    this.size = 58,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final ringColor = isOwner
        ? const Color(0xFFFF9500)
        : hasUnseen
            ? const Color(0xFFE53935)
            : Colors.grey.shade400;

    return Container(
      width: size + 6,
      height: size + 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ringColor.withValues(alpha: 0.9),
            ringColor,
          ],
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(2),
        child: ClipOval(child: child),
      ),
    );
  }
}
