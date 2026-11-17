import 'package:cloud_firestore/cloud_firestore.dart';

import '../repos/admin_search_repo.dart';
import 'package:hesba/core/services/app_logger.dart';

/// بحث شامل للأدمن (محل / منتج / طلب اشتراك).
///
/// Firestore لا يدعم فهرسة substring، لذلك البحث بيتعمل client-side.
/// بدل ما نقرأ أول [_maxScan] مستند فقط (زي قبل كده)، بنلف على الـ collection
/// كله بدفعات [_batchSize] مع حد أقصى للقراءة [_maxScanPerCollection] —
/// النتيجة إن
/// البحث بيلقى أي مستند موجود فعلاً (مش أول 50 بس)، مع سقف واضح للتكلفة.
///
/// استثناءيًا: لو collection وقع (صلاحيات مثلاً) بنتخطاه وبنرجع باقي
/// النتائج؛ لو الـ collections التلاتة وقعوا كلهم بنرمي exception عشان
/// الـ Cubit يعرض رسالة خطأ بدل "لا توجد نتائج" مضللة.
class AdminSearchRepoImpl implements AdminSearchRepo {
  AdminSearchRepoImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// حجم دفعة القراءة الواحدة من Firestore.
  static const int _batchSize = 200;

  /// أقصى عدد مستندات نقرأها من كل collection في البحث الواحد.
  /// السقف مقصود كحاجز تكلفة فقط؛ الدفعات بتتوقف فور ما نلاقي 50
  /// نتيجة، فالبحث العادي بيقرأ أقل بكتير. رُفع من 1000 إلى 10000 عشان
  /// المستندات اللي بعد أول 1000 ما تضيعش في المجموعات الكبيرة.
  static const int _maxScanPerCollection = 10000;

  /// أقصى عدد نتائج معروضة في القائمة.
  static const int _maxHits = 50;

  @override
  Future<List<AdminSearchHit>> search(String query) async {
    final q = _normalize(query);
    if (q.isEmpty) return const [];

    final results = await Future.wait([
      _tryCollection(() => _scanShops(q)),
      _tryCollection(() => _scanProducts(q)),
      _tryCollection(() => _scanRequests(q)),
    ]);

    if (results.every((r) => r == null)) {
      // كل الـ collections فشلت — مشكلة شبكة/صلاحيات مش نتائج فاضية.
      throw Exception('admin search: all collections failed');
    }

    final hits = <AdminSearchHit>[
      for (final r in results) ...?r,
    ];
    return hits.length > _maxHits ? hits.sublist(0, _maxHits) : hits;
  }

  /// بيلف على الـ collection دفعات دفعات (بترتيب documentId) مع `startAfter`
  /// لحد ما تخلص المستندات أو نلمس حد القراءة أو حد النتائج.
  Future<List<AdminSearchHit>> _scanCollection({
    required String collection,
    required String q,
    required bool Function(Map<String, dynamic> data, String q) matches,
    required String kind,
    required String Function(Map<String, dynamic> data) titleOf,
  }) async {
    final hits = <AdminSearchHit>[];
    DocumentSnapshot<Map<String, dynamic>>? lastDoc;
    var scanned = 0;

    while (scanned < _maxScanPerCollection && hits.length < _maxHits) {
      final remaining = _maxScanPerCollection - scanned;
      final pageSize = remaining < _batchSize ? remaining : _batchSize;

      Query<Map<String, dynamic>> query = _firestore
          .collection(collection)
          .orderBy(FieldPath.documentId)
          .limit(pageSize);
      if (lastDoc != null) query = query.startAfterDocument(lastDoc);

      final snap = await query.get();
      if (snap.docs.isEmpty) break;

      for (final doc in snap.docs) {
        scanned++;
        final data = doc.data();
        if (matches(data, q)) {
          hits.add(AdminSearchHit(kind, titleOf(data), doc.id));
        }
      }
      if (snap.docs.length < pageSize) break; // خلصت الـ collection
      lastDoc = snap.docs.last;
    }
    return hits;
  }

