import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import 'user_role_service.dart';

/// مصدر موحّد لمعرّف المحل (واسمه اختيارياً).
///
/// `UserRoleService` بيقرأ `users/{uid}` مرة واحدة عند الدخول/الـ login
/// ويخزّن `cachedShopId` + `cachedShopName`. كل الـ repositories كانوا
/// بيعيدوا قراءة نفس المستند في كل عملية (بيع، مرتجع، مصروف، منتج…).
/// هنا بنستخدم الكاش أولاً، ومع بنقرأ المستند مرة واحدة كـ fallback لو
/// الكاش لسه متحملش (أول تشغيل، اختبارات، أو فشل قراءة الدور).
///
/// فحص [cachedUid] مهم: لو الحساب اتغير والكاش لسه القديم، ما نستخدمهوش.
Future<({String? shopId, String? shopName})> resolveCachedShopIdentity({
  required FirebaseFirestore firestore,
  required FirebaseAuth auth,
}) async {
  final uid = auth.currentUser?.uid;
  if (uid == null) return (shopId: null, shopName: null);

  final getIt = GetIt.instance;
  if (getIt.isRegistered<UserRoleService>()) {
    final role = getIt<UserRoleService>();
    if (role.cachedUid == uid &&
        role.cachedShopId != null &&
        role.cachedShopId!.isNotEmpty) {
      return (shopId: role.cachedShopId, shopName: role.cachedShopName);
    }
  }

  // Fallback: الكاش غير متاح — قراءة واحدة فقط.
  final doc = await firestore.collection('users').doc(uid).get();
  final data = doc.data();
  final rawShopId = data?['shopId'] as String?;
  return (
    shopId: (rawShopId == null || rawShopId.isEmpty) ? null : rawShopId,
    shopName: data?['shopName'] as String?,
  );
}

/// مثل [resolveCachedShopIdentity] بس للـ repos اللي محتاجة shopId فقط.
///
/// [provided] لو موجود (مثلاً shopId ممرّر من الـ view) بياخد الأولوية
/// وما بيقرأ ولا مستند — زي السلوك القديم بالضبط.
Future<String?> resolveCachedShopId({
  required FirebaseFirestore firestore,
  required FirebaseAuth auth,
  String? provided,
}) async {
  if (provided != null && provided.isNotEmpty) return provided;
  return (await resolveCachedShopIdentity(firestore: firestore, auth: auth)).shopId;
}
