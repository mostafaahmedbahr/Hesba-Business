import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/extensions/log_util.dart';
import '../models/product_fields_catalog.dart';
import '../models/product_form_config.dart';
import '../repos/product_config_repo.dart';

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
    } catch (e) {
      // القراءة فشلت → نكمل بإعدادات عامة بدل ما الشاشة تفشل.
      logWarning('[ProductConfigRepo] read businessType failed: $e');
    }
    return ProductFieldsCatalog.configFor(businessType);
  }

  Future<String?> _readBusinessType() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) return null;
    final shopId = userDoc.data()?['shopId'] as String?;
    if (shopId == null || shopId.isEmpty) return null;
    final shopDoc = await _firestore.collection('shops').doc(shopId).get();
    if (!shopDoc.exists) return null;
    return shopDoc.data()?['businessType'] as String?;
  }
}
