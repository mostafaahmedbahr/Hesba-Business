import 'package:equatable/equatable.dart';

import '../../data/models/return_model.dart';

enum ReturnsStatus { initial, loading, success, error }

class ReturnsState extends Equatable {
  final ReturnsStatus status;
  final ReturnModel? ret;
  final String? errorMessage;

  /// Interpolation args when [errorMessage] is a translation key.
  final Map<String, String>? errorArgs;

  const ReturnsState({
    this.status = ReturnsStatus.initial,
    this.ret,
    this.errorMessage,
    this.errorArgs,
  });

  static const _sentinel = Object();

  ReturnsState copyWith({
    ReturnsStatus? status,
    ReturnModel? ret,
    Object? errorMessage = _sentinel,
    Object? errorArgs = _sentinel,
  }) {
    return ReturnsState(
      status: status ?? this.status,
      ret: ret ?? this.ret,
      errorMessage: identical(errorMessage, _sentinel) ? this.errorMessage : errorMessage as String?,
      errorArgs: identical(errorArgs, _sentinel) ? this.errorArgs : errorArgs as Map<String, String>?,
    );
  }

  @override
  List<Object?> get props => [status, ret, errorMessage, errorArgs];
}
