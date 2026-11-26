import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/register_model.dart';
import '../../data/repos/auth_repo.dart';
import '../states/register_state.dart';
import 'package:hesba/core/services/app_logger.dart';
import 'package:easy_localization/easy_localization.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final AuthRepo _authRepo;

  RegisterCubit({required this._authRepo})
      : super(const RegisterState());

  void nextStep() {
    if (state.step >= 2) {
      return;
    }
    emit(state.copyWith(step: state.step + 1));
  }

  void previousStep() {
    if (state.step <= 0) {
      return;
    }
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
    if (state.status == RegisterStatus.loading) return;
    emit(state.copyWith(status: RegisterStatus.loading));
    try {
      await _authRepo.register(model: model, password: password);
      if (!isClosed) emit(state.copyWith(status: RegisterStatus.success));
    } catch (e, logSt) {
      AppLogger.nonFatal('features/auth/presentation/cubit/register_cubit.dart', e, logSt, severity: LoggingSeverity.warning);
      if (!isClosed) {
        emit(state.copyWith(
          status: RegisterStatus.failure,
          errorMessage: _mapError(e),
        ));
      }
    }
  }

  String _mapError(dynamic error) {
    final msg = error.toString();
    if (msg.contains('email-already-in-use')) return 'البريد الإلكتروني مستخدم بالفعل'.tr();
    if (msg.contains('invalid-email')) return 'البريد الإلكتروني غير صالح'.tr();
    if (msg.contains('weak-password')) return 'كلمة المرور ضعيفة جداً'.tr();
    if (msg.contains('operation-not-allowed')) return 'إنشاء الحسابات غير متاح حالياً'.tr();
    if (msg.contains('user-disabled')) return 'هذا الحساب معطل'.tr();
    if (msg.contains('too-many-requests')) return 'محاولات كثيرة، حاول مرة أخرى لاحقاً'.tr();
    if (msg.contains('permission-denied')) return 'حدث خطأ في قاعدة البيانات — راجع قواعد الأمان في Firebase'.tr();
    if (msg.contains('network-request-failed')) return 'تحقق من اتصال الإنترنت'.tr();
    return 'حدث خطأ أثناء إنشاء الحساب، حاول مرة أخرى'.tr();
  }
}
