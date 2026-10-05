import '../models/register_model.dart';

abstract class AuthRepo {
  Future<void> login({
    required String email,
    required String password,
  });

  Future<RegisterModel> register({
    required RegisterModel model,
    required String password,
  });

  /// Sends a password reset email to the given address.
  Future<void> sendPasswordResetEmail({required String email});
}