import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repos/admin_repo.dart';

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
    try {
      final ok = await repo.isAdmin();
      emit(ok ? AdminAuthAuthenticated() : AdminAuthDenied());
    } catch (e) {
      emit(AdminAuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    // Firebase sign-out happens from the view via FirebaseAuth.
    emit(AdminAuthNotLoggedIn());
  }
}
