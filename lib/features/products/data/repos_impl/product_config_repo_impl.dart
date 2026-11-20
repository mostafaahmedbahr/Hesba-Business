import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/extensions/log_util.dart';
import '../models/product_fields_catalog.dart';
import '../models/product_form_config.dart';
import '../repos/product_config_repo.dart';
import 'package:hesba/core/services/app_logger.dart';
import 'package:hesba/core/services/shop_id_resolver.dart';

/// يقرأ businessType من shops/{shopId} ويبني إعدادات حقول المنتج منه.
class ProductConfigRepoImpl implements ProductConfigRepo {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ProductConfigRepoImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;

  @override
  Future<ProductFormConfig> getProductFormConfig() async {
    String? businessType;
    try {
      businessType = await _readBusinessType();
    } catch (e, logSt) {
      AppLogger.nonFatal('features/products/data/repos_impl/product_config_repo_impl.dart', e, logSt, severity: LoggingSeverity.warning);
      // القراءة فشلت → نكمل بإعدادات عامة بدل ما الشاشة تفشل.
      logWarning('[ProductConfigRepo] read businessType failed: $e');
    }
    return ProductFieldsCatalog.configFor(businessType);
  }

  Future<String?> _readBusinessType() async {
    // shopId من الكاش الموحّد — قراءة users/{uid} القديمة اتشالت.
    final shopId = await resolveCachedShopId(
      firestore: _firestore,
      auth: _auth,
    );
    if (shopId == null || shopId.isEmpty) return null;
    final shopDoc = await _firestore.collection('shops').doc(shopId).get();
    if (!shopDoc.exists) return null;
    return shopDoc.data()?['businessType'] as String?;
  }
}
