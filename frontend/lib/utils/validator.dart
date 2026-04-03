class Validator {
  // Không để trống
  static String? required(
    String? value, {
    String message = "Không được để trống",
  }) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  // Email
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Không được để trống";
    }

    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!regex.hasMatch(value)) {
      return "Email không hợp lệ";
    }

    return null;
  }

  // Password mạnh
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return "Không được để trống";
    }

    final regex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$',
    );

    if (!regex.hasMatch(value)) {
      return "Mật khẩu phải ≥8 ký tự, gồm chữ hoa, thường, số, ký tự đặc biệt";
    }

    return null;
  }

  // Username
  static String? username(String? value) {
    if (value == null || value.isEmpty) {
      return "Không được để trống";
    }

    final regex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

    if (!regex.hasMatch(value)) {
      return "Username 3-20 ký tự, không ký tự đặc biệt";
    }

    return null;
  }

  // SĐT Việt Nam
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return "Không được để trống";
    }

    final regex = RegExp(r'^(0|\+84)[0-9]{9}$');

    if (!regex.hasMatch(value)) {
      return "Số điện thoại không hợp lệ";
    }

    return null;
  }

  // Chỉ số
  static String? number(String? value) {
    if (value == null || value.isEmpty) {
      return "Không được để trống";
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return "Chỉ được nhập số";
    }

    return null;
  }

  // Không chứa ký tự đặc biệt
  static String? noSpecialChar(String? value) {
    if (value == null || value.isEmpty) {
      return "Không được để trống";
    }

    if (!RegExp(r'^[a-zA-Z0-9_ ]+$').hasMatch(value)) {
      return "Không được chứa ký tự đặc biệt";
    }

    return null;
  }

  // Confirm password
  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return "Không được để trống";
    }

    if (value != original) {
      return "Mật khẩu không khớp";
    }

    return null;
  }

  // Min length
  static String? minLength(String? value, int min) {
    if (value == null || value.isEmpty) {
      return "Không được để trống";
    }

    if (value.length < min) {
      return "Ít nhất $min ký tự";
    }

    return null;
  }
}
