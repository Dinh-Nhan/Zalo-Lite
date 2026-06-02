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
  final _formKey = GlobalKey<FormState>(); // 1. Khai báo FormKey
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isFormValid = false; // Biến theo dõi trạng thái form

  String? _apiStatus;
  String? _apiBody;
  bool _apiSuccess = false;

  // Hàm kiểm tra form mỗi khi người dùng nhập liệu
  void _validateForm() {
    setState(() {
      _isFormValid = _formKey.currentState?.validate() ?? false;
    });
  }

  Future<void> _handleLogin() async {
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
        final response = await DioClient.instance.get(
          '/api/auth/profile',
        );
        //final profile = response.data['result'];
        // await friendProvider.setCurrentUid(profile['id']);
        final firebaseUid = FirebaseAuth.instance.currentUser!.uid;

        await friendProvider.setCurrentUid(firebaseUid);
        await friendProvider.loadAll();
        await friendProvider.startRealtime();

        if (!mounted) return;

        context.go('/chat-list');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khởi tạo dữ liệu: $e'),
          ),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
        _apiSuccess = false;
        _apiStatus = 'Login thất bại';

        _apiBody = result.errorMessage ??
            (result.errorCode != null
                ? 'Code: ${result.errorCode}'
                : null);
      });
    }
  }

  // --- Giữ nguyên hàm _testProfileApi của bạn ---
  Future<void> _testProfileApi() async {
    try {
      final response = await DioClient.instance.get('/api/auth/profile');
      setState(() {
        _isLoading = false;
        _apiSuccess = true;
        _apiStatus = '✅ ${response.statusCode} OK';
        _apiBody = response.data.toString();
      });
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
          onChanged: _validateForm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // --- Email field
              TextFormField( 
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  
                  // Xóa khoảng trắng thừa ở đầu/cuối chuỗi trước khi kiểm tra
                  final email = value.trim();

                  // RegExp chuẩn hóa cho email phổ biến hiện nay
                  final emailRegex = RegExp(
                    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+"
                  );

                  if (!emailRegex.hasMatch(email)) {
                    return 'Email không đúng định dạng';
                  }
                  
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  errorStyle: const TextStyle(height: 0), // Ẩn text lỗi để giống Zalo
                ),
              ),
              const SizedBox(height: 4),

              // --- Password field ---
              TextFormField( // Đổi thành TextFormField
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                // validator: (value) {
                //   return Validator.password(value);
                // },
                decoration: InputDecoration(
                  hintText: 'Mật khẩu',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                  suffixIcon: TextButton(
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    child: Text(
                      _isPasswordVisible ? 'ẨN' : 'HIỆN',
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF0068FF), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  errorStyle: const TextStyle(height: 0),
                ),
              ),
              const SizedBox(height: 20),

              // Quên mật khẩu
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Lấy lại mật khẩu',
                    style: TextStyle(color: Color(0xFF0068FF), fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Login button
              Center(
                child: SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    // 3. Logic Enable/Disable: Nếu đang load HOẶC form chưa valid thì null (Disable)
                    onPressed: (_isLoading || !_isFormValid) ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      // Màu khi disable sẽ tự động nhạt đi, màu chính khi enable
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
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Đăng nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),

              // Hiển thị thông báo API (Giữ nguyên của bạn)
              if (_apiStatus != null) ...[
                const SizedBox(height: 24),
                // ... (Đoạn Container hiển thị kết quả giữ nguyên)
              ],
            ],
          ),
        ),
      ),
    );
  }
}