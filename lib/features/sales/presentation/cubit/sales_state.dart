import 'package:equatable/equatable.dart';

import '../../data/models/sale_model.dart';

enum SalesStatus {
  initial,
  loading,
  success,
  error,
}

class SalesState extends Equatable {
  final SalesStatus status;
  final SaleModel? sale;
  final String? errorMessage;

  /// Interpolation args when [errorMessage] is a translation key.
  final Map<String, String>? errorArgs;

  const SalesState({
    this.status = SalesStatus.initial,
    this.sale,
    this.errorMessage,
    this.errorArgs,
  });

  static const _sentinel = Object();

  SalesState copyWith({
    SalesStatus? status,
    SaleModel? sale,
    Object? errorMessage = _sentinel,
    Object? errorArgs = _sentinel,
  }) {
    return SalesState(
      status: status ?? this.status,
      sale: sale ?? this.sale,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      errorArgs: identical(errorArgs, _sentinel)
          ? this.errorArgs
          : errorArgs as Map<String, String>?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    sale,
    errorMessage,
    errorArgs,
  ];
}