import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/features/admin/data/repos_impl/admin_repo_impl.dart';

import '../helpers/test_auth.dart';

/// Platform rollup: the admin dashboard reads ONE document instead of
/// scanning the whole book; rebuild writes that document once.
void main() {
  late FakeFirebaseFirestore firestore;
  late AdminRepoImpl repo;
  const uid = 'admin-1';

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc(uid).set({'role': 'admin'});
    repo = AdminRepoImpl(auth: signedInAuth(uid), firestore: firestore);
    await firestore.collection('sales').doc('s1').set({
      'saleId': 's1',
      'ownerId': 'o1',
      'shopId': 'shop-1',
      'items': [
        {
          'productId': 'p1',
          'productName': 'p1',
          'quantity': 2,
          'unitPrice': 100,
          'costPrice': 60,
          'total': 200,
        }
      ],
      'subtotal': 200,
      'discount': 0,
      'total': 200,
      'paymentMethod': 'cash',
      'note': '',
      'createdAt': Timestamp.fromDate(DateTime(2026, 1, 5)),
    });
  });

  test('rollup doc is written once by rebuildPlatformRollup', () async {
    final built = await repo.rebuildPlatformRollup();
    final snap = await firestore.collection('admin_rollups').doc('platform').get();
    expect(snap.exists, isTrue);
    expect((snap.data()!['salesCounted'] as num).toInt(), 1);
    expect((snap.data()!['profit'] as num).toDouble(), built.profit);
    expect(snap.data()!['generatedAt'], isA<Timestamp>());
  });

  test('profitSummary reads cached rollup, not a fresh full scan', () async {
    await repo.rebuildPlatformRollup();
    // Change the underlying sale — a cached read must NOT see it.
    await firestore.collection('sales').doc('s2').set({
      'saleId': 's2',
      'ownerId': 'o1',
      'shopId': 'shop-1',
      'items': [
        {
          'productId': 'p1',
          'productName': 'p1',
          'quantity': 1,
          'unitPrice': 100,
          'costPrice': 60,
          'total': 100,
        }
      ],
      'subtotal': 100,
      'discount': 0,
      'total': 100,
      'paymentMethod': 'cash',
      'note': '',
      'createdAt': Timestamp.fromDate(DateTime(2026, 2, 5)),
    });

    final summary = await repo.profitSummary();
    expect(summary.salesCounted, 1); // still cached
    expect(summary.capped, isFalse);
    expect(summary.profitByMonth.containsKey('2026-01'), isTrue);
    expect(summary.profitByMonth.containsKey('2026-02'), isFalse);
  });

  test('missing rollup falls back to a direct scan', () async {
    final summary = await repo.profitSummary();
    expect(summary.salesCounted, 1);
    expect(summary.capped, isFalse);
  });
}
