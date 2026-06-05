// ============================================================
// CORE - App Exception
// ============================================================

sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([String message = 'Network error occurred'])
      : super(message);
}

class FirestoreException extends AppException {
  const FirestoreException([String message = 'Database error occurred'])
      : super(message);
}

class AuthException extends AppException {
  const AuthException([String message = 'Authentication failed'])
      : super(message);
}

class PermissionException extends AppException {
  const PermissionException([String message = 'Permission denied'])
      : super(message);
}

class NotFoundException extends AppException {
  const NotFoundException([String message = 'Resource not found'])
      : super(message);
}

class UnknownException extends AppException {
  const UnknownException([String message = 'An unexpected error occurred'])
      : super(message);
}
