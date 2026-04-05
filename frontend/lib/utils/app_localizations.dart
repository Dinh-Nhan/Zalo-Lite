/// Hệ thống đa ngôn ngữ đơn giản cho Zalo Lite
/// Hỗ trợ: Tiếng Việt (vi), English (en)
///
/// Cách dùng:
///   final t = AppLocalizations('vi');
///   print(t.get('login')); // → "Đăng nhập"
///
///   final tEn = AppLocalizations('en');
///   print(tEn.get('login')); // → "Log in"
class AppLocalizations {
  final String locale;

  AppLocalizations(this.locale);

  /// Lấy text theo key, trả về key nếu không tìm thấy
  String get(String key) {
    final langMap = _localizedValues[locale];
    if (langMap == null) return key;
    return langMap[key] ?? key;
  }

  /// Kiểm tra có phải tiếng Việt không
  bool get isVietnamese => locale == 'vi';

  /// Kiểm tra có phải tiếng Anh không
  bool get isEnglish => locale == 'en';

  /// Tên hiển thị của ngôn ngữ hiện tại
  String get displayName => locale == 'vi' ? 'Tiếng Việt' : 'English';

  /// Chuyển từ tên hiển thị → locale code
  static String localeFromDisplayName(String name) {
    switch (name) {
      case 'English':
        return 'en';
      case 'Tiếng Việt':
      default:
        return 'vi';
    }
  }

  /// Danh sách ngôn ngữ hỗ trợ (tên hiển thị)
  static const List<String> supportedLanguages = ['Tiếng Việt', 'English'];

  // ========================================
  // Bảng dữ liệu ngôn ngữ
  // ========================================
  static const Map<String, Map<String, String>> _localizedValues = {
    // ---- TIẾNG VIỆT ----
    'vi': {
      // App chung
      'appName': 'Zalo',

      // HomeView (màn hình chào mừng)
      'login': 'Đăng nhập',
      'createAccount': 'Tạo tài khoản mới',

      // Validator messages
      'validatorRequired': 'Không được để trống',
      'validatorEmail': 'Email không hợp lệ',
      'validatorPassword':
          'Mật khẩu phải ≥8 ký tự, gồm chữ hoa, thường, số, ký tự đặc biệt',
      'validatorUsername': 'Username 3-20 ký tự, không ký tự đặc biệt',
      'validatorPhone': 'Số điện thoại không hợp lệ',
      'validatorNumber': 'Chỉ được nhập số',
      'validatorNoSpecialChar': 'Không được chứa ký tự đặc biệt',
      'validatorConfirmPassword': 'Mật khẩu không khớp',
      'validatorMinLength': 'Ít nhất {min} ký tự',

      // Màn hình đăng nhập (cho tương lai)
      'phoneNumber': 'Số điện thoại',
      'password': 'Mật khẩu',
      'forgotPassword': 'Quên mật khẩu?',
      'noAccount': 'Bạn đã có tài khoản?',
      'loginNow': 'Đăng nhập ngay',

      // Màn hình đăng ký (cho tương lai)
      'enterPhoneNumber': 'Nhập số điện thoại',
      'phoneHint': 'Ehehehehehehe',
      'agreeTerms': 'Tôi đồng ý với các điều khoản sử dụng Zalo',
      'agreePolicy':
          'Tôi đồng ý với Điều khoản Mạng xã hội của Zalo',
      'continue_': 'Tiếp tục',
      'back': 'Quay lại',
    },

    // ---- ENGLISH ----
    'en': {
      // App chung
      'appName': 'Zalo',

      // HomeView (welcome screen)
      'login': 'Log in',
      'createAccount': 'Create new account',

      // Validator messages
      'validatorRequired': 'This field is required',
      'validatorEmail': 'Invalid email address',
      'validatorPassword':
          'Password must be ≥8 characters, including uppercase, lowercase, number, and special character',
      'validatorUsername':
          'Username must be 3-20 characters, no special characters',
      'validatorPhone': 'Invalid phone number',
      'validatorNumber': 'Only numbers allowed',
      'validatorNoSpecialChar': 'No special characters allowed',
      'validatorConfirmPassword': 'Passwords do not match',
      'validatorMinLength': 'At least {min} characters',

      // Login screen (future)
      'phoneNumber': 'Phone number',
      'password': 'Password',
      'forgotPassword': 'Forgot password?',
      'noAccount': 'Already have an account?',
      'loginNow': 'Log in now',

      // Register screen (future)
      'enterPhoneNumber': 'Enter phone number',
      'phoneHint': 'Ehehehehehehe',
      'agreeTerms': 'I agree with Zalo\'s terms of use',
      'agreePolicy': 'I agree with Zalo\'s social network policy',
      'continue_': 'Continue',
      'back': 'Back',
    },
  };
}
