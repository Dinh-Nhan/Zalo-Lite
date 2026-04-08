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
      'noAccount': 'Bạn đã có tài khoản? ',
      'loginNow': 'Đăng nhập ngay',

      // Màn hình đăng ký (cho tương lai)
      'enterPhoneNumber': 'Nhập số điện thoại',
      'phoneHint': 'Nhập để tìm kiếm',
      'agreeTerms': 'Tôi đồng ý với các ',
      'agreeTermsLink': 'Điều khoản sử dụng của Zalo',
      'agreePolicy': 'Tôi đồng ý với ',
      'agreePolicyLink': 'Chính sách Mạng xã hội của Zalo',
      'continue_': 'Tiếp tục',
      'back': 'Quay lại',
      'confirmPhoneTitle': 'Nhận mã xác thực qua số',
      'confirmPhoneDesc': 'Zalo sẽ gửi mã xác thực cho bạn qua số điện thoại này',
      'changeNumber': 'Đổi số khác',
      'phoneHintDesc': 'Nhập dãy 6 số đang được gửi đến số điện thoại',

      // Màn hình OTP
      'otpTitle': 'Nhập mã xác thực',
      'otpDesc': 'Nhập dãy 6 số đang được gửi đến số điện thoại',
      'otpInvalid': 'Mã xác thực không chính xác',
      'otpError': 'Đã có lỗi xảy ra, vui lòng thử lại',
      'otpSuccess': 'Xác thực thành công!',
      'otpNotReceived': 'Bạn không nhận được mã?',
      'otpResend': 'Gửi lại',

      // Màn hình tin nhắn (Chat List)
      'messages': 'Tin nhắn',
      'searchPlaceholder': 'Tìm kiếm',
      'noMessages': 'Chưa có tin nhắn nào',
      'all': 'Tất cả',
      'unread': 'Chưa đọc',
      'category': 'Phân loại',
      'friends': 'Bạn bè',
      'groups': 'Nhóm',
      'youPrefix': 'Bạn:',
      'messageHint': 'Tin nhắn',
      'today': 'Hôm nay',
      'members': 'thành viên',
      
      // Settings
      'settings': 'Cài đặt',
      'darkMode': 'Chế độ tối',
      'darkModeOn': 'Đang bật',
      'darkModeOff': 'Đang tắt',
      'lightMode': 'Chế độ sáng',
      'language': 'Ngôn ngữ',
      'selectLanguage': 'Chọn ngôn ngữ',
      'changeLanguage': 'Thay đổi ngôn ngữ',
      'logout': 'Đăng xuất',
      'logoutSubtitle': 'Thoát khỏi tài khoản',
      'generalSettings': 'Cài đặt chung',
      'generalSettingsDesc': 'Các cài đặt chung của ứng dụng sẽ được hiển thị ở đây.',
      'appearance': 'Giao diện',
      'appearanceDesc': 'Chọn giao diện phù hợp với bạn',
      
      // Welcome panel
      'welcomeTitle': 'Chào mừng đến với Zalo PC!',
      'welcomeDescription': 'Khám phá những tiện ích hỗ trợ làm việc và trò chuyện cùng\nngười thân, bạn bè được tối ưu hoá cho máy tính của bạn.',
      'darkModeTitle': 'Giao diện Dark Mode',
      'darkModeDescription': 'Thư giãn và bảo vệ mắt với chế độ giao diện tối mới trên Zalo PC',
      'tryNow': 'Thử ngay',
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
      'phoneHint': 'Search...',
      'agreeTerms': 'I agree with Zalo\'s ',
      'agreeTermsLink': 'terms of use',
      'agreePolicy': 'I agree with Zalo\'s ',
      'agreePolicyLink': 'social network policy',
      'continue_': 'Continue',
      'back': 'Back',
      'confirmPhoneTitle': 'Receive verification code via',
      'confirmPhoneDesc': 'Zalo will send a verification code to this phone number',
      'changeNumber': 'Change number',
      'phoneHintDesc': 'Enter the 6-digit code sent to your phone',

      // OTP screen
      'otpTitle': 'Enter verification code',
      'otpDesc': 'Enter the 6-digit code sent to phone number',
      'otpInvalid': 'Verification code is incorrect',
      'otpError': 'An error occurred, please try again',
      'otpSuccess': 'Verification successful!',
      'otpNotReceived': 'Didn\'t receive the code?',
      'otpResend': 'Resend',

      // Chat List screen
      'messages': 'Messages',
      'searchPlaceholder': 'Search',
      'noMessages': 'No messages yet',
      'all': 'All',
      'unread': 'Unread',
      'category': 'Category',
      'friends': 'Friends',
      'groups': 'Groups',
      'youPrefix': 'You:',
      'messageHint': 'Message',
      'today': 'Today',
      'members': 'members',
      
      // Settings
      'settings': 'Settings',
      'darkMode': 'Dark Mode',
      'darkModeOn': 'On',
      'darkModeOff': 'Off',
      'lightMode': 'Light Mode',
      'language': 'Language',
      'selectLanguage': 'Select Language',
      'changeLanguage': 'Change language',
      'logout': 'Log out',
      'logoutSubtitle': 'Sign out of your account',
      'generalSettings': 'General Settings',
      'generalSettingsDesc': 'General application settings will be displayed here.',
      'appearance': 'Appearance',
      'appearanceDesc': 'Choose the appearance that suits you',
      
      // Welcome panel
      'welcomeTitle': 'Welcome to Zalo PC!',
      'welcomeDescription': 'Discover useful features to work and chat with\nfamily and friends, optimized for your computer.',
      'darkModeTitle': 'Dark Mode Interface',
      'darkModeDescription': 'Relax and protect your eyes with the new dark interface on Zalo PC',
      'tryNow': 'Try now',
    },
  };
}
