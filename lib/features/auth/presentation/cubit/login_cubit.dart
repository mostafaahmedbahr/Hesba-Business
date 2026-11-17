import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repos/auth_repo.dart';
import '../states/login_state.dart';
import 'package:hesba/core/services/app_logger.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepo _authRepo;

  LoginCubit({required this._authRepo})
      : super(const LoginState());

  void togglePassword() {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    if (state.status == LoginStatus.loading) return;
    emit(state.copyWith(status: LoginStatus.loading));
    try {
      await _authRepo.login(email: email, password: password);
      if (!isClosed) emit(state.copyWith(status: LoginStatus.success));
    } catch (e, logSt) {
      AppLogger.nonFatal('features/auth/presentation/cubit/login_cubit.dart', e, logSt, severity: LoggingSeverity.warning);
      if (!isClosed) {
        emit(state.copyWith(
          status: LoginStatus.failure,
          errorMessage: _mapError(e),
        ));
      }
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
    if (msg.contains('network-request-failed')) return 'تحقق من اتصال الإنترنت';
    return 'تعذر تسجيل الدخول، حاول مرة أخرى';
  }
}
