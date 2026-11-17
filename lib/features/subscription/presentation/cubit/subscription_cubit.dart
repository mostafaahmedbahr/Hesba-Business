import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/app_settings_service.dart';
import '../../data/models/subscription_plan.dart';
import '../../data/repos/subscription_repo.dart';
import '../states/subscription_state.dart';
import 'package:hesba/core/services/app_logger.dart';

/// Drives the subscription screen: reads the current state, then walks the
/// user through plan -> payment channel -> receipt -> submit.
class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit(this._repo) : super(const SubscriptionState());

  final SubscriptionRepo _repo;

  /// Picked locally; uploaded only when the user confirms submission so an
  /// abandoned/failed request cannot leave an unattended receipt on Cloudinary.
  XFile? _pickedReceipt;

  Future<void> load() async {
    emit(state.copyWith(
      loadStatus: SubscriptionLoadStatus.loading,
      messageKey: null,
    ));
    // Pull the latest plan prices / trial / wallet numbers from the dashboard
    // settings so the paywall shows live values (never throws on failure).
    await AppSettingsService.refresh();
    try {
      final subscription = await _repo.getSubscription(refresh: true);
      emit(state.copyWith(
        loadStatus: SubscriptionLoadStatus.ready,
        subscription: subscription,
      ));
    } catch (logErr, logSt) {
      AppLogger.nonFatal('features/subscription/presentation/cubit/subscription_cubit.dart', logErr, logSt, severity: LoggingSeverity.warning);
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

  /// Picks the receipt locally only — no upload happens until [submit].
  Future<void> pickReceipt(ImageSource source) async {
    if (state.phase == SubscriptionRequestPhase.uploadingReceipt ||
        state.phase == SubscriptionRequestPhase.submitting) {
      return;
    }
    emit(state.copyWith(phase: SubscriptionRequestPhase.uploadingReceipt, messageKey: null));
    try {
      final picked = await _repo.pickPaymentReceipt(source: source);
      if (picked == null) {
        if (!isClosed) emit(state.copyWith(phase: SubscriptionRequestPhase.idle));
        return;
      }
      _pickedReceipt = picked;
      if (!isClosed) {
        emit(state.copyWith(
          phase: SubscriptionRequestPhase.idle,
          receiptPath: picked.path,
          receiptUrl: null,
        ));
      }
    } catch (logErr, logSt) {
      AppLogger.nonFatal('features/subscription/presentation/cubit/subscription_cubit.dart', logErr, logSt, severity: LoggingSeverity.warning);
      if (!isClosed) {
        emit(state.copyWith(
          phase: SubscriptionRequestPhase.error,
          messageKey: 'subscriptionReceiptFailed',
        ));
      }
    }
  }

  Future<void> submit() async {
    // Re-entrancy guard: the submit button also checks `canSubmit`, but a
    // second call must never create a duplicate request.
    if (state.phase == SubscriptionRequestPhase.submitting ||
        state.phase == SubscriptionRequestPhase.uploadingReceipt) {
      return;
    }
    final plan = state.selectedPlan;
    final method = state.selectedPaymentMethod;
    final picked = _pickedReceipt;

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
    if (picked == null) {
      emit(state.copyWith(
        phase: SubscriptionRequestPhase.error,
        messageKey: 'subscriptionReceiptRequired',
      ));
      return;
    }

    emit(state.copyWith(
      phase: SubscriptionRequestPhase.uploadingReceipt,
      messageKey: null,
    ));
    String receiptUrl;
    try {
      final url = await _repo.uploadPaymentReceipt(file: picked);
      if (url == null) throw StateError('receipt upload returned null');
      receiptUrl = url;
    } catch (logErr, logSt) {
      AppLogger.nonFatal('features/subscription/presentation/cubit/subscription_cubit.dart', logErr, logSt, severity: LoggingSeverity.warning);
      if (!isClosed) {
        emit(state.copyWith(
          phase: SubscriptionRequestPhase.error,
          messageKey: 'subscriptionReceiptFailed',
        ));
      }
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
      _pickedReceipt = null;
      emit(state.copyWith(
        phase: SubscriptionRequestPhase.submitted,
        subscription: subscription,
        receiptUrl: receiptUrl,
      ));
    } catch (logErr, logSt) {
      AppLogger.nonFatal('features/subscription/presentation/cubit/subscription_cubit.dart', logErr, logSt, severity: LoggingSeverity.warning);
      emit(state.copyWith(
        phase: SubscriptionRequestPhase.error,
        messageKey: 'subscriptionSubmitFailed',
      ));
    }
  }
}
