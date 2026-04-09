import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/apps/app_locale.dart';
import 'package:frontend/component/confirm_phone_sheet.dart';
import 'package:frontend/utils/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../utils/validator.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  bool _agreeTerms = false;
  bool _agreeSocialPolicy = false;

  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _phoneController.addListener(_updateButtonState);
  }

  // ================= STATE =================

  void _updateButtonState() {
    final isValid = _formKey.currentState?.validate() ?? false;

    setState(() {
      _isButtonEnabled =
          isValid && _agreeTerms && _agreeSocialPolicy;
    });
  }

  void _onAgreeTermsChanged(bool? value) {
    setState(() {
      _agreeTerms = value ?? false;
    });
    _updateButtonState();
  }

  void _onAgreeSocialPolicyChanged(bool? value) {
    setState(() {
      _agreeSocialPolicy = value ?? false;
    });
    _updateButtonState();
  }

  // ================= ACTION =================

  void _onBackPressed() {
    context.go('/');
  }

  void _clearPhone() {
    _phoneController.clear();
  }
  void _showConfirmSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ConfirmPhoneSheet(
        phone: _phoneController.text,
        onContinue: () {
          context.go('/otp');
        },
      ),
    );
}
  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
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
                        _buildPhoneField(t),
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

  Widget _buildTitle(AppLocalizations t) {
    return Text(
      t.get('enterPhoneNumber'),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildPhoneField(AppLocalizations t) {
    return TextFormField(
      controller: _phoneController,
      focusNode: _phoneFocusNode,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(11),
      ],
      validator: (value) => Validator.phone(value ?? '', t),
      onChanged: (_) => _updateButtonState(),
      decoration: InputDecoration(
        hintText: t.get('phoneNumber'),
        filled: true,
        fillColor: AppColors.backgroundWhite,
        contentPadding: const EdgeInsets.all(16),
        suffixIcon: _phoneController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearPhone,
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.grey,
            width: 1.5,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.green,
            width: 2,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
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
          // Sửa lỗi: Đổi children thành child và bọc bằng Wrap hoặc Row
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
                GestureDetector(
                  onTap: () {
                    print("Mở link: $link");
                  },
                  child: Text(
                    "$link", 
                    style: const TextStyle(
                      color: AppColors.textBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
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
        onPressed:
            _isButtonEnabled ? _showConfirmSheet : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isButtonEnabled
              ? AppColors.primaryBlue
              : Colors.grey.shade300,
          foregroundColor: Colors.white,
          overlayColor:
              Colors.white.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(
          t.get('continue_'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildLoginLink(AppLocalizations t) {
    return GestureDetector(
      onTap: () {
        context.go('/');
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.get('noAccount'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              decoration: TextDecoration.none,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            t.get('loginNow'),
            style: const TextStyle(
              color: AppColors.textBlue,
              decoration: TextDecoration.none,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}