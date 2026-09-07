import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/features/auth/data/repos/auth_repo.dart';
import 'auth_states.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo _authRepo;

  AuthCubit(this._authRepo) : super(const AuthInitial()) {
    _checkAuthState();
  }

  void _checkAuthState() {
    _authRepo.authStateChanges.listen((user) {
      if (user != null) {
        emit(const AuthAuthenticated());
      } else {
        emit(const AuthUnauthenticated());
      }
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      await _authRepo.signIn(email: email, password: password);
    } catch (e) {
      emit(AuthError(_mapFirebaseError(e.toString())));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String shopName,
  }) async {
    emit(const AuthLoading());
    try {
      await _authRepo.signUp(
        email: email,
        password: password,
        name: name,
        shopName: shopName,
      );
    } catch (e) {
      emit(AuthError(_mapFirebaseError(e.toString())));
    }
  }

  Future<void> resetPassword(String email) async {
    emit(const AuthLoading());
    try {
      await _authRepo.resetPassword(email);
      emit(const AuthPasswordResetSent());
    } catch (e) {
      emit(AuthError(_mapFirebaseError(e.toString())));
    }
  }

  Future<void> signOut() async {
    await _authRepo.signOut();
  }

  String _mapFirebaseError(String error) {
    if (error.contains('user-not-found')) {
      return 'لا يوجد حساب بهذا البريد الإلكتروني';
    } else if (error.contains('wrong-password')) {
      return 'كلمة المرور غير صحيحة';
    } else if (error.contains('email-already-in-use')) {
      return 'البريد الإلكتروني مستخدم بالفعل';
    } else if (error.contains('weak-password')) {
      return 'كلمة المرور ضعيفة جداً';
    } else if (error.contains('invalid-email')) {
      return 'البريد الإلكتروني غير صالح';
    } else if (error.contains('invalid-credential')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    }
    return 'حدث خطأ. حاول مرة أخرى';
  }
}
