import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_colors.dart';
import 'package:go_router/go_router.dart';
/// Màn hình splash (loading) - Hiển thị logo Zalo trên nền xanh
/// Tự động chuyển sang HomeView sau 5 giây với hiệu ứng chuyển cảnh mượt mà
class LoadView extends StatefulWidget {
  const LoadView({super.key});

  @override
  State<LoadView> createState() => _LoadViewState();
}

class _LoadViewState extends State<LoadView> with TickerProviderStateMixin {
  // Animation cho logo Zalo (fade + scale)
  late AnimationController _logoController;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;

  // Animation cho hiệu ứng glow (ánh sáng lung linh)
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Animation cho hiệu ứng chuyển cảnh ra (transition out)
  late AnimationController _transitionController;
  late Animation<double> _transitionFadeAnimation;
  late Animation<double> _transitionScaleAnimation;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Ẩn thanh trạng thái để hiển thị full screen
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _initAnimations();
    _startAnimations();
  }

  /// Khởi tạo tất cả animation controllers và animations
  void _initAnimations() {
    // === Logo Animation: fade in + scale lên (0 → 1.2s) ===
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    // === Glow Animation: hiệu ứng sáng lung linh lặp lại ===
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // === Transition Out: fade out + zoom ra khi chuyển cảnh ===
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _transitionFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: Curves.easeInOut,
      ),
    );
    _transitionScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: Curves.easeIn,
      ),
    );
  }

  /// Khởi chạy chuỗi animation theo timeline (tổng ~5 giây)
  void _startAnimations() async {
    // Đợi 1 chút trước khi bắt đầu
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // 1. Logo fade in + scale lên
    _logoController.forward();

    // 2. Bắt đầu hiệu ứng glow sau khi logo hiện
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _glowController.repeat(reverse: true);

    // 3. Sau tổng cộng ~5 giây, dừng glow và bắt đầu chuyển cảnh
    //    Tổng: 300ms chờ + 800ms logo + 3100ms glow = ~4200ms
    //    800ms transition → tổng ~5 giây
    await Future.delayed(const Duration(milliseconds: 3100));
    if (!mounted) return;
    _glowController.stop();

    // 4. Chạy hiệu ứng transition out
    await _transitionController.forward();
    if (!mounted || _navigated) return;

    // 5. Chuyển sang HomeView với hiệu ứng mượt mà
    _navigated = true;
    
    context.go('/');
  }

  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _logoController,
        _glowController,
        _transitionController,
      ]),
      builder: (context, child) {
        // Tính màu nền chuyển dần từ xanh → trắng khi transition
        final bgColor = Color.lerp(
          AppColors.primaryBlue,
          Colors.white,
          _transitionController.value,
        )!;
        final bgColorDark = Color.lerp(
          AppColors.darkBlue,
          Colors.white,
          _transitionController.value,
        )!;

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bgColor, bgColorDark],
              ),
            ),
            child: Center(
              child: Opacity(
                opacity: _transitionFadeAnimation.value,
                child: Transform.scale(
                  scale: _transitionScaleAnimation.value,
                  child: Opacity(
                    opacity: _logoFadeAnimation.value,
                    child: Transform.scale(
                      scale: _logoScaleAnimation.value,
                      child: _buildLogo(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Xây dựng logo Zalo chữ trắng lớn, với hiệu ứng glow
  Widget _buildLogo() {
    final glowOpacity = 0.3 + (_glowAnimation.value * 0.4);
    final glowBlur = 20.0 + (_glowAnimation.value * 30.0);

    return Text(
      'Zalo',
      style: TextStyle(
        fontSize: 72,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 2,
        shadows: [
          // Glow pulsating chính
          Shadow(
            color: Colors.white.withValues(alpha: glowOpacity.clamp(0.0, 1.0)),
            blurRadius: glowBlur,
          ),
          // Shadow nhẹ phía dưới
          const Shadow(
            color: Colors.white24,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
