import 'package:firebase_auth/firebase_auth.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repos/admin_repo.dart';

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
    emit(AdminLoginLoading());
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      final ok = await repo.isAdmin();
      if (ok) {
        emit(AdminLoginSuccess());
      } else {
        await FirebaseAuth.instance.signOut();
        emit(const AdminLoginDenied());
      }
    } on FirebaseAuthException catch (e) {
      emit(AdminLoginFailure(e.message ?? 'خطأ في تسجيل الدخول'));
    } catch (e) {
      emit(AdminLoginFailure(e.toString()));
    }
  }
}
