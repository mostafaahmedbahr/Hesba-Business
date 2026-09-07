import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repos/auth_repo.dart';
import '../states/login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepo _authRepo;

  LoginCubit({required AuthRepo authRepo})
      : _authRepo = authRepo,
        super(const LoginState());

  void togglePassword() {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(status: LoginStatus.loading));
    try {
      await _authRepo.login(email: email, password: password);
      emit(state.copyWith(status: LoginStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: _mapError(e),
      ));
    }
  }

  String _mapError(dynamic error) {
    final msg = error.toString();
    if (msg.contains('user-not-found')) return 'البريد الإلكتروني غير مسجل';
    if (msg.contains('wrong-password')) return 'كلمة المرور غير صحيحة';
    if (msg.contains('invalid-email')) return 'البريد الإلكتروني غير صالح';
    if (msg.contains('user-disabled')) return 'هذا الحساب معطل';
    if (msg.contains('too-many-requests')) return 'محاولات كثيرة، حاول مرة أخرى لاحقاً';
    if (msg.contains('invalid-credential')) return 'بيانات الدخول غير صحيحة';
    return 'حدث خطأ، يرجى المحاولة مرة أخرى';
  }
}
