import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fake firestore supports shop-scoped queries + server timestamps', () async {
    final db = FakeFirebaseFirestore();
    final ref = db.collection('suppliers').doc();
    await ref.set({
      'id': ref.id,
      'name': 'أحمد',
      'shopId': 'shop1',
      'ownerId': 'u1',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await db.collection('suppliers').doc().set({
      'id': 'other',
      'name': 'بائع آخر',
      'shopId': 'shop2',
      'ownerId': 'u2',
      'createdAt': FieldValue.serverTimestamp(),
    });

    final snap = await db
        .collection('suppliers')
        .where('shopId', isEqualTo: 'shop1')
        .orderBy('createdAt', descending: true)
        .limit(500)
        .get();
    expect(snap.docs, hasLength(1));
    expect(snap.docs.first.data()['name'], 'أحمد');
    expect(snap.docs.first.data()['createdAt'], isA<Timestamp>());
  });

  test('fake firestore supports where on two fields (linked products)', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('products').doc('p1').set({
      'name': 'منتج',
      'shopId': 'shop1',
      'ownerId': 'u1',
      'supplierId': 's1',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await db.collection('products').doc('p2').set({
      'name': 'آخر',
      'shopId': 'shop2',
      'ownerId': 'u2',
      'supplierId': 's1',
      'createdAt': FieldValue.serverTimestamp(),
    });

    final linked = await db
        .collection('products')
        .where('shopId', isEqualTo: 'shop1')
        .where('supplierId', isEqualTo: 's1')
        .get();
    expect(linked.docs, hasLength(1));
    expect(linked.docs.first.id, 'p1');
  });

  test('mocktail can stub FirebaseAuth.currentUser', () {
    final auth = MockFirebaseAuth();
    final user = MockUser();
    when(() => user.uid).thenReturn('u1');
    when(() => auth.currentUser).thenReturn(user);
    expect(auth.currentUser?.uid, 'u1');
  });

  test('fake firestore batch writes work', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('suppliers').doc('s1').set({'name': 'old', 'shopId': 'shop1'});
    await db.collection('products').doc('p1').set({'supplierName': 'old', 'shopId': 'shop1'});
    final batch = db.batch();
    batch.update(db.collection('suppliers').doc('s1'), {'name': 'new'});
    batch.update(db.collection('products').doc('p1'), {'supplierName': 'new'});
    await batch.commit();
    expect((await db.collection('suppliers').doc('s1').get()).data()!['name'], 'new');
    expect((await db.collection('products').doc('p1').get()).data()!['supplierName'], 'new');
  });
}
