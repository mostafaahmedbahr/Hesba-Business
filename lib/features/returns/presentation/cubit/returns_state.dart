import 'package:equatable/equatable.dart';

import '../../data/models/return_model.dart';

enum ReturnsStatus { initial, loading, success, error }

class ReturnsState extends Equatable {
  final ReturnsStatus status;
  final ReturnModel? ret;
  final String? errorMessage;

  const ReturnsState({
    this.status = ReturnsStatus.initial,
    this.ret,
    this.errorMessage,
  });

  static const _sentinel = Object();

  ReturnsState copyWith({
    ReturnsStatus? status,
    ReturnModel? ret,
    Object? errorMessage = _sentinel,
  }) {
    return ReturnsState(
      status: status ?? this.status,
      ret: ret ?? this.ret,
      errorMessage: identical(errorMessage, _sentinel) ? this.errorMessage : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, ret, errorMessage];
}
