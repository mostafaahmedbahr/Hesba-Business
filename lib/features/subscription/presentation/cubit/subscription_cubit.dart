import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/subscription_plan.dart';
import '../../data/repos/subscription_repo.dart';
import '../states/subscription_state.dart';

/// Drives the subscription screen: reads the current state, then walks the
/// user through plan -> payment channel -> receipt -> submit.
class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit(this._repo) : super(const SubscriptionState());

  final SubscriptionRepo _repo;

  Future<void> load() async {
    emit(state.copyWith(
      loadStatus: SubscriptionLoadStatus.loading,
      messageKey: null,
    ));
    try {
      final subscription = await _repo.getSubscription(refresh: true);
      emit(state.copyWith(
        loadStatus: SubscriptionLoadStatus.ready,
        subscription: subscription,
      ));
    } catch (_) {
      emit(state.copyWith(
        loadStatus: SubscriptionLoadStatus.error,
        messageKey: 'subscriptionLoadFailed',
      ));
    }
  }

  void selectPlan(SubscriptionPlan plan) {
    emit(state.copyWith(selectedPlan: plan, messageKey: null));
  }

  void selectPaymentMethod(SubscriptionPaymentMethod method) {
    emit(state.copyWith(selectedPaymentMethod: method, messageKey: null));
  }

  /// Picks the receipt and uploads it. Cancelling keeps whatever was already
  /// uploaded and returns the flow to its previous state.
  Future<void> pickReceipt(ImageSource source) async {
    emit(state.copyWith(
      phase: SubscriptionRequestPhase.uploadingReceipt,
      messageKey: null,
    ));
    try {
      final url = await _repo.uploadPaymentReceipt(source: source);
      if (url == null) {
        emit(state.copyWith(phase: SubscriptionRequestPhase.idle));
        return;
      }
      emit(state.copyWith(
        phase: SubscriptionRequestPhase.idle,
        receiptUrl: url,
      ));
    } catch (_) {
      emit(state.copyWith(
        phase: SubscriptionRequestPhase.error,
        messageKey: 'subscriptionReceiptFailed',
      ));
    }
  }

  Future<void> submit() async {
    final plan = state.selectedPlan;
    final method = state.selectedPaymentMethod;
    final receiptUrl = state.receiptUrl;

    if (plan == null) {
      emit(state.copyWith(
        phase: SubscriptionRequestPhase.error,
        messageKey: 'subscriptionPlanRequired',
      ));
      return;
    }
    if (method == null) {
      emit(state.copyWith(
        phase: SubscriptionRequestPhase.error,
        messageKey: 'subscriptionPaymentMethodRequired',
      ));
      return;
    }
    if (receiptUrl == null) {
      emit(state.copyWith(
        phase: SubscriptionRequestPhase.error,
        messageKey: 'subscriptionReceiptRequired',
      ));
      return;
    }

    emit(state.copyWith(
      phase: SubscriptionRequestPhase.submitting,
      messageKey: null,
    ));
    try {
      await _repo.submitRequest(
        plan: plan,
        paymentMethod: method,
        paymentProofUrl: receiptUrl,
      );
      final subscription = await _repo.getSubscription();
      emit(state.copyWith(
        phase: SubscriptionRequestPhase.submitted,
        subscription: subscription,
      ));
    } catch (_) {
      emit(state.copyWith(
        phase: SubscriptionRequestPhase.error,
        messageKey: 'subscriptionSubmitFailed',
      ));
    }
  }
}
