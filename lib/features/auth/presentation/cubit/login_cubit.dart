import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repos/auth_repo.dart';
import '../states/login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepo _authRepo;

  LoginCubit({required this._authRepo})
      : super(const LoginState());

  void togglePassword() {
    print('[LoginCubit] togglePassword() called. Current obscure: ${state.obscurePassword}');
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
    print('[LoginCubit] togglePassword() emitted. New obscure: ${state.obscurePassword}');
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    print('[LoginCubit] login() called. Email: $email');
    emit(state.copyWith(status: LoginStatus.loading));
    print('[LoginCubit] emitted loading state');
    try {
      await _authRepo.login(email: email, password: password);
      print('[LoginCubit] authRepo.login() succeeded');
      emit(state.copyWith(status: LoginStatus.success));
      print('[LoginCubit] emitted success state');
    } catch (e) {
      print('[LoginCubit] authRepo.login() failed: $e');
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: _mapError(e),
      ));
      print('[LoginCubit] emitted failure state: ${_mapError(e)}');
    }
  }

  String _mapError(dynamic error) {
    final msg = error.toString();
    print('[LoginCubit] _mapError() called with: $msg');
    if (msg.contains('user-not-found')) return 'البريد الإلكتروني غير مسجل';
    if (msg.contains('wrong-password')) return 'كلمة المرور غير صحيحة';
    if (msg.contains('invalid-email')) return 'البريد الإلكتروني غير صالح';
    if (msg.contains('user-disabled')) return 'هذا الحساب معطل';
    if (msg.contains('too-many-requests')) return 'محاولات كثيرة، حاول مرة أخرى لاحقاً';
    if (msg.contains('invalid-credential')) return 'بيانات الدخول غير صحيحة';
    print('[LoginCubit] _mapError() returning default error');
    return 'حدث خطأ، يرجى المحاولة مرة أخرى';
  }
}
