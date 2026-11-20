import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/features/categories/data/repos_impl/category_repo_impl.dart';
import 'package:hesba/features/profile/data/repos_impl/account_repo_impl.dart';
import 'package:hesba/features/staff/data/repos_impl/staff_repo_impl.dart';
import 'package:hesba/features/suppliers/data/repos_impl/suppliers_repo_impl.dart';

import '../helpers/test_auth.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  const uid = 'owner-1';
  const shopId = 'shop-1';

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc(uid).set({
      'uid': uid,
      'shopId': shopId,
      'shopName': 'محلي',
      'ownerName': 'صاحب المحل',
      'role': 'owner',
    });
    await firestore.collection('shops').doc(shopId).set({
      'shopId': shopId,
      'shopName': 'محلي',
      'customCategories': ['قسم 1', 'قسم 2'],
    });
    await firestore.collection('users').doc('staff-1').set({
      'uid': 'staff-1',
      'ownerId': uid,
      'role': 'staff',
      'shopId': shopId,
      'name': 'موظف',
      'phone': '01000000001',
      'isActive': true,
    });
    await firestore.collection('suppliers').doc('sup-1').set({
      'supplierId': 'sup-1',
      'ownerId': uid,
      'shopId': shopId,
      'name': 'مورد',
      'phone': '01000000002',
    });
    await firestore.collection('products').doc('p-1').set({
      'productId': 'p-1',
      'ownerId': uid,
      'shopId': shopId,
      'supplierId': 'sup-1',
      'name': 'منتج',
      'stock': 5,
      'isActive': true,
    });
  });

  test('getStaff reads the staff list once', () async {
    final repo = StaffRepoImpl(
      auth: signedInAuth(uid),
      firestore: firestore,
    );

    final staff = await repo.getStaff();

    expect(staff, hasLength(1));
    expect(staff.single.name, 'موظف');
  });

  test('getSuppliers and getLinkedProductCounts are one-shot reads', () async {
    final repo = SuppliersRepoImpl(
      auth: signedInAuth(uid),
      firestore: firestore,
    );

    final suppliers = await repo.getSuppliers();
    final counts = await repo.getLinkedProductCounts();

    expect(suppliers, hasLength(1));
    expect(counts['sup-1'], 1);
  });

  test('getCustomCategories returns the shop categories once', () async {
    final repo = CategoryRepoImpl(
      auth: signedInAuth(uid),
      firestore: firestore,
    );

    final categories = await repo.getCustomCategories(shopId);

    expect(categories, ['قسم 1', 'قسم 2']);
  });

  test('getProfile returns the current user profile', () async {
    final repo = AccountRepoImpl(
      auth: signedInAuth(uid),
      firestore: firestore,
    );

    final profile = await repo.getProfile();

    expect(profile, isNotNull);
    expect(profile!.shopName, 'محلي');
  });
}
