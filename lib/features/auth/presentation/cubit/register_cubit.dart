import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/register_model.dart';
import '../../data/repos/auth_repo.dart';
import '../states/register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final AuthRepo _authRepo;

  RegisterCubit({required AuthRepo authRepo})
      : _authRepo = authRepo,
        super(const RegisterState());

  void nextStep() {
    print('[RegisterCubit] nextStep() called. Current step: ${state.step}');
    if (state.step >= 2) {
      print('[RegisterCubit] nextStep() ignored — already at last step');
      return;
    }
    emit(state.copyWith(step: state.step + 1));
    print('[RegisterCubit] nextStep() emitted. New step: ${state.step}');
  }

  void previousStep() {
    print('[RegisterCubit] previousStep() called. Current step: ${state.step}');
    if (state.step <= 0) {
      print('[RegisterCubit] previousStep() ignored — already at first step');
      return;
    }
    emit(state.copyWith(step: state.step - 1));
    print('[RegisterCubit] previousStep() emitted. New step: ${state.step}');
  }

  void togglePassword() {
    print('[RegisterCubit] togglePassword() called. Current obscure: ${state.obscurePassword}');
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
    print('[RegisterCubit] togglePassword() emitted. New obscure: ${state.obscurePassword}');
  }

  void toggleConfirmPassword() {
    print('[RegisterCubit] toggleConfirmPassword() called. Current obscure: ${state.obscureConfirmPassword}');
    emit(state.copyWith(obscureConfirmPassword: !state.obscureConfirmPassword));
    print('[RegisterCubit] toggleConfirmPassword() emitted. New obscure: ${state.obscureConfirmPassword}');
  }

  Future<void> register({
    required RegisterModel model,
    required String password,
  }) async {
    print('[RegisterCubit] register() called. Email: ${model.email}, Shop: ${model.shopName}');
    emit(state.copyWith(status: RegisterStatus.loading));
    print('[RegisterCubit] emitted loading state');
    try {
      await _authRepo.register(model: model, password: password);
      print('[RegisterCubit] authRepo.register() succeeded');
      emit(state.copyWith(status: RegisterStatus.success));
      print('[RegisterCubit] emitted success state');
    } catch (e) {
      print('[RegisterCubit] authRepo.register() failed: $e');
      emit(state.copyWith(
        status: RegisterStatus.failure,
        errorMessage: _mapError(e),
      ));
      print('[RegisterCubit] emitted failure state: ${_mapError(e)}');
    }
  }

  String _mapError(dynamic error) {
    final msg = error.toString();
    print('[RegisterCubit] _mapError() called with: $msg');
    if (msg.contains('email-already-in-use')) return 'البريد الإلكتروني مستخدم بالفعل';
    if (msg.contains('invalid-email')) return 'البريد الإلكتروني غير صالح';
    if (msg.contains('weak-password')) return 'كلمة المرور ضعيفة جداً';
    if (msg.contains('permission-denied')) return 'حدث خطأ في قاعدة البيانات — راجع قواعد الأمان في Firebase';
    if (msg.contains('network-request-failed')) return 'تحقق من اتصال الإنترنت';
    print('[RegisterCubit] _mapError() returning UNMATCHED error: $msg');
    return 'حدث خطأ: $msg';
  }
}
