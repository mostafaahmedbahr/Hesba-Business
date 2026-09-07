abstract class AuthRepo {
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String shopName,
  });
  Future<void> resetPassword(String email);
  Future<void> signOut();
  Stream<dynamic> get authStateChanges;
}
