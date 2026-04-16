import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/apps/app_locale.dart';
import 'package:frontend/utils/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';

/// Màn hình nhập mã xác thực OTP
/// Hiển thị 6 ô nhập OTP, đếm ngược gửi lại, nút Tiếp tục
class OtpVerifyView extends StatefulWidget {
  final String phone;

  const OtpVerifyView({super.key, required this.phone});

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

    // TODO: [Backend] Gọi API gửi OTP đến số điện thoại widget.phone
    // Ví dụ: AuthService.sendOtp(widget.phone);
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
    if (value.length == 1 && index < 5) {
      // Tự động chuyển sang ô tiếp theo
      _focusNodes[index + 1].requestFocus();
    }
    _updateButtonState();
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

  void _onContinuePressed() {
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != 6) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // TODO: [Backend] Gọi API xác thực OTP
    // Ví dụ:
    // try {
    //   final result = await AuthService.verifyOtp(widget.phone, otp);
    //   if (result.success) {
    //     context.go('/home'); // hoặc trang tiếp theo
    //   } else {
    //     setState(() {
    //       _errorMessage = t.get('otpInvalid');
    //       _isLoading = false;
    //     });
    //   }
    // } catch (e) {
    //   setState(() {
    //     _errorMessage = t.get('otpError');
    //     _isLoading = false;
    //   });
    // }

    // ========================================================
    // NOTE cho Backend Team:
    // Cần implement API xác thực OTP với logic sau:
    // - Endpoint: POST /api/auth/verify-otp
    // - Input: { phone: String, otp: String }
    // - Output: { success: bool, token?: String, message?: String }
    // - Logic: Kiểm tra OTP có đúng với mã đã gửi cho SĐT này không
    // - Xử lý các trường hợp: OTP sai, OTP hết hạn, OTP đúng
    // ========================================================

    // === Tạm thời: Giả lập xác thực (Frontend only - XÓA khi có backend) ===
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _isLoading = false);

      // TEMPORARY: Chấp nhận bất kỳ mã OTP nào để test frontend
      // Backend cần replace logic này bằng API verify-otp thực sự
      if (otp.length == 6) {
        // TODO: [Backend] Navigate đến trang phù hợp sau khi xác thực thành công
        // context.go('/home');
        _showSuccessDialog();
      } else {
        setState(() {
          _errorMessage =
              AppLocalizations(localeNotifier.value).get('otpInvalid');
        });
      }
    });
  }

  void _onResendOtp() {
    if (!_canResend) return;

    // TODO: [Backend] Gọi API gửi lại OTP
    // Ví dụ: AuthService.sendOtp(widget.phone);

    _startCountdown();

    // Xóa OTP cũ
    for (final controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
    _updateButtonState();
  }

  void _onBackPressed() {
    context.go('/login');
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
              Navigator.pop(context);
              // Navigate đến trang tin nhắn sau khi xác thực thành công
              context.go('/chat-list');
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
                Expanded(
                  child: SingleChildScrollView(
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
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildContinueButton(t),
                      const SizedBox(height: 16),
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
        icon: const Icon(Icons.arrow_back_ios,
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
              fontSize: 22,
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
                  text: ' ${widget.phone}',
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

  /// 6 ô nhập OTP
  Widget _buildOtpFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: tính kích thước ô theo chiều rộng
        final maxWidth = constraints.maxWidth;
        final spacing = maxWidth > 400 ? 12.0 : 8.0;
        final boxSize = ((maxWidth - spacing * 5) / 6).clamp(40.0, 56.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final hasError = _errorMessage != null;
            return Container(
              width: boxSize,
              height: boxSize * 1.15,
              margin: EdgeInsets.symmetric(horizontal: spacing / 2),
              child: RawKeyboardListener(
                focusNode: FocusNode(),
                onKey: (event) => _onOtpKeyDown(index, event),
                child: TextFormField(
                  controller: _otpControllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: TextStyle(
                    fontSize: boxSize * 0.45,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(1),
                  ],
                  onChanged: (value) => _onOtpChanged(index, value),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: hasError
                        ? Colors.red.withValues(alpha: 0.04)
                        : AppColors.backgroundGray,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: boxSize * 0.25,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: hasError
                            ? Colors.red.withValues(alpha: 0.3)
                            : AppColors.borderGray,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color:
                            hasError ? Colors.red : AppColors.primaryBlue,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
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
