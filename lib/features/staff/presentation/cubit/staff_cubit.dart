import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/staff_model.dart';
import '../../data/repos/staff_repo.dart';
import 'package:hesba/core/services/app_logger.dart';

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
  StreamSubscription<List<StaffModel>>? _sub;

  StaffCubit({required StaffRepo repo}) : _repo = repo, super(const StaffState()) {
    _sub = _repo.watchStaff().listen(
          (list) => emit(StaffState(staff: list, loading: false)),
          onError: (_) => emit(StaffState(staff: const [], loading: false,
              error: 'تعذر تحميل الحسابات الفرعية')),
        );
  }

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
    if (msg.contains('email-already-in-use')) return 'هذا البريد مستخدم بالفعل';
    if (msg.contains('invalid-email')) return 'البريد الإلكتروني غير صالح';
    if (msg.contains('weak-password')) return 'كلمة المرور ضعيفة (6 أحرف على الأقل)';
    if (msg.contains('network-request-failed')) return 'تحقق من اتصال الإنترنت';
    if (msg.contains('permission-denied')) return 'ليست لديك صلاحية لتنفيذ هذا الإجراء';
    return msg.replaceAll(RegExp(r'^Exception:\s*|^[A-Za-z]+\/?[A-Za-z]*:\s*'), '');
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
