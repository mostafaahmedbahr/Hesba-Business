import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:hesba/features/subscription/data/models/subscription_model.dart';
import 'package:hesba/features/subscription/data/models/subscription_plan.dart';
import 'package:hesba/features/subscription/presentation/cubit/subscription_cubit.dart';
import 'package:hesba/features/subscription/presentation/states/subscription_state.dart';

import '../../../../helpers/mock_subscription_repo.dart';

void main() {
  late MockSubscriptionRepo repo;
  late SubscriptionCubit cubit;

  setUp(() {
    repo = MockSubscriptionRepo();
    cubit = SubscriptionCubit(repo);
  });

  tearDown(() => cubit.close());

  test('starts with nothing loaded and nothing picked', () {
    const state = SubscriptionState();
    expect(state.loadStatus, SubscriptionLoadStatus.initial);
    expect(state.subscription, isNull);
    expect(state.selectedPlan, isNull);
    expect(state.selectedPaymentMethod, isNull);
    expect(state.receiptUrl, isNull);
    expect(state.phase, SubscriptionRequestPhase.idle);
    expect(state.canSubmit, isFalse);
  });

  group('load', () {
    test('reads the current subscription', () async {
      await cubit.load();

      expect(cubit.state.loadStatus, SubscriptionLoadStatus.ready);
      expect(cubit.state.subscription, isNotNull);
      expect(cubit.state.subscription!.canModifyData, isTrue);
      expect(repo.getCalls, 1);
    });

    test('reports a translation key when the read fails', () async {
      repo.failLoad = true;

      await cubit.load();

      expect(cubit.state.loadStatus, SubscriptionLoadStatus.error);
      expect(cubit.state.messageKey, 'subscriptionLoadFailed');
    });
  });

  group('picking', () {
    test('keeps the plan and the channel the user chose', () async {
      await cubit.load();
      cubit.selectPlan(SubscriptionPlan.threeMonths);
      cubit.selectPaymentMethod(SubscriptionPaymentMethod.instapay);

      expect(cubit.state.selectedPlan, SubscriptionPlan.threeMonths);
      expect(cubit.state.selectedPaymentMethod,
          SubscriptionPaymentMethod.instapay);
      expect(cubit.state.messageKey, isNull);
    });

    test('stores the receipt url and returns to idle', () async {
      await cubit.load();
      await cubit.pickReceipt(ImageSource.gallery);

      expect(repo.uploadCalls, 1);
      expect(cubit.state.receiptUrl, startsWith('https://'));
      expect(cubit.state.phase, SubscriptionRequestPhase.idle);
    });

    test('cancelling the picker keeps whatever was already uploaded', () async {
      await cubit.load();
      await cubit.pickReceipt(ImageSource.gallery);
      repo.uploadReturnsNull = true;

      await cubit.pickReceipt(ImageSource.camera);

      expect(cubit.state.receiptUrl, startsWith('https://'));
      expect(cubit.state.phase, SubscriptionRequestPhase.idle);
    });

    test('surfaces a translation key when the upload fails', () async {
      await cubit.load();
      repo.failUpload = true;

      await cubit.pickReceipt(ImageSource.gallery);

      expect(cubit.state.phase, SubscriptionRequestPhase.error);
      expect(cubit.state.messageKey, 'subscriptionReceiptFailed');
      expect(cubit.state.receiptUrl, isNull);
    });
  });

  group('submit', () {
    Future<void> pickPlanAndPayment() async {
      await cubit.load();
      cubit.selectPlan(SubscriptionPlan.yearly);
      cubit.selectPaymentMethod(SubscriptionPaymentMethod.vodafoneCash);
    }

    test('refuses to run without a plan', () async {
      await cubit.load();

      await cubit.submit();

      expect(cubit.state.phase, SubscriptionRequestPhase.error);
      expect(cubit.state.messageKey, 'subscriptionPlanRequired');
      expect(repo.lastRequest, isNull);
    });

    test('refuses to run without a payment channel', () async {
      await cubit.load();
      cubit.selectPlan(SubscriptionPlan.yearly);

      await cubit.submit();

      expect(cubit.state.phase, SubscriptionRequestPhase.error);
      expect(cubit.state.messageKey, 'subscriptionPaymentMethodRequired');
    });

    test('refuses to run without a receipt', () async {
      await pickPlanAndPayment();

      await cubit.submit();

      expect(cubit.state.phase, SubscriptionRequestPhase.error);
      expect(cubit.state.messageKey, 'subscriptionReceiptRequired');
      expect(repo.lastRequest, isNull);
    });

    test('sends the chosen plan, channel and receipt together', () async {
      await pickPlanAndPayment();
      await cubit.pickReceipt(ImageSource.gallery);

      await cubit.submit();

      expect(cubit.state.phase, SubscriptionRequestPhase.submitted);
      expect(cubit.state.subscription!.status, SubscriptionStatus.pending);
      expect(cubit.state.subscription!.lastRequestId, 'req_1');
      expect(repo.lastRequest!.plan, SubscriptionPlan.yearly);
      expect(repo.lastRequest!.amount, 799);
      expect(
        repo.lastRequest!.paymentMethod,
        SubscriptionPaymentMethod.vodafoneCash.id,
      );
      expect(repo.lastRequest!.paymentProofUrl, startsWith('https://'));
    });

    test('reports a translation key when sending fails', () async {
      await pickPlanAndPayment();
      await cubit.pickReceipt(ImageSource.gallery);
      repo.failSubmit = true;

      await cubit.submit();

      expect(cubit.state.phase, SubscriptionRequestPhase.error);
      expect(cubit.state.messageKey, 'subscriptionSubmitFailed');
    });
  });

  group('request phases', () {
    test('walk through uploading, idle, submitting and submitted in order',
        () async {
      await cubit.load();

      SubscriptionRequestPhase last = cubit.state.phase;
      final phases = <SubscriptionRequestPhase>[];
      final sub = cubit.stream.listen((s) {
        if (s.phase != last) {
          last = s.phase;
          phases.add(s.phase);
        }
      });

      await cubit.pickReceipt(ImageSource.gallery);
      cubit.selectPlan(SubscriptionPlan.monthly);
      cubit.selectPaymentMethod(SubscriptionPaymentMethod.etisalatCash);
      await cubit.submit();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sub.cancel();

      expect(phases, [
        SubscriptionRequestPhase.uploadingReceipt,
        SubscriptionRequestPhase.idle,
        SubscriptionRequestPhase.submitting,
        SubscriptionRequestPhase.submitted,
      ]);
    });
  });
}
