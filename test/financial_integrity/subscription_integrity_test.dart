import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hesba/core/services/cloudinary_image_service.dart';
import 'package:hesba/features/admin/data/repos_impl/admin_repo_impl.dart';
import 'package:hesba/features/subscription/data/models/subscription_model.dart';
import 'package:hesba/features/subscription/data/models/subscription_plan.dart';
import 'package:hesba/features/subscription/data/models/subscription_request_model.dart';
import 'package:hesba/features/subscription/data/repos_impl/subscription_repo_impl.dart';

import '../helpers/test_auth.dart';

class MockCloudinary extends Mock implements CloudinaryImageService {}

/// Checks 9/10/11: renewal idempotency, admin decision idempotency,
/// stale requests must not overwrite newer subscription state.
void main() {
  late FakeFirebaseFirestore firestore;
  late SubscriptionRepoImpl repo;
  late AdminRepoImpl admin;

  const uid = 'owner-1';
  const shopId = 'shop-1';

  Future<void> seedUser() => firestore.collection('users').doc(uid).set({
        'shopId': shopId,
        'shopName': 'محلي',
        'ownerName': 'مالك',
        'phone': '01000000001',
        'role': 'owner',
      });

  Future<void> seedSubscription({
    SubscriptionStatus status = SubscriptionStatus.active,
    String? lastRequestId,
    DateTime? endDate,
  }) =>
      firestore
          .collection('users')
          .doc(uid)
          .collection('subscription')
          .doc('current')
          .set({
        'status': status.id,
        'plan': SubscriptionPlan.monthly.id,
        'startDate': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'endDate': Timestamp.fromDate(endDate ?? DateTime(2026, 12, 31)),
        'isTrial': false,
        'lastRequestId': lastRequestId,
        'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });

  SubscriptionRequestModel request(String id,
          {String status = SubscriptionRequestModel.statusPending}) =>
      SubscriptionRequestModel(
        requestId: id,
        userId: uid,
        ownerName: 'مالك',
        shopName: 'محلي',
        phone: '01000000001',
        plan: SubscriptionPlan.monthly,
        amount: 99,
        paymentMethod: SubscriptionPaymentMethod.instapay.id,
        paymentProofUrl: 'https://example.com/r.png',
        status: status,
        createdAt: DateTime(2026, 1, 5),
      );

  Future<void> seedRequest(SubscriptionRequestModel r) => firestore
      .collection('subscription_requests')
      .doc(r.requestId)
      .set(r.toJson());

  Future<Map<String, dynamic>?> currentSubscription() async {
    final snap = await firestore
        .collection('users')
        .doc(uid)
        .collection('subscription')
        .doc('current')
        .get();
    return snap.data();
  }

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await seedUser();
    repo = SubscriptionRepoImpl(
      auth: signedInAuth(uid),
      firestore: firestore,
      cloudinary: MockCloudinary(),
    );
    admin = AdminRepoImpl(auth: signedInAuth(uid), firestore: firestore);
  });

  test('submitRequest writes one request and flags the subscription pending',
      () async {
    await seedSubscription();
    final r = await repo.submitRequest(
      plan: SubscriptionPlan.monthly,
      paymentMethod: SubscriptionPaymentMethod.instapay,
      paymentProofUrl: 'https://example.com/r.png',
    );

    final requests = await firestore.collection('subscription_requests').get();
    expect(requests.docs, hasLength(1));
    expect(requests.docs.single.id, r.requestId);
    final sub = await currentSubscription();
    expect(sub!['status'], 'pending');
    expect(sub['lastRequestId'], r.requestId);
  });

  test('second submit while pending is rejected', () async {
    await seedSubscription();
    await repo.submitRequest(
      plan: SubscriptionPlan.monthly,
      paymentMethod: SubscriptionPaymentMethod.instapay,
      paymentProofUrl: 'https://example.com/r.png',
    );

    await expectLater(
      repo.submitRequest(
        plan: SubscriptionPlan.monthly,
        paymentMethod: SubscriptionPaymentMethod.instapay,
        paymentProofUrl: 'https://example.com/r2.png',
      ),
      throwsA(isA<Exception>()),
    );
    final requests = await firestore.collection('subscription_requests').get();
    expect(requests.docs, hasLength(1));
  });

  test('approving the same request twice cannot extend the period twice',
      () async {
    await seedSubscription(status: SubscriptionStatus.pending, lastRequestId: 'r1');
    final r = request('r1');
    await seedRequest(r);

    await admin.approveRequest(r);
    final afterFirst = await currentSubscription();
    final firstEnd = (afterFirst!['endDate'] as Timestamp).toDate();

    await expectLater(admin.approveRequest(r), throwsA(isA<StateError>()));
    final afterSecond = await currentSubscription();
    expect((afterSecond!['endDate'] as Timestamp).toDate(), firstEnd);
    expect(afterSecond['status'], 'active');
    final stored = await firestore.collection('subscription_requests').doc('r1').get();
    expect(stored.data()!['status'], 'approved');
  });

  test('rejecting the same request twice is blocked', () async {
    await seedSubscription(status: SubscriptionStatus.pending, lastRequestId: 'r1');
    final r = request('r1');
    await seedRequest(r);

    await admin.rejectRequest(r, 'مرفوض');
    await expectLater(
      admin.rejectRequest(r, 'مرفوض'),
      throwsA(isA<StateError>()),
    );
  });

  test('STALE request cannot overwrite a newer pending request', () async {
    // Subscription now points at 'new', but the admin still has 'old' open.
    await seedSubscription(status: SubscriptionStatus.pending, lastRequestId: 'new');
    final old = request('old');
    await seedRequest(old);

    await expectLater(admin.approveRequest(old), throwsA(isA<StateError>()));
    await expectLater(
      admin.rejectRequest(old, 'stale'),
      throwsA(isA<StateError>()),
    );

    final sub = await currentSubscription();
    expect(sub!['lastRequestId'], 'new');
    expect(sub['status'], 'pending');
    final storedOld = await firestore.collection('subscription_requests').doc('old').get();
    expect(storedOld.data()!['status'], 'pending');
  });

  test('subscription mirror stays in sync with the users doc after approval',
      () async {
    await seedSubscription(status: SubscriptionStatus.pending, lastRequestId: 'r1');
    final r = request('r1');
    await seedRequest(r);
    await admin.approveRequest(r);

    final mirror = await firestore.collection('subscriptions').doc(uid).get();
    expect(mirror.data()!['status'], 'active');
    expect(mirror.data()!['lastRequestId'], 'r1');
  });
}
