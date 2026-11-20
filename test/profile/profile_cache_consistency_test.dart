import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:hesba/core/services/user_role_service.dart';
import 'package:hesba/features/profile/data/repos_impl/account_repo_impl.dart';
import 'package:hesba/features/profile/presentation/cubit/profile_cubit.dart';

import '../helpers/test_auth.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late UserRoleService role;
  const uid = 'owner-1';
  const shopId = 'shop-1';

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc(uid).set({
      'uid': uid,
      'shopId': shopId,
      'shopName': 'OLD',
      'role': 'owner',
    });
    await firestore.collection('shops').doc(shopId).set({
      'shopId': shopId,
      'ownerId': uid,
      'shopName': 'OLD',
      'shopPhone': '01000000002',
    });

    final auth = signedInAuth(uid);
    role = UserRoleService(auth: auth, firestore: firestore);
    await role.load(); // كاش بالاسم القديم
    GetIt.instance.registerSingleton<UserRoleService>(role);
  });

  tearDown(() {
    if (GetIt.instance.isRegistered<UserRoleService>()) {
      GetIt.instance.unregister<UserRoleService>();
    }
  });

  test('profile edit refreshes cached shop name and indexes shop phone',
      () async {
    final cubit = ProfileCubit(
      repo: AccountRepoImpl(
        auth: signedInAuth(uid),
        firestore: firestore,
      ),
    );

    final error = await cubit.updateProfile(
      ownerName: 'Owner',
      phone: '01011111111', // هاتف المالك الشخصي
      shopName: 'NEW',
      businessType: 'retail',
      shopPhone: '01022222222', // هاتف المحل
      address: '',
      state: '',
      city: '',
      locationUrl: '',
      shopImageUrl: '',
    );

    expect(error, isNull);
    // D2: كاش الاسم اتحدّث
    expect(role.cachedShopName, 'NEW');
    // D1: tokens بتاعة المحل من shopPhone مش phone
    final shop = await firestore.collection('shops').doc(shopId).get();
    final tokens = (shop.data()?['searchTokens'] as List<dynamic>?) ?? const [];
    expect(tokens, contains('01022222222'));
    expect(tokens, isNot(contains('01011111111')));

    await cubit.close();
  });
}
