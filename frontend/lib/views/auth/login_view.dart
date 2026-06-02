import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/dio_client.dart';
import 'package:frontend/utils/validator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}
class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isFormValid = false;

  String? _apiStatus;
  String? _apiBody;
  bool _apiSuccess = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _emailController.text.isNotEmpty &&
          _emailController.text.contains('@') &&
          _passwordController.text.isNotEmpty;
    });
  }

  Future<void> _handleLogin() async {
    if (_isLoading || !_isFormValid) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _apiStatus = null;
      _apiBody = null;
    });

    final result = await AuthService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      try {
        final friendProvider = context.read<FriendProvider>();
        final response = await DioClient.instance.get('/api/auth/profile');
        final firebaseUid = FirebaseAuth.instance.currentUser!.uid;

        await friendProvider.setCurrentUid(firebaseUid);
        await friendProvider.loadAll();
        await friendProvider.startRealtime();

        if (!mounted) return;
        context.go('/chat-list');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khởi tạo dữ liệu: $e')),
        );
        setState(() => _isLoading = false);
      }
    } else {
      setState(() {
        _isLoading = false;
        _apiSuccess = false;
        _apiStatus = 'Login thất bại';
        _apiBody = result.errorMessage ??
            (result.errorCode != null ? 'Code: ${result.errorCode}' : null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Đăng nhập', style: TextStyle(fontSize: 18)),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.textWhite,
        elevation: 0.5,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined, size: 18),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập email';
                  if (!value.contains('@')) return 'Email không hợp lệ';
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Số điện thoại/Email',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF0068FF), width: 1.5),
                  ),
                  errorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  errorStyle: const TextStyle(height: 0),
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleLogin(),
                validator: (value) {
                  return Validator.password(value);
                },
                decoration: InputDecoration(
                  hintText: 'Mật khẩu',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                  suffixIcon: TextButton(
                    onPressed: () {
                      setState(() => _isPasswordVisible = !_isPasswordVisible);
                    },
                    child: Text(
                      _isPasswordVisible ? 'ẨN' : 'HIỆN',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF0068FF), width: 1.5),
                  ),
                  errorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  errorStyle: const TextStyle(height: 0),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Lấy lại mật khẩu',
                    style: TextStyle(
                      color: Color(0xFF0068FF),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isLoading || !_isFormValid) ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0068FF),
                    disabledBackgroundColor: const Color(0xFF0068FF).withOpacity(0.3),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
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
                      : const Text(
                          'Đăng nhập',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              if (_apiStatus != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _apiSuccess ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _apiSuccess ? Colors.green.shade200 : Colors.red.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _apiStatus!,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _apiSuccess ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                      if (_apiBody != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _apiBody!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _apiSuccess ? Colors.green.shade600 : Colors.red.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
