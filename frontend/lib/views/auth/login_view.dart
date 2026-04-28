import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/dio_client.dart';
import 'package:go_router/go_router.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _apiStatus;
  String? _apiBody;
  bool _apiSuccess = false;

  Future<void> _handleLogin() async {
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
      // Login OK → test gọi API với token
      await _testProfileApi();
    } else {
      // Hiện lỗi Firebase cụ thể
      setState(() {
        _isLoading = false;
        _apiSuccess = false;
        _apiStatus = '❌ Login thất bại';
        _apiBody = result.errorMessage ??
            (result.errorCode != null ? 'Code: ${result.errorCode}' : null);
      });
    }
  }

  /// Gọi GET /api/auth/profile — token tự động được gắn bởi AuthInterceptor
  Future<void> _testProfileApi() async {
    try {
      final response = await DioClient.instance.get('/api/auth/profile');
      setState(() {
        _isLoading = false;
        _apiSuccess = true;
        _apiStatus = '✅ ${response.statusCode} OK';
        _apiBody = response.data.toString();
      });

      // Chờ 1.5s để user thấy kết quả rồi mới navigate
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) context.go('/chat-list');
    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
        _apiSuccess = false;
        _apiStatus = '❌ ${e.response?.statusCode ?? 'Network Error'}';
        _apiBody = e.response?.data?.toString() ?? e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Đăng nhập'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // Email field
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Password field
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Login button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0068FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            // === Kết quả API test ===
            if (_apiStatus != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _apiSuccess
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  border: Border.all(
                    color: _apiSuccess
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kết quả gọi API',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _apiSuccess
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status: $_apiStatus',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                    if (_apiBody != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Body: $_apiBody',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
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
    );
  }
}
