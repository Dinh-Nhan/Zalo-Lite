import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/apps/app_locale.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/utils/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';

/// Màn hình nhập mã xác thực OTP
/// Hiển thị 6 ô nhập OTP, đếm ngược gửi lại, nút Tiếp tục
class OtpVerifyView extends StatefulWidget {
  final String email;

  const OtpVerifyView({super.key, required this.email});

  @override
  State<OtpVerifyView> createState() => _OtpVerifyViewState();
}

class _OtpVerifyViewState extends State<OtpVerifyView> {
  // === OTP Input ===
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  // === State ===
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  String? _errorMessage;

  // === Countdown ===
  int _countdown = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _startCountdown();

    // Tự động gọi gửi OTP khi vừa vào trang
    AuthService.sendOtp(widget.email).catchError((e) {
      setState(() => _errorMessage = e.toString());
    });
  }

  // ================= COUNTDOWN =================

  void _startCountdown() {
    _countdown = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 0) {
        timer.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  // ================= STATE =================

  void _updateButtonState() {
    final otp = _otpControllers.map((c) => c.text).join();
    setState(() {
      _isButtonEnabled = otp.length == 6;
      _errorMessage = null; // Xóa lỗi khi user nhập lại
    });
  }

  // ================= ACTION =================

  void _onOtpChanged(int index, String value) {
    if (value.isEmpty) return;

    // Nếu paste chuỗi dài (vd: 123456)
    if (value.length > 1) {
      String cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanValue.length > 6) cleanValue = cleanValue.substring(0, 6);

      for (int i = 0; i < cleanValue.length; i++) {
        if (index + i < 6) {
          _otpControllers[index + i].text = cleanValue[i];
        }
      }
      
      // Focus vào ô cuối cùng sau khi điền
      int lastFilledIndex = (index + cleanValue.length - 1).clamp(0, 5);
      _focusNodes[lastFilledIndex].requestFocus();
    } else {
      // Nhập thủ công 1 số -> nhảy sang ô kế tiếp
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      }
    }
    _updateButtonState();
  }

  // --- LOGIC XỬ LÝ PHÍM XÓA (BACKSPACE) ---
  void _handleKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_otpControllers[index].text.isEmpty && index > 0) {
        // Nếu ô hiện tại đang trống mà nhấn xóa -> về ô trước và xóa số đó
        _otpControllers[index - 1].clear();
        _focusNodes[index - 1].requestFocus();
        _updateButtonState();
      }
    }
  }

  void _onOtpKeyDown(int index, RawKeyEvent event) {
    // Khi nhấn Backspace ở ô trống → quay lại ô trước
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _otpControllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _otpControllers[index - 1].clear();
      _updateButtonState();
    }
  }

  Future<void> _onContinuePressed() async {
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != 6) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Gọi API Verify từ AuthService
      bool isValid = await AuthService.verifyOtp(widget.email, otp);

      if (isValid) {
        _showSuccessDialog(); // Nếu đúng, hiện thông báo thành công
      } else {
        setState(() => _errorMessage = "Mã xác thực không chính xác.");
      }
    } catch (e) {
      // Nếu sai mã hoặc lỗi mạng, API sẽ trả về lỗi và hiển thị tại đây
      setState(() => _errorMessage = e.toString().replaceAll("Exception: ", ""));
      
      // Tùy chọn: Xóa trắng các ô OTP để user nhập lại nếu sai
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
      _updateButtonState();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // === Hàm gửi lại mã OTP ===
  void _onResendOtp() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.sendOtp(widget.email);
      _startCountdown();
      
      // Clear input cũ
      for (final controller in _otpControllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
      _updateButtonState();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mã OTP mới đã được gửi!")),
      );
    } catch (e) {
      setState(() => _errorMessage = "Không thể gửi lại mã. Vui lòng thử lại.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onBackPressed() async {
    context.pop(); 
  }

  void _showSuccessDialog() {
    final t = AppLocalizations(localeNotifier.value);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            Text(
              t.get('otpSuccess'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Navigator.pop(context);
              // Navigate đến trang tin nhắn sau khi xác thực thành công
              context.push('/reset-password', extra: widget.email); // Truyền email vào trang reset-password
              // Navigator.pushReplacementNamed(context, '/reset-password');
            },
            child: Text(t.get('continue_')),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        final t = AppLocalizations(locale);
        return Scaffold(
          backgroundColor: AppColors.backgroundWhite,
          appBar: _buildAppBar(),
          body: SafeArea(
            child: Column(
              children: [
                SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildTitle(t),
                        const SizedBox(height: 32),
                        _buildOtpFields(),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          _buildErrorMessage(),
                        ],
                      ],
                    ),
                  ),
                SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildContinueButton(t),
                      const SizedBox(height: 24),
                      _buildResendRow(t),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.backgroundWhite,
      elevation: 0,
      leading: IconButton(
        onPressed: _onBackPressed,
        icon: const Icon(Icons.arrow_back_outlined,
            size: 20, color: AppColors.textPrimary),
      ),
    );
  }

  /// Tiêu đề + mô tả
  Widget _buildTitle(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            t.get('otpTitle'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              children: [
                TextSpan(text: t.get('otpDesc')),
                TextSpan(
                  text: ' ${widget.email}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpFields() {
    return Row(
      // Thay đổi sang center để các ô chụm vào giữa
      mainAxisAlignment: MainAxisAlignment.center, 
      children: List.generate(6, (index) {
        return Container(
          // Thêm margin hoặc dùng SizedBox để tạo khoảng cách nhỏ (vd: 8px)
          margin: const EdgeInsets.symmetric(horizontal: 8), 
          width: 45, // Giảm nhẹ chiều rộng để khít hơn nếu cần
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) => _handleKeyEvent(index, event),
            child: TextFormField(
              controller: _otpControllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) => _onOtpChanged(index, value),
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: AppColors.backgroundGray,
                // Giảm padding nội bộ để số nằm chính giữa ô
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8), // Bo góc nhẹ lại cho thanh thoát
                  borderSide: const BorderSide(color: AppColors.borderGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
  /// Thông báo lỗi
  Widget _buildErrorMessage() {
    return Text(
      _errorMessage!,
      style: const TextStyle(
        color: Colors.red,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Nút Tiếp tục
  Widget _buildContinueButton(AppLocalizations t) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        // onPressed: (_isButtonEnabled && !_isLoading) ? () => context.go('/reset-password') : _onContinuePressed,
        onPressed: (_isButtonEnabled && !_isLoading) ? _onContinuePressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isButtonEnabled
              ? AppColors.primaryBlue
              : Colors.grey.shade300,
          foregroundColor: Colors.white,
          elevation: _isButtonEnabled ? 2 : 0,
          shadowColor: AppColors.primaryBlue.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                t.get('continue_'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  /// Dòng "Bạn không nhận được mã? Gửi lại (XXs)"
  Widget _buildResendRow(AppLocalizations t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          t.get('otpNotReceived'),
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: _canResend ? _onResendOtp : null,
          child: Text(
            _canResend
                ? t.get('otpResend')
                : '${t.get('otpResend')} (${_countdown}s)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _canResend
                  ? AppColors.primaryBlue
                  : AppColors.textHint,
            ),
          ),
        ),
      ],
    );
  }
}