  Future<List<AdminSearchHit>?> _tryCollection(
      Future<List<AdminSearchHit>> Function() scan) async {
    try {
      return await scan();
    } catch (logErr, logSt) {
      AppLogger.nonFatal('features/admin/data/repos_impl/admin_search_repo_impl.dart', logErr, logSt, severity: LoggingSeverity.warning);
      return null; // نتخطى الـ collection ده ونكمل الباقي
    }
  }

  Future<List<AdminSearchHit>> _scanShops(String q) => _scanCollection(
        collection: 'shops',
        q: q,
        kind: 'shop',
        matches: (data, q) =>
            _matchesText(data['shopName'], q) ||
            _matchesText(data['ownerName'], q) ||
            _matchesPhone(data['phone'], q),
        titleOf: (data) => data['shopName'] as String? ?? '-',
      );

  Future<List<AdminSearchHit>> _scanProducts(String q) => _scanCollection(
        collection: 'products',
        q: q,
        kind: 'product',
        matches: (data, q) => _matchesText(data['name'], q),
        titleOf: (data) => data['name'] as String? ?? '-',
      );

  Future<List<AdminSearchHit>> _scanRequests(String q) => _scanCollection(
        collection: 'subscription_requests',
        q: q,
        kind: 'subscription_request',
        matches: (data, q) =>
            _matchesText(data['shopName'], q) ||
            _matchesPhone(data['phone'], q) ||
            _matchesText(data['ownerName'], q),
        titleOf: (data) => data['shopName'] as String? ?? '-',
      );

  /// تطبيع النص للمقارنة: trim + lowercase + توحيد الأرقام العربية/الفارسية إلى لاتينية.
  String _normalize(Object? value) {
    if (value == null) return '';
    var s = value.toString().trim().toLowerCase();
    const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    const easternArabic = '۰۱۲۳۴۵۶۷۸۹';
    final buffer = StringBuffer();
    for (final ch in s.split('')) {
      final ai = arabicIndic.indexOf(ch);
      if (ai != -1) {
        buffer.write(ai);
        continue;
      }
      final ea = easternArabic.indexOf(ch);
      if (ea != -1) {
        buffer.write(ea);
        continue;
      }
      buffer.write(ch);
    }
    return buffer.toString();
  }

  /// إزالة كل ما عدا الأرقام (للبحث في التليفونات مهما كان الفورمات).
  String _digitsOnly(Object? value) =>
      _normalize(value).replaceAll(RegExp(r'[^0-9]'), '');

  bool _matchesText(Object? value, String q) =>
      value != null && _normalize(value).contains(q);

  /// للتليفونات: لو الاستعلام فيه أرقام بنقارن بالأرقام بس بدلاً من النص الخام
  /// (عشان "010" تلاقي "٠١٠" و"010-1234" إلخ)، ولو مفيهوش أرقام بنرجع للنص.
  bool _matchesPhone(Object? value, String q) {
    if (value == null) return false;
    final qDigits = _digitsOnly(q);
    if (qDigits.isNotEmpty) {
      return _digitsOnly(value).contains(qDigits);
    }
    return _normalize(value).contains(q);
  }

  @override
  Future<Map<String, dynamic>?> fetchShop(String id) async {
    final snap = await _firestore.collection('shops').doc(id).get();
    return snap.exists ? snap.data() : null;
  }

  @override
  Future<Map<String, dynamic>?> fetchProduct(String id) async {
    final snap = await _firestore.collection('products').doc(id).get();
    return snap.exists ? snap.data() : null;
  }

  @override
  Future<Map<String, dynamic>?> fetchRequest(String id) async {
    final snap =
        await _firestore.collection('subscription_requests').doc(id).get();
    return snap.exists ? snap.data() : null;
  }
}
