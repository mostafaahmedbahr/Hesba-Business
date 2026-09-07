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
}