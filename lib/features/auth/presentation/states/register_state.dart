import 'package:equatable/equatable.dart';

enum RegisterStatus { initial, loading, success, failure }

class RegisterState extends Equatable {
  final int step;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final RegisterStatus status;
  final String? errorMessage;

  const RegisterState({
    this.step = 0,
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
    this.status = RegisterStatus.initial,
    this.errorMessage,
  });

  RegisterState copyWith({
    int? step,
    bool? obscurePassword,
    bool? obscureConfirmPassword,
    RegisterStatus? status,
    String? errorMessage,
  }) {
    return RegisterState(
      step: step ?? this.step,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword: obscureConfirmPassword ?? this.obscureConfirmPassword,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        step,
        obscurePassword,
        obscureConfirmPassword,
        status,
        errorMessage,
      ];
}
