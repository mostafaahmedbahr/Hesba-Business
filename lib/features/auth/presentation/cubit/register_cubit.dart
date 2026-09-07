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
    if (state.step >= 2) return;
    emit(state.copyWith(step: state.step + 1));
  }

  void previousStep() {
    if (state.step <= 0) return;
    emit(state.copyWith(step: state.step - 1));
  }

  void togglePassword() {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  void toggleConfirmPassword() {
    emit(state.copyWith(obscureConfirmPassword: !state.obscureConfirmPassword));
  }

  Future<void> register({
    required RegisterModel model,
    required String password,
  }) async {
    emit(state.copyWith(status: RegisterStatus.loading));
    try {
      await _authRepo.register(model: model, password: password);
      emit(state.copyWith(status: RegisterStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: RegisterStatus.failure,
        errorMessage: _mapError(e),
      ));
    }
  }

  String _mapError(dynamic error) {
    final msg = error.toString();
    if (msg.contains('email-already-in-use')) return 'البريد الإلكتروني مستخدم بالفعل';
    if (msg.contains('invalid-email')) return 'البريد الإلكتروني غير صالح';
    if (msg.contains('weak-password')) return 'كلمة المرور ضعيفة جداً';
    return 'حدث خطأ، يرجى المحاولة مرة أخرى';
  }
}
