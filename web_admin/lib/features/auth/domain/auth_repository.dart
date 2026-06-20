// ============================================================
// AUTH FEATURE - Domain
// ============================================================

abstract interface class AuthRepository {
  Future<void> signIn(String email, String password);
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Stream<bool> get authStateStream;
  bool get isLoggedIn;
}
