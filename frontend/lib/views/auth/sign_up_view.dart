import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/apps/app_locale.dart';
import 'package:frontend/component/confirm_phone_sheet.dart'; 
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/services/auth_service.dart'; // Đảm bảo đã import service
import 'package:frontend/utils/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../utils/validator.dart';

class SignUpView extends StatefulWidget {
  final String? initialEmail; // Thêm trường này để nhận email từ OTP nếu có
  const SignUpView({super.key, this.initialEmail});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers & Nodes
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();

  // State logic
  bool _agreeTerms = false;
  bool _agreeSocialPolicy = false;
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Animation
  late AnimationController _shakeCtrl;
  late Animation<Offset> _shakeAnim;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
    _emailController.text = widget.initialEmail!;
  }
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    // Khởi tạo hiệu ứng rung khi có lỗi
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(-0.02, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.02, 0), end: const Offset(0.02, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.02, 0), end: Offset.zero), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _emailController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ================= STATE LOGIC =================

  void _updateButtonState() {
    final t = AppLocalizations(localeNotifier.value);
    
    final isEmailValid = Validator.email(
      _emailController.text, 
      requiredMessage: t.get('validatorRequired'),
      invalidMessage: t.get('validatorEmail'),
    ) == null;

    setState(() {
      _isButtonEnabled = isEmailValid && _agreeTerms && _agreeSocialPolicy;
    });
  }

  void _onAgreeTermsChanged(bool? value) {
    setState(() => _agreeTerms = value ?? false);
    _updateButtonState();
  }

  void _onAgreeSocialPolicyChanged(bool? value) {
    setState(() => _agreeSocialPolicy = value ?? false);
    _updateButtonState();
  }

  // ================= ACTIONS =================

  Future<void> _handleRegister() async {
    // Ẩn bàn phím
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      _shakeCtrl.forward(from: 0);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Gọi register với các thông số mặc định như yêu cầu
      await AuthService.register(
        RegisterRequest(
          email: _emailController.text.trim(),
          password: "Aa@123456",       
          firstName: "User",      
          lastName: "Test",       
          dateOfBirth: "1990-01-01", 
        ),
      );

      if (!mounted) return;
      
      // Nếu không lỗi (email chưa tồn tại), hiện Sheet xác nhận
      _showConfirmSheet();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      _shakeCtrl.forward(from: 0);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onCancelRegistration() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Gọi service xóa dữ liệu tạm
      await AuthService.deleteAccountAndData();

      if (!mounted) return;
      
      // Chuyển hướng về trang chủ/login
      context.go('/'); 
      
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Không thể hủy đăng ký: ${e.toString()}";
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showConfirmSheet() {
    showDialog(
      context: context,
      barrierDismissible: false, // Ngăn chặn tắt bằng cách chạm ra ngoài để đảm bảo quy trình xóa
      barrierColor: Colors.black54,
      builder: (_) => ConfirmPhoneSheet(
        phone: _emailController.text,
        onContinue: () {
          Navigator.pop(context);
          // context.go('/otp', extra: _emailController.text);
          context.push('/reset-password', extra: _emailController.text);
        },
        onCancel: () async {
          Navigator.pop(context); // 1. Đóng cái sheet trước
          await AuthService.deleteAccountAndData(); // 2. Gọi hàm xóa dữ liệu và về trang chủ/sign-up
        },
      ),
    );
  }

  void _onBackPressed() {
    final t = AppLocalizations(localeNotifier.value);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "Hủy đăng ký?", // Hoặc t.get('cancelConfirmTitle')
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Bạn có chắc chắn muốn hủy đăng ký không? Toàn bộ dữ liệu đã nhập sẽ bị xóa.",
          ),
          actions: [
            // Nút Tiếp tục (Đóng dialog và ở lại)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Tiếp tục đăng ký", // Hoặc t.get('continueRegistration')
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            // Nút Chắc chắn (Gọi hàm xóa và thoát)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Đóng dialog
                _onCancelRegistration(); // Gọi hàm xóa tài khoản
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text("Chắc chắn"),
            ),
          ],
        );
      },
    );
  }

  void _clearEmail() {
    _emailController.clear();
    _updateButtonState();
  }

  // ================= UI BUILDERS =================

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
            child: SlideTransition(
              position: _shakeAnim,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildTitle(t),
                            const SizedBox(height: 24),
                            _buildEmailField(t),
                            
                            // Banner hiển thị lỗi từ Server (ví dụ: Email tồn tại)
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),
                            _buildCheckbox(
                              value: _agreeTerms,
                              onChanged: _onAgreeTermsChanged,
                              label: t.get('agreeTerms'),
                              link: t.get('agreeTermsLink'),
                            ),
                            _buildCheckbox(
                              value: _agreeSocialPolicy,
                              onChanged: _onAgreeSocialPolicyChanged,
                              label: t.get('agreePolicy'),
                              link: t.get('agreePolicyLink'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildButton(t),
                          const SizedBox(height: 12),
                          _buildLoginLink(t),
                        ],
                      ),
                    )
                  ],
                ),
              ),
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
        icon: const Icon(Icons.arrow_back_outlined, size: 20, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildTitle(AppLocalizations t) {
    return Text(
      t.get('enterEmail'),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildEmailField(AppLocalizations t) {
    return TextFormField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      keyboardType: TextInputType.emailAddress,
      autovalidateMode: AutovalidateMode.onUserInteraction, 
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      onChanged: (_) => _updateButtonState(),
      validator: (value) => Validator.email(
        value,
        requiredMessage: t.get('validatorRequired'),
        invalidMessage: t.get('validatorEmail'),
      ),
      decoration: InputDecoration(
        hintText: t.get('emailHint'),
        hintStyle: TextStyle(fontSize: 16, color: Colors.grey.shade400),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        prefixIcon: const Icon(Icons.email_outlined, size: 22, color: Colors.grey),
        suffixIcon: _emailController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.cancel, size: 20, color: Colors.grey),
                onPressed: _clearEmail,
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0068FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.red, fontSize: 12), 
      ),
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required Function(bool?) onChanged,
    required String label,
    required String link,
  }) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primaryBlue,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (link.isNotEmpty)
                  Text(
                    " $link",
                    style: const TextStyle(
                      color: AppColors.textBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildButton(AppLocalizations t) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: (_isButtonEnabled && !_isLoading) ? _handleRegister : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isButtonEnabled ? AppColors.primaryBlue : Colors.grey.shade300,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        child: _isLoading 
          ? const SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            )
          : Text(
              t.get('continue_'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
      ),
    );
  }

  Widget _buildLoginLink(AppLocalizations t) {
    return GestureDetector(
      onTap: () => context.go('/'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.get('noAccount'), style: const TextStyle(color: AppColors.textPrimary)),
          const SizedBox(width: 4),
          Text(
            t.get('loginNow'),
            style: const TextStyle(color: AppColors.textBlue, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}