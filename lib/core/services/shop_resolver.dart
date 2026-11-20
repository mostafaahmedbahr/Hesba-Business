import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hesba/core/services/app_logger.dart';
import 'shop_id_resolver.dart';

/// Single place that answers "who is the current owner, and what is
/// their shop?".
///
/// Replaces the copy-pasted `FirebaseAuth.instance.currentUser` +
/// `users/{uid}.shopId` lookups that used to live in every form view and
/// cubit — one implementation, one error policy (null on any failure).
class ShopResolver {
  ShopResolver({required FirebaseAuth auth, required FirebaseFirestore firestore})
      : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String? get currentUid => _auth.currentUser?.uid;

  Future<String?> getShopId() async {
    try {
      return await resolveCachedShopId(firestore: _firestore, auth: _auth);
    } catch (logErr, logSt) {
      AppLogger.nonFatal('core/services/shop_resolver.dart', logErr, logSt, severity: LoggingSeverity.warning);
      return null;
    }
  }

  /// اسم المحل الحالي (من ملف المستخدم، مع fallback لمستند shops).
  Future<String?> getShopName() async {
    try {
      final identity = await resolveCachedShopIdentity(
        firestore: _firestore,
        auth: _auth,
      );
      final name = identity.shopName;
      if (name != null && name.trim().isNotEmpty) return name.trim();
      // الاسم مش موجود في الكاش — جرّب مستند shops زي ما كان يحصل.
      final shopId = identity.shopId;
      if (shopId != null) {
        final shopDoc = await _firestore.collection('shops').doc(shopId).get();
        final sName = shopDoc.data()?['shopName'] as String?;
        if (sName != null && sName.trim().isNotEmpty) return sName.trim();
      }
      return null;
    } catch (logErr, logSt) {
      AppLogger.nonFatal('core/services/shop_resolver.dart', logErr, logSt, severity: LoggingSeverity.warning);
      return null;
    }
  }

  Future<String?> getShopBusinessType() async {
    try {
      final shopId = await getShopId();
      if (shopId == null) return null;
      final doc = await _firestore.collection('shops').doc(shopId).get();
      return doc.data()?['businessType'] as String?;
    } catch (logErr, logSt) {
      AppLogger.nonFatal('core/services/shop_resolver.dart', logErr, logSt, severity: LoggingSeverity.warning);
      return null;
    }
  }
}
