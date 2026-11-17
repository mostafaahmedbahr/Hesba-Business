import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/user_role_service.dart';
import '../../data/repos/admin_repo.dart';
import 'package:hesba/core/services/app_logger.dart';

abstract class AdminAuthState extends Equatable {
  const AdminAuthState();
  @override
  List<Object?> get props => [];
}

class AdminAuthInitial extends AdminAuthState {}

class AdminAuthLoading extends AdminAuthState {}

class AdminAuthNotLoggedIn extends AdminAuthState {}

class AdminAuthDenied extends AdminAuthState {}

class AdminAuthAuthenticated extends AdminAuthState {}

class AdminAuthError extends AdminAuthState {
  const AdminAuthError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class AdminAuthCubit extends Cubit<AdminAuthState> {
  AdminAuthCubit({required this.repo}) : super(AdminAuthInitial());
  final AdminRepo repo;

  Future<void> checkSession() async {
    emit(AdminAuthLoading());
    // Admin sign-in/out uses the same FirebaseAuth as the customer app. Keep
    // the shared role cache in sync or the customer router would authorize
    // with the identity that was signed in before this session.
    await sl<UserRoleService>().reload();
    try {
      final ok = await repo.isAdmin();
      if (isClosed) return;
      emit(ok ? AdminAuthAuthenticated() : AdminAuthDenied());
    } catch (e, logSt) {
      AppLogger.nonFatal('features/admin/presentation/cubit/admin_auth_cubit.dart', e, logSt, severity: LoggingSeverity.warning);
      if (isClosed) return;
      emit(AdminAuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    // Firebase sign-out happens from the view via FirebaseAuth.
    sl<UserRoleService>().clear();
    emit(AdminAuthNotLoggedIn());
  }
}
