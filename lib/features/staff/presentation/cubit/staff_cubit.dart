import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/staff_model.dart';
import '../../data/repos/staff_repo.dart';
import 'package:hesba/core/services/app_logger.dart';
import 'package:easy_localization/easy_localization.dart';

class StaffState {
  final List<StaffModel> staff;
  final bool loading;
  final String? error;

  const StaffState({this.staff = const [], this.loading = true, this.error});

  StaffState copyWith({List<StaffModel>? staff, bool? loading, String? error}) =>
      StaffState(
        staff: staff ?? this.staff,
        loading: loading ?? this.loading,
        error: error,
      );
}

class StaffCubit extends Cubit<StaffState> {
  final StaffRepo _repo;

  // ignore: prefer_initializing_formals
  StaffCubit({required StaffRepo repo}) : _repo = repo, super(const StaffState()) {
    load();
  }

  /// قراءة واحدة عند فتح الشاشة / بعد كل عملية كتابة (بدل listener دائم).
  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final list = await _repo.getStaff();
      if (!isClosed) emit(StaffState(staff: list, loading: false));
    } catch (e, logSt) {
      AppLogger.nonFatal('features/staff/presentation/cubit/staff_cubit.dart', e, logSt, severity: LoggingSeverity.warning);
      if (!isClosed) {
        emit(StaffState(staff: [], loading: false,
            error: 'تعذر تحميل الحسابات الفرعية'.tr()));
      }
    }
  }

  /// تحديث عند الطلب (سحب للتحديث).
  Future<void> refresh() => load();

  Future<void> add({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    emit(state.copyWith(error: null));
    try {
      await _repo.addStaff(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      await load();
    } catch (e, logSt) {
      AppLogger.nonFatal('features/staff/presentation/cubit/staff_cubit.dart', e, logSt, severity: LoggingSeverity.error);
      emit(state.copyWith(error: _mapError(e.toString())));
      rethrow;
    }
  }

  Future<void> update({
    required String uid,
    required String name,
    required String phone,
    required bool isActive,
  }) async {
    try {
      await _repo.updateStaff(
        uid: uid,
        name: name,
        phone: phone,
        isActive: isActive,
      );
      await load();
    } catch (e, logSt) {
      AppLogger.nonFatal('features/staff/presentation/cubit/staff_cubit.dart', e, logSt, severity: LoggingSeverity.error);
      emit(state.copyWith(error: _mapError(e.toString())));
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _repo.sendPasswordReset(email: email);
    } catch (e, logSt) {
      AppLogger.nonFatal('features/staff/presentation/cubit/staff_cubit.dart', e, logSt, severity: LoggingSeverity.error);
      emit(state.copyWith(error: _mapError(e.toString())));
      rethrow;
    }
  }

  String _mapError(String msg) {
    if (msg.contains('email-already-in-use')) return 'هذا البريد مستخدم بالفعل'.tr();
    if (msg.contains('invalid-email')) return 'البريد الإلكتروني غير صالح'.tr();
    if (msg.contains('weak-password')) return 'كلمة المرور غير كافية'.tr();
    if (msg.contains('network-request-failed')) return 'تحقق من اتصال الإنترنت'.tr();
    if (msg.contains('permission-denied')) return 'ليست لديك صلاحية لتنفيذ هذا الإجراء'.tr();
    return msg.replaceAll(RegExp(r'^Exception:\s*|^[A-Za-z]+\/?[A-Za-z]*:\s*'), '');
  }

}
