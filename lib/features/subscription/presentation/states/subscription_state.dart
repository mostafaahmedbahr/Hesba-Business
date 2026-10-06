import 'package:equatable/equatable.dart';

import '../../data/models/subscription_model.dart';
import '../../data/models/subscription_plan.dart';

enum SubscriptionLoadStatus { initial, loading, ready, error }

/// Where the purchase flow currently is. One field instead of several
/// booleans, so the view never has to reason about impossible combinations.
enum SubscriptionRequestPhase {
  idle,
  uploadingReceipt,
  submitting,
  submitted,
  error,
}

class SubscriptionState extends Equatable {
  final SubscriptionLoadStatus loadStatus;
  final SubscriptionModel? subscription;

  final SubscriptionPlan? selectedPlan;
  final SubscriptionPaymentMethod? selectedPaymentMethod;
  final String? receiptUrl;

  final SubscriptionRequestPhase phase;

  /// Translation key, never a raw message.
  final String? messageKey;

  const SubscriptionState({
    this.loadStatus = SubscriptionLoadStatus.initial,
    this.subscription,
    this.selectedPlan,
    this.selectedPaymentMethod,
    this.receiptUrl,
    this.phase = SubscriptionRequestPhase.idle,
    this.messageKey,
  });

  bool get isLoading => loadStatus == SubscriptionLoadStatus.loading;
  bool get isReady => loadStatus == SubscriptionLoadStatus.ready;

  bool get isUploadingReceipt =>
      phase == SubscriptionRequestPhase.uploadingReceipt;
  bool get isSubmitting => phase == SubscriptionRequestPhase.submitting;
  bool get isSubmitted => phase == SubscriptionRequestPhase.submitted;
  bool get hasError => phase == SubscriptionRequestPhase.error;

  /// Everything the submit button needs before it may run.
  bool get canSubmit =>
      selectedPlan != null &&
      selectedPaymentMethod != null &&
      receiptUrl != null &&
      !isUploadingReceipt &&
      !isSubmitting &&
      !isSubmitted;

  static const _sentinel = Object();

  SubscriptionState copyWith({
    SubscriptionLoadStatus? loadStatus,
    SubscriptionModel? subscription,
    SubscriptionPlan? selectedPlan,
    SubscriptionPaymentMethod? selectedPaymentMethod,
    String? receiptUrl,
    SubscriptionRequestPhase? phase,
    Object? messageKey = _sentinel,
  }) {
    return SubscriptionState(
      loadStatus: loadStatus ?? this.loadStatus,
      subscription: subscription ?? this.subscription,
      selectedPlan: selectedPlan ?? this.selectedPlan,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      phase: phase ?? this.phase,
      messageKey: identical(messageKey, _sentinel)
          ? this.messageKey
          : messageKey as String?,
    );
  }

  @override
  List<Object?> get props => [
        loadStatus,
        subscription,
        selectedPlan,
        selectedPaymentMethod,
        receiptUrl,
        phase,
        messageKey,
      ];
}
