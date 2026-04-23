import 'package:flutter/material.dart';

class RippleAnimation extends StatefulWidget {
  final Widget child;
  const RippleAnimation({super.key, required this.child});

  @override
  State<RippleAnimation> createState() => _RippleAnimationState();
}

class _RippleAnimationState extends State<RippleAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Thời gian một vòng sóng
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Tạo ra 3 lớp sóng với độ trễ khác nhau
              _buildRipple(0.0), // Sóng 1
              _buildRipple(0.5), // Sóng 2 (trễ 1/3 chu kỳ)
              // _buildRipple(0.66), // Sóng 3 (trễ 2/3 chu kỳ)
              
              // Widget gốc (Avatar) nằm trên cùng
              widget.child,
            ],
          );
        },
      ),
    );
  }

  Widget _buildRipple(double delay) {
    // Tính toán giá trị progress (từ 0.0 đến 1.0) dựa trên delay
    double progress = (_controller.value + delay) % 1.0;

    return Opacity(
      // Sóng mờ dần khi to ra (từ 0.3 về 0.0)
      opacity: (0.3 * (1 - progress)),
      child: Transform.scale(
        // Sóng to dần từ 1.0 lên 2.2 lần kích thước gốc
        scale: 1.0 + (progress * 0.6),
        child: Container(
          width: 110,
          height: 110,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}