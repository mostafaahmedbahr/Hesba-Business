import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repos/auth_repo.dart';
import '../states/forgot_password_state.dart';

/// Sends the password reset email for the login screen.
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final AuthRepo _authRepo;

  ForgotPasswordCubit({required this._authRepo})
      : super(const ForgotPasswordState());
  Future<void> sendResetEmail({required String email}) async {
    emit(state.copyWith(status: ForgotPasswordStatus.loading));
    try {
      await _authRepo.sendPasswordResetEmail(email: email);
      emit(state.copyWith(status: ForgotPasswordStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: ForgotPasswordStatus.failure,
        errorMessage: mapResetError(e),
      ));
    }
  }

  /// Returns a translation key describing the Firebase failure.
  String mapResetError(dynamic error) {
    final message = error.toString();
    if (message.contains('user-not-found')) return 'forgotPasswordNotFound';
    if (message.contains('invalid-email')) return 'loginEmailInvalid';
    if (message.contains('too-many-requests')) {
      return 'forgotPasswordTooMany';
    }
    if (message.contains('network-request-failed')) {
      return 'forgotPasswordNoNetwork';
    }
    return 'forgotPasswordFailed';
  }
}
