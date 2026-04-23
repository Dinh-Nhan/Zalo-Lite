import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/app/app_locale.dart';
import 'package:frontend/common/widget/primary_button.dart';
import 'package:frontend/common/widget/secondary_button.dart';
import 'package:go_router/go_router.dart';
import '../../common/config/app_colors.dart';
import '../../utils/app_localizations.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  // === Ngôn ngữ ===
  String _selectedLanguage = AppLocalizations(localeNotifier.value).displayName;
  // late AppLocalizations _t;
  final t = AppLocalizations(localeNotifier.value);
  // === Animation controllers ===
  late AnimationController _contentController;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoSlideAnimation;
  late Animation<double> _buttonsFadeAnimation;
  late Animation<double> _buttonsSlideAnimation;
  late Animation<double> _languageFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Khởi tạo ngôn ngữ mặc định
    // _\t = AppLocalizations('vi');

    // Đặt status bar cho nền trắng
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _initAnimations();
    _contentController.forward();
  }

  /// Khởi tạo animation: các phần tử xuất hiện tuần tự
  void _initAnimations() {
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Dropdown ngôn ngữ xuất hiện đầu tiên
    _languageFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Logo "Zalo" fade in + slide từ trên xuống
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
      ),
    );
    _logoSlideAnimation = Tween<double>(begin: -30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Buttons fade in + slide từ dưới lên
    _buttonsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );
    _buttonsSlideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
      ),
    );
  }

  /// Xử lý khi đổi ngôn ngữ
  void _onLanguageChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedLanguage = value;
        // _t = AppLocalizations(AppLocalizations.localeFromDisplayName(value));
        localeNotifier.value =
        AppLocalizations.localeFromDisplayName(value);
      });
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

 @override
Widget build(BuildContext context) {
  return ValueListenableBuilder(
    valueListenable: localeNotifier,
    builder: (context, locale, _) {
      final t = AppLocalizations(locale);

      return AnimatedBuilder(
        animation: _contentController,
        builder: (context, child) {
          return Scaffold(
            backgroundColor: AppColors.backgroundWhite,
            body: SafeArea(
              child: Column(
                children: [
                  _buildLanguageSelector(),
                  Expanded(child: _buildLogo(t)),
                  _buildButtons(t),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  /// Mở bottom sheet chọn ngôn ngữ
  void _showLanguageBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              // Thanh kéo nhỏ ở trên cùng
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Tiêu đề
              const Text(
                'Chọn ngôn ngữ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              // Danh sách ngôn ngữ
              ...AppLocalizations.supportedLanguages.map((lang) {
                final isSelected = lang == _selectedLanguage;
                return ListTile(
                  title: Text(
                    lang,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primaryBlue
                          : AppColors.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.primaryBlue)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    _onLanguageChanged(lang);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Nút chọn ngôn ngữ ở góc phải trên — ấn vào mở bottom sheet
  Widget _buildLanguageSelector() {
    return Opacity(
      opacity: _languageFadeAnimation.value,
      child: Padding(
        padding: const EdgeInsets.only(top: 12, right: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: _showLanguageBottomSheet,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.borderGray,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedLanguage,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Logo "Zalo" lớn màu xanh ở giữa màn hình
  Widget _buildLogo(AppLocalizations t) {
    return Opacity(
      opacity: _logoFadeAnimation.value,
      child: Transform.translate(
        offset: Offset(0, _logoSlideAnimation.value),
        child: Center(
          child: Text(
            // _t.get('appName'),
            t.get('appName'),
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
              letterSpacing: 1,
              shadows: [
                Shadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Các nút Đăng nhập và Tạo tài khoản mới — text tự đổi theo ngôn ngữ
  Widget _buildButtons(AppLocalizations t) {
    return Opacity(
      opacity: _buttonsFadeAnimation.value,
      child: Transform.translate(
        offset: Offset(0, _buttonsSlideAnimation.value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // === Nút ĐĂNG NHẬP (xanh, bo tròn) ===
              PrimaryButton(
                text: t.get('login'),
                onPressed: () {
                  context.go('/login');
                },
              ),

              const SizedBox(height: 14),

              // === Nút TẠO TÀI KHOẢN MỚI (viền xám, nền trắng) ===
              SecondaryButton(
                text: t.get('createAccount'),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
