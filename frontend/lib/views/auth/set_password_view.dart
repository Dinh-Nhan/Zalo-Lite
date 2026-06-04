import 'package:flutter/material.dart';
import 'package:frontend/component/loading_dialog.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/utils/validator.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordView extends StatefulWidget {
  final String? email; // Biến lưu email để truyền vào API reset password
  const ResetPasswordView({super.key, required this.email});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();

  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isFormValid = false;
  String? _errorMessage;

  double _passwordStrength = 0;
  String _passwordStrengthLabel = '';
  Color _passwordStrengthColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_onInputChanged);
    _confirmPasswordCtrl.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    _evaluatePasswordStrength();
    _validateFormStatus();
  }

  void _validateFormStatus() {
    final password = _passwordCtrl.text;
    final confirm = _confirmPasswordCtrl.text;

    bool isValid = password.length >= 8 && 
                   confirm.isNotEmpty && 
                   password == confirm;

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  void _evaluatePasswordStrength() {
    final p = _passwordCtrl.text;
    if (p.isEmpty) {
      setState(() {
        _passwordStrength = 0;
        _passwordStrengthLabel = '';
      });
      return;
    }

    int score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) score++;

    setState(() {
      _passwordStrength = score / 4;
      switch (score) {
        case 0:
        case 1:
          _passwordStrengthLabel = 'Yếu';
          _passwordStrengthColor = const Color(0xFFE53935);
          break;
        case 2:
          _passwordStrengthLabel = 'Trung bình';
          _passwordStrengthColor = const Color(0xFFFF8F00);
          break;
        case 3:
          _passwordStrengthLabel = 'Mạnh';
          _passwordStrengthColor = const Color(0xFF43A047);
          break;
        case 4:
          _passwordStrengthLabel = 'Rất mạnh';
          _passwordStrengthColor = const Color(0xFF00897B);
          break;
      }
    });
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      LoadingDialog.show(context, message: "Đang tải...");
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      LoadingDialog.hide(context);
      context.pushReplacement('/enter-name', extra: {
        'email': widget.email,
        'password': _passwordCtrl.text.trim()
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () async => {
            await AuthService.deleteAccountAndData(),
            context.pop(), 
          }
        ),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Cài đặt mật khẩu',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mật khẩu mới phải từ 8 ký tự và bao gồm tối thiểu 1 chữ hoa, 1 chữ số, có thể chứa ký tự đặc biệt.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
                  ),
                ],

                const SizedBox(height: 32),

                _buildPasswordField(
                  controller: _passwordCtrl,
                  focusNode: _passwordFocus,
                  label: 'Nhập mật khẩu mới',
                  isObscured: _obscurePassword,
                  onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                  validator: (v) => Validator.password(v),
                  onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
                ),

                if (_passwordCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: _buildPasswordStrengthBar(),
                  ),
                ],

                const SizedBox(height: 20),

                _buildPasswordField(
                  controller: _confirmPasswordCtrl,
                  focusNode: _confirmFocus,
                  label: 'Nhập lại mật khẩu mới',
                  isObscured: _obscureConfirm,
                  onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) => Validator.confirmPassword(v, _passwordCtrl.text),
                  onFieldSubmitted: _isFormValid ? (_) => _handleSubmit() : null,
                ),

                const SizedBox(height: 40),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isFormValid ? _handleSubmit : null, 
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primaryBlue.withOpacity(0.3),
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: const Text('Tiếp tục', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: _passwordStrength,
            minHeight: 6,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Độ mạnh: $_passwordStrengthLabel',
          style: TextStyle(fontSize: 12, color: _passwordStrengthColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required bool isObscured,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
    required Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: isObscured,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
        
        // Nút HIỆN/ẨN
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: TextButton(
            onPressed: onToggleVisibility,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              isObscured ? 'HIỆN' : 'ẨN',
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        
        // Cấu hình Border Tròn
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.grey, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}