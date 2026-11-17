import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hesba/features/subscription/data/models/subscription_model.dart';
import 'package:hesba/features/subscription/data/models/subscription_plan.dart';
import 'package:hesba/features/subscription/data/models/subscription_request_model.dart';
import 'package:hesba/features/subscription/data/repos/subscription_repo.dart';
import 'package:hesba/features/subscription/presentation/cubit/subscription_cubit.dart';
import 'package:hesba/features/subscription/presentation/states/subscription_state.dart';

class MockSubscriptionRepo extends Mock implements SubscriptionRepo {}

/// Subscription request submission: success / failure / repeated submission /
/// concurrent requests. A duplicate submit would create two pending requests.
void main() {
  late MockSubscriptionRepo repo;
  late SubscriptionCubit cubit;

  const receipt = 'https://example.com/receipt.png';

  SubscriptionRequestModel makeRequest() => SubscriptionRequestModel(
        requestId: 'req-1',
        userId: 'owner-1',
        ownerName: 'مالك',
        shopName: 'محل',
        phone: '01000000001',
        plan: SubscriptionPlan.monthly,
        amount: 100,
        paymentMethod: SubscriptionPaymentMethod.instapay.id,
        paymentProofUrl: receipt,
        createdAt: DateTime(2026, 1, 5),
      );

  void stubCommon() {
    when(
      () => repo.pickPaymentReceipt(source: any(named: 'source')),
    ).thenAnswer((_) async => XFile('/tmp/receipt.png'));
    when(
      () => repo.uploadPaymentReceipt(
        source: any(named: 'source'),
        file: any(named: 'file'),
      ),
    ).thenAnswer((_) async => receipt);
    when(() => repo.getSubscription()).thenAnswer((_) async => const SubscriptionModel());
  }

  Future<void> prepare() async {
    cubit.selectPlan(SubscriptionPlan.monthly);
    cubit.selectPaymentMethod(SubscriptionPaymentMethod.instapay);
    await cubit.pickReceipt(ImageSource.gallery);
    expect(cubit.state.receiptPath, '/tmp/receipt.png');
    expect(cubit.state.receiptUrl, isNull);
  }

  void stubSubmit() {
    when(
      () => repo.submitRequest(
        plan: any(named: 'plan'),
        paymentMethod: any(named: 'paymentMethod'),
        paymentProofUrl: any(named: 'paymentProofUrl'),
      ),
    ).thenAnswer((_) async => makeRequest());
  }

  setUpAll(() {
    registerFallbackValue(ImageSource.gallery);
    registerFallbackValue(SubscriptionPlan.monthly);
    registerFallbackValue(SubscriptionPaymentMethod.instapay);
    registerFallbackValue(XFile('/tmp/fallback.png'));
  });

  setUp(() {
    repo = MockSubscriptionRepo();
    cubit = SubscriptionCubit(repo);
    stubCommon();
  });

  tearDown(() async {
    await cubit.close();
  });

  test('success: submitting -> submitted with refreshed subscription', () async {
    stubSubmit();
    await prepare();
    await cubit.submit();

    expect(cubit.state.phase, SubscriptionRequestPhase.submitted);
    expect(cubit.state.messageKey, isNull);
    verify(
      () => repo.submitRequest(
        plan: any(named: 'plan'),
        paymentMethod: any(named: 'paymentMethod'),
        paymentProofUrl: any(named: 'paymentProofUrl'),
      ),
    ).called(1);
    verify(() => repo.getSubscription()).called(1);
  });

  test('failure: error phase with a translation key, not a raw message', () async {
    when(
      () => repo.submitRequest(
        plan: any(named: 'plan'),
        paymentMethod: any(named: 'paymentMethod'),
        paymentProofUrl: any(named: 'paymentProofUrl'),
      ),
    ).thenThrow(Exception('network down'));
    await prepare();
    await cubit.submit();

    expect(cubit.state.phase, SubscriptionRequestPhase.error);
    expect(cubit.state.messageKey, 'subscriptionSubmitFailed');
  });

  test('validation: no plan/method/receipt blocks the write', () async {
    await cubit.submit();
    expect(cubit.state.phase, SubscriptionRequestPhase.error);
    expect(cubit.state.messageKey, 'subscriptionPlanRequired');
    verifyNever(
      () => repo.submitRequest(
        plan: any(named: 'plan'),
        paymentMethod: any(named: 'paymentMethod'),
        paymentProofUrl: any(named: 'paymentProofUrl'),
      ),
    );
  });

  test('repeated submission while in flight writes only once', () async {
    final completer = Completer<SubscriptionRequestModel>();
    when(
      () => repo.submitRequest(
        plan: any(named: 'plan'),
        paymentMethod: any(named: 'paymentMethod'),
        paymentProofUrl: any(named: 'paymentProofUrl'),
      ),
    ).thenAnswer((_) => completer.future);
    await prepare();

    final first = cubit.submit();
    final second = cubit.submit();
    expect(
      cubit.state.phase == SubscriptionRequestPhase.submitting ||
          cubit.state.phase == SubscriptionRequestPhase.uploadingReceipt,
      isTrue,
    );
    completer.complete(makeRequest());
    await Future.wait([first, second]);

    verify(
      () => repo.submitRequest(
        plan: any(named: 'plan'),
        paymentMethod: any(named: 'paymentMethod'),
        paymentProofUrl: any(named: 'paymentProofUrl'),
      ),
    ).called(1);
    expect(cubit.state.phase, SubscriptionRequestPhase.submitted);
  });

  test('concurrent requests: only one request is created', () async {
    final a = Completer<SubscriptionRequestModel>();
    final b = Completer<SubscriptionRequestModel>();
    var calls = 0;
    when(
      () => repo.submitRequest(
        plan: any(named: 'plan'),
        paymentMethod: any(named: 'paymentMethod'),
        paymentProofUrl: any(named: 'paymentProofUrl'),
      ),
    ).thenAnswer((_) => (calls++ == 0 ? a : b).future);
    await prepare();

    final f1 = cubit.submit();
    final f2 = cubit.submit();
    final model = makeRequest();
    b.complete(model);
    a.complete(model);
    await Future.wait([f1, f2]);
    expect(calls, 1);
  });

  test('retry after failure is allowed', () async {
    var calls = 0;
    when(
      () => repo.submitRequest(
        plan: any(named: 'plan'),
        paymentMethod: any(named: 'paymentMethod'),
        paymentProofUrl: any(named: 'paymentProofUrl'),
      ),
    ).thenAnswer((_) {
      calls++;
      if (calls == 1) throw Exception('offline');
      return Future.value(makeRequest());
    });
    await prepare();

    await cubit.submit();
    expect(cubit.state.phase, SubscriptionRequestPhase.error);
    await cubit.submit();
    expect(calls, 2);
    expect(cubit.state.phase, SubscriptionRequestPhase.submitted);
  });
}
