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

  const SalesState({
    this.status = SalesStatus.initial,
    this.sale,
    this.errorMessage,
  });

  static const _sentinel = Object();

  SalesState copyWith({
    SalesStatus? status,
    SaleModel? sale,
    Object? errorMessage = _sentinel,
  }) {
    return SalesState(
      status: status ?? this.status,
      sale: sale ?? this.sale,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    sale,
    errorMessage,
  ];
}