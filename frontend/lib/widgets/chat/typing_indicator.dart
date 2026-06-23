import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar placeholder (cùng width với bubble)
          const SizedBox(width: 28),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(5),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: const Color(0xFFE8E8E8), width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(controller: _ctrl, delay: 0.0),
                const SizedBox(width: 4),
                _Dot(controller: _ctrl, delay: 0.2),
                const SizedBox(width: 4),
                _Dot(controller: _ctrl, delay: 0.4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final AnimationController controller;
  final double delay;

  const _Dot({required this.controller, required this.delay});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        // Bounce: 0→-6→0 theo sine, mỗi chấm lệch phase
        final t = ((controller.value - delay) % 1.0);
        final bounce = t < 0.5
            ? -6.0 * (t * 2) * (1 - t * 2)
            : 0.0;
        return Transform.translate(
          offset: Offset(0, bounce),
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF999999),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
