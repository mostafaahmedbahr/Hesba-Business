import 'package:equatable/equatable.dart';

import '../../data/models/debt_model.dart';
import '../../data/models/payment_model.dart';

enum DebtDetailsStatus { loading, success, failure }

/// حالة شاشة كشف الحساب (تفاصيل مديونية واحدة + سجل الدفعات).
class DebtDetailsState extends Equatable {
  final DebtDetailsStatus status;

  /// المديونية نفسها — تنعكس حيًّا من الستريم.
  final DebtModel? debt;

  /// كل الحركات على المديونية (الأحدث أولًا).
  final List<PaymentModel> payments;

  final bool saving;
  final String? errorMessage;

  const DebtDetailsState({
    this.status = DebtDetailsStatus.loading,
    this.debt,
    this.payments = const [],
    this.saving = false,
    this.errorMessage,
  });

  static const _sentinel = Object();

  DebtDetailsState copyWith({
    DebtDetailsStatus? status,
    Object? debt = _sentinel,
    List<PaymentModel>? payments,
    bool? saving,
    Object? errorMessage = _sentinel,
    bool clearError = false,
  }) {
    return DebtDetailsState(
      status: status ?? this.status,
      debt: identical(debt, _sentinel) ? this.debt : debt as DebtModel?,
      payments: payments ?? this.payments,
      saving: saving ?? this.saving,
      errorMessage: clearError
          ? null
          : identical(errorMessage, _sentinel)
              ? this.errorMessage
              : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, debt, payments, saving, errorMessage];
}
