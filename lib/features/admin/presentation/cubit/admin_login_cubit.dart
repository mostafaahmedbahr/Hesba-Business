import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repos/admin_repo.dart';
import 'package:hesba/core/services/app_logger.dart';

abstract class AdminLoginState extends Equatable {
  const AdminLoginState();
  @override
  List<Object?> get props => [];
}

class AdminLoginIdle extends AdminLoginState {}

class AdminLoginLoading extends AdminLoginState {}

class AdminLoginSuccess extends AdminLoginState {}

class AdminLoginDenied extends AdminLoginState {
  const AdminLoginDenied();
}

class AdminLoginFailure extends AdminLoginState {
  const AdminLoginFailure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class AdminLoginCubit extends Cubit<AdminLoginState> {
  AdminLoginCubit({required this.repo}) : super(AdminLoginIdle());
  final AdminRepo repo;

  Future<void> login(String email, String password) async {
    if (state is AdminLoginLoading) return;
    emit(AdminLoginLoading());
    try {
      await repo.signInAdmin(email, password);
      final ok = await repo.isAdmin();
      if (isClosed) return;
      if (ok) {
        emit(AdminLoginSuccess());
      } else {
        await repo.signOutAdmin();
        if (!isClosed) emit(const AdminLoginDenied());
      }
    } on FirebaseAuthException catch (e, logSt) {
      AppLogger.nonFatal('features/admin/presentation/cubit/admin_login_cubit.dart', e, logSt, severity: LoggingSeverity.warning);
      if (!isClosed) emit(AdminLoginFailure(e.message ?? 'خطأ في تسجيل الدخول'));
    } catch (e, logSt) {
      AppLogger.nonFatal('features/admin/presentation/cubit/admin_login_cubit.dart', e, logSt, severity: LoggingSeverity.warning);
      if (!isClosed) emit(AdminLoginFailure(e.toString()));
    }
  }
}
