import 'package:frontend/utils/app_localizations.dart';

/// Các hàm validate dùng chung cho toàn bộ ứng dụng.
///
/// Mỗi hàm đều nhận optional parameter [message] để hỗ trợ đa ngôn ngữ.
/// Mặc định là tiếng Việt. Caller truyền message tiếng Anh từ AppLocalizations.
///
/// Ví dụ:
///   // Tiếng Việt (mặc định)
///   Validator.required(value);
///
///   // Tiếng Anh (truyền message)
///   Validator.required(value, message: t.get('validatorRequired'));
class Validator {
  // Không để trống
  static String? required(
    String? value, {
    String message = 'Không được để trống',
  }) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  // Email
  static String? email(
    String? value, {
    String requiredMessage = 'Không được để trống',
    String invalidMessage = 'Email không hợp lệ',
  }) {
    if (value == null || value.trim().isEmpty) {
      return requiredMessage;
    }

    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!regex.hasMatch(value)) {
      return invalidMessage;
    }

    return null;
  }

  // Password mạnh
  static String? password(
    String? value, {
    String requiredMessage = 'Không được để trống',
    String invalidMessage =
        'Mật khẩu ≥8 ký tự, gồm ít nhất 1 chữ hoa và 1 chữ số',
  }) {
    if (value == null || value.isEmpty) {
      return requiredMessage;
    }

    final regex = RegExp(r'^(?=.*[A-Z])(?=.*\d).{8,}$');

    if (!regex.hasMatch(value)) {
      return invalidMessage;
    }

    return null;
  }

  // Username
  static String? username(
    String? value, {
    String requiredMessage = 'Không được để trống',
    String invalidMessage = 'Username 3-20 ký tự, không ký tự đặc biệt',
  }) {
    if (value == null || value.isEmpty) {
      return requiredMessage;
    }

    final regex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

    if (!regex.hasMatch(value)) {
      return invalidMessage;
    }

    return null;
  }

  // SĐT Việt Nam
  static String? phone(String? value, AppLocalizations t) {
    if (value == null || value.isEmpty) {
      return t.get('validatorRequired');
    }

    final regex = RegExp(r'^(0|\+84)[0-9]{9}$');

    if (!regex.hasMatch(value)) {
      return t.get('validatorPhone');
    }

    return null;
  }

  // Chỉ số
  static String? number(
    String? value, {
    String requiredMessage = 'Không được để trống',
    String invalidMessage = 'Chỉ được nhập số',
  }) {
    if (value == null || value.isEmpty) {
      return requiredMessage;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return invalidMessage;
    }

    return null;
  }

  // Không chứa ký tự đặc biệt
  static String? noSpecialChar(
    String? value, {
    String requiredMessage = 'Không được để trống',
    String invalidMessage = 'Không được chứa ký tự đặc biệt',
  }) {
    if (value == null || value.isEmpty) {
      return requiredMessage;
    }

    if (!RegExp(r'^[a-zA-Z0-9_ ]+$').hasMatch(value)) {
      return invalidMessage;
    }

    return null;
  }

  // Confirm password
  static String? confirmPassword(
    String? value,
    String original, {
    String requiredMessage = 'Không được để trống',
    String mismatchMessage = 'Mật khẩu không khớp',
  }) {
    if (value == null || value.isEmpty) {
      return requiredMessage;
    }

    if (value != original) {
      return mismatchMessage;
    }

    return null;
  }

  // Min length
  static String? minLength(
    String? value,
    int min, {
    String requiredMessage = 'Không được để trống',
    String? tooShortMessage,
  }) {
    if (value == null || value.isEmpty) {
      return requiredMessage;
    }

    if (value.length < min) {
      return tooShortMessage ?? 'Ít nhất $min ký tự';
    }

    return null;
  }
}
