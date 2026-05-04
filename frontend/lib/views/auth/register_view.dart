import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:go_router/go_router.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView>
    with TickerProviderStateMixin {
  // ── Form key ──
  final _formKey = GlobalKey<FormState>();

  // ── Controllers ──
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  // ── Focus nodes ──
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  // ── State ──
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  DateTime? _selectedDob;

  // ── Password strength ──
  double _passwordStrength = 0;
  String _passwordStrengthLabel = '';
  Color _passwordStrengthColor = Colors.transparent;

  // ── Animation ──
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _shakeCtrl;
  late Animation<Offset> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(-0.02, 0)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(-0.02, 0), end: const Offset(0.02, 0)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0.02, 0), end: Offset.zero),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _passwordCtrl.addListener(_evaluatePasswordStrength);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _shakeCtrl.dispose();
    for (final c in [
      _firstNameCtrl,
      _lastNameCtrl,
      _emailCtrl,
      _passwordCtrl,
      _confirmPasswordCtrl,
    ]) {
      c.dispose();
    }
    for (final f in [
      _firstNameFocus,
      _lastNameFocus,
      _emailFocus,
      _passwordFocus,
      _confirmFocus,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  // ════════════════════════════════════════════
  //  Logic
  // ════════════════════════════════════════════

  void _evaluatePasswordStrength() {
    final p = _passwordCtrl.text;
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

  Future<void> _pickDob() async {
    final now = DateTime.now();
    // Người dùng phải íd nhất 16 tuổi
    final maxDate = DateTime(now.year - 16, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: maxDate,
      helpText: 'Chọn ngày sinh',
      confirmText: 'Xác nhận',
      cancelText: 'Hủy',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primaryBlue,
            onPrimary: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  /// Tính tuổi dựa trên ngày sinh
  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _handleRegister() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      _shakeCtrl.forward(from: 0);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dobStr = _selectedDob != null
          ? '${_selectedDob!.year.toString().padLeft(4, '0')}-'
                '${_selectedDob!.month.toString().padLeft(2, '0')}-'
                '${_selectedDob!.day.toString().padLeft(2, '0')}'
          : null;

      await AuthService.register(
        RegisterRequest(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          dateOfBirth: dobStr,
        ),
      );

      if (!mounted) return;
      _showSuccessAndNavigate();
    } catch (e) {
      if (!mounted) return;
      final rawMessage = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _isLoading = false;
        _errorMessage = _mapBackendError(rawMessage);
      });
      _shakeCtrl.forward(from: 0);
    }
  }

  /// Chuyển đổi thông báo lỗi từ backend sang tiếng Việt thân thiện.
  String _mapBackendError(String message) {
    final lower = message.toLowerCase();
    // Backend trả về lỗi mật khẩu phải đủ 8 ký tự
    if (lower.contains('password') &&
        (lower.contains('8') ||
            lower.contains('least') ||
            lower.contains('minimum') ||
            lower.contains('characters') ||
            lower.contains('ký tự'))) {
      return 'Mật khẩu phải có ít nhất 8 ký tự.';
    }
    // Backend trả về lỗi mật khẩu cần chữ hoa
    if (lower.contains('password') &&
        (lower.contains('uppercase') ||
            lower.contains('upper case') ||
            lower.contains('capital') ||
            lower.contains('chữ hoa'))) {
      return 'Mật khẩu phải có ít nhất 1 chữ hoa (A-Z).';
    }
    // Backend trả về lỗi mật khẩu cần chữ thường
    if (lower.contains('password') &&
        (lower.contains('lowercase') ||
            lower.contains('lower case') ||
            lower.contains('letter') ||
            lower.contains('chữ thường'))) {
      return 'Mật khẩu phải có ít nhất 1 chữ thường (a-z).';
    }
    if (lower.contains('email') && lower.contains('exist')) {
      return 'Email này đã được sử dụng. Vui lòng dùng email khác.';
    }
    if (lower.contains('invalid') && lower.contains('email')) {
      return 'Địa chỉ email không hợp lệ.';
    }
    return message;
  }

  void _showSuccessAndNavigate() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(36),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF43A047),
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Đăng ký thành công!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tài khoản của bạn đã được tạo. Hãy đăng nhập để tiếp tục.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Đăng nhập ngay',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  //  Build
  // ════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: SlideTransition(
                      position: _shakeAnim,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            _buildSubtitle(),
                            const SizedBox(height: 28),
                            _buildNameRow(),
                            const SizedBox(height: 16),
                            _buildEmailField(),
                            const SizedBox(height: 16),
                            _buildDobField(),
                            const SizedBox(height: 16),
                            _buildPasswordField(),
                            if (_passwordCtrl.text.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildPasswordStrengthBar(),
                            ],
                            const SizedBox(height: 16),
                            _buildConfirmPasswordField(),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              _buildErrorBanner(),
                            ],
                            const SizedBox(height: 28),
                            _buildRegisterButton(),
                            const SizedBox(height: 20),
                            _buildLoginRow(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/login'),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo + tên app
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Z',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Zalo Lite',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlue,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tạo tài khoản',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Điền thông tin để bắt đầu kết nối',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ── Name row ────────────────────────────────

  Widget _buildNameRow() {
    return Row(
      children: [
        Expanded(
          child: _buildField(
            controller: _firstNameCtrl,
            focusNode: _firstNameFocus,
            nextFocus: _lastNameFocus,
            label: 'Họ',
            hint: 'Nguyễn',
            icon: Icons.person_outline_rounded,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Nhập họ';
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildField(
            controller: _lastNameCtrl,
            focusNode: _lastNameFocus,
            nextFocus: _emailFocus,
            label: 'Tên',
            hint: 'Văn A',
            icon: null,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Nhập tên';
              return null;
            },
          ),
        ),
      ],
    );
  }

  // ── Email ────────────────────────────────────

  Widget _buildEmailField() {
    return _buildField(
      controller: _emailCtrl,
      focusNode: _emailFocus,
      nextFocus: _passwordFocus,
      label: 'Email',
      hint: 'example@email.com',
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
        final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$');
        if (!emailRegex.hasMatch(v.trim())) return 'Email không hợp lệ';
        return null;
      },
    );
  }

  // ── Date of birth ────────────────────────────

  Widget _buildDobField() {
    final dobText = _selectedDob != null
        ? '${_selectedDob!.day.toString().padLeft(2, '0')}/'
              '${_selectedDob!.month.toString().padLeft(2, '0')}/'
              '${_selectedDob!.year}'
        : null;

    return GestureDetector(
      onTap: _pickDob,
      child: AbsorbPointer(
        child: TextFormField(
          readOnly: true,
          decoration: _fieldDecoration(
            label: 'Ngày sinh',
            hint: 'DD/MM/YYYY',
            prefixIcon: Icons.cake_outlined,
            suffixIcon: Icons.calendar_today_outlined,
          ),
          controller: TextEditingController(text: dobText ?? ''),
          validator: (_) {
            if (_selectedDob == null) return 'Vui lòng nhập ngày sinh';
            if (_calculateAge(_selectedDob!) < 16) {
              return 'Bạn phải đủ 16 tuổi để đăng ký';
            }
            return null;
          },
        ),
      ),
    );
  }

  // ── Password ─────────────────────────────────

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordCtrl,
      focusNode: _passwordFocus,
      obscureText: _obscurePassword,
      onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
        if (v.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';
        if (!RegExp(r'[a-z]').hasMatch(v)) return 'Mật khẩu phải có ít nhất 1 chữ thường';
        if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Mật khẩu phải có ít nhất 1 chữ hoa';
        return null;
      },
      decoration:
          _fieldDecoration(
            label: 'Mật khẩu',
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
          ).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textHint,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
    );
  }

  Widget _buildPasswordStrengthBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _passwordStrength,
            minHeight: 4,
            backgroundColor: AppColors.borderGray,
            valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Độ mạnh: $_passwordStrengthLabel',
          style: TextStyle(
            fontSize: 12,
            color: _passwordStrengthColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordCtrl,
      focusNode: _confirmFocus,
      obscureText: _obscureConfirm,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleRegister(),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
        if (v != _passwordCtrl.text) return 'Mật khẩu không khớp';
        return null;
      },
      decoration:
          _fieldDecoration(
            label: 'Xác nhận mật khẩu',
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
          ).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textHint,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
    );
  }

  // ── Error banner ─────────────────────────────

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFE53935),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFB71C1C),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Register button ──────────────────────────

  Widget _buildRegisterButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryBlue.withValues(alpha: 0.5),
          elevation: 0,
          shadowColor: AppColors.primaryBlue.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isLoading
              ? const SizedBox(
                  key: ValueKey('loader'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  key: ValueKey('label'),
                  'Đăng ký',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }

  // ── Login row ────────────────────────────────

  Widget _buildLoginRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Đã có tài khoản? ',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: () => context.go('/login'),
          child: const Text(
            'Đăng nhập',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════
  //  Helpers
  // ════════════════════════════════════════════

  /// Generic text field builder
  Widget _buildField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required String label,
    required String hint,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: nextFocus != null
          ? TextInputAction.next
          : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          nextFocus.requestFocus();
        }
      },
      validator: validator,
      decoration: _fieldDecoration(label: label, hint: hint, prefixIcon: icon),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    IconData? prefixIcon,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.textHint, size: 20)
          : null,
      suffixIcon: suffixIcon != null
          ? Icon(suffixIcon, color: AppColors.textHint, size: 18)
          : null,
      filled: true,
      fillColor: AppColors.backgroundGray,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderGray, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE53935), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
      ),
      errorStyle: const TextStyle(fontSize: 12, color: Color(0xFFE53935)),
    );
  }
}
