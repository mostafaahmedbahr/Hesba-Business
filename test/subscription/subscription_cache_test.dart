import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hesba/core/services/cloudinary_image_service.dart';
import 'package:hesba/features/subscription/data/models/subscription_model.dart';
import 'package:hesba/features/subscription/data/repos_impl/subscription_repo_impl.dart';

class MockAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockCloudinary extends Mock implements CloudinaryImageService {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockAuth auth;
  late SubscriptionRepoImpl repo;

  void signInAs(String uid) {
    final u = MockUser();
    when(() => u.uid).thenReturn(uid);
    when(() => auth.currentUser).thenReturn(u);
  }

  Future<void> seedSub(String uid, SubscriptionStatus status) =>
      firestore
          .collection('users')
          .doc(uid)
          .collection('subscription')
          .doc('current')
          .set({
        'status': status.id,
        'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        'isTrial': false,
      });

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    auth = MockAuth();
    signInAs('u1');
    await seedSub('u1', SubscriptionStatus.active);
    await seedSub('u2', SubscriptionStatus.expired);
    repo = SubscriptionRepoImpl(
      auth: auth,
      firestore: firestore,
      cloudinary: MockCloudinary(),
    );
  });

  test('cached allowed status is reused for the same account', () async {
    final first = await repo.getSubscription();
    expect(first.status, SubscriptionStatus.active);

    // Change the stored doc behind the cache; the cached value is returned.
    await seedSub('u1', SubscriptionStatus.expired);
    final second = await repo.getSubscription();
    expect(second.status, SubscriptionStatus.active);
  });

  test('account switch invalidates the cache and reads the new account',
      () async {
    final first = await repo.getSubscription();
    expect(first.status, SubscriptionStatus.active);

    signInAs('u2');
    final second = await repo.getSubscription();

    expect(second.status, SubscriptionStatus.expired);
    expect(repo.cached?.status, SubscriptionStatus.expired);
  });

  test('refresh bypasses the cache', () async {
    await repo.getSubscription();
    await seedSub('u1', SubscriptionStatus.expired);

    final fresh = await repo.getSubscription(refresh: true);
    expect(fresh.status, SubscriptionStatus.expired);
  });
}
