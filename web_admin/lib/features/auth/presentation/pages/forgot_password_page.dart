import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';

// ============================================================
// AUTH FEATURE - Forgot Password Page
// ============================================================

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .sendPasswordResetEmail(_emailCtrl.text.trim());
      if (mounted) setState(() => _emailSent = true);
    } catch (e) {
      if (mounted) setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.shield_rounded,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(height: 24),

                // Card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _emailSent ? _buildSuccess() : _buildForm(),
                ),

                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Forgot Password', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            'Enter your admin email address and we\'ll send you a password reset link.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 28),

          // Error banner
          if (_errorMsg != null) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_errorMsg!,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.error)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Email field
          Text('Email Address', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: AppTextStyles.bodyMedium,
            decoration: const InputDecoration(
              hintText: 'admin@example.com',
              prefixIcon: Icon(Icons.email_outlined, size: 18),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Send Reset Link', style: AppTextStyles.labelLarge),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.successContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              color: AppColors.success, size: 28),
        ),
        const SizedBox(height: 20),
        Text('Check Your Email', style: AppTextStyles.h2),
        const SizedBox(height: 12),
        Text(
          'A password reset link has been sent to:\n${_emailCtrl.text.trim()}',
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () => setState(() {
              _emailSent = false;
              _emailCtrl.clear();
            }),
            child: const Text('Send Again'),
          ),
        ),
      ],
    );
  }
}
