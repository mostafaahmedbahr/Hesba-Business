import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/search_tokens.dart';
import '../repos/admin_search_repo.dart';
import 'package:hesba/core/services/app_logger.dart';

/// بحث الأدمن باستعلام مفهرس: كل مستند بيخزّن `searchTokens` وقت الكتابة،
/// والبحث بيستخدم `arrayContains` على كلمة واحدة — بيرجّع بس المستندات
/// المطابقة بدل مسح آلاف المستندات. الـ pagination لسه موجودة للنتائج
/// الكتيرة، والمؤشر بيكمل من نفس النقطة.
class AdminSearchRepoImpl implements AdminSearchRepo {
  AdminSearchRepoImpl({
    required FirebaseFirestore firestore,
    int? batchSize,
    int? pageSize,
  })  : _firestore = firestore,
        _batchSize = batchSize ?? 200,
        _maxHitsPerPage = pageSize ?? 50;

  final FirebaseFirestore _firestore;
  final int _batchSize;

  /// أقصى عدد نتائج في الصفحة الواحدة.
  final int _maxHitsPerPage;

  @override
  Future<AdminSearchPage> searchPage(String query,
      {AdminSearchCursor? cursor}) async {
    final q = SearchTokens.queryToken(query);
    if (q.isEmpty) return const AdminSearchPage(<AdminSearchHit>[], null);

    final results = await Future.wait([
      _tryQuery(() => _queryCollection(
            collection: 'shops',
            q: q,
            start: cursor?.shops,
            kind: 'shop',
            titleOf: (data) => data['shopName'] as String? ?? '-',
          )),
      _tryQuery(() => _queryCollection(
            collection: 'products',
            q: q,
            start: cursor?.products,
            kind: 'product',
            titleOf: (data) => data['name'] as String? ?? '-',
          )),
      _tryQuery(() => _queryCollection(
            collection: 'subscription_requests',
            q: q,
            start: cursor?.requests,
            kind: 'subscription_request',
            titleOf: (data) => data['shopName'] as String? ?? '-',
          )),
    ]);

    final shops = results[0] ?? _ScanResult.empty;
    final products = results[1] ?? _ScanResult.empty;
    final requests = results[2] ?? _ScanResult.empty;

    final hits = <AdminSearchHit>[
      ...shops.hits,
      ...products.hits,
      ...requests.hits,
    ];

    final hasMore =
        !shops.exhausted || !products.exhausted || !requests.exhausted;
    final nextCursor = hasMore
        ? AdminSearchCursor(
            shops: _cursorOf(shops),
            products: _cursorOf(products),
            requests: _cursorOf(requests),
          )
        : null;
    return AdminSearchPage(hits, nextCursor);
  }

  AdminSearchCollectionCursor _cursorOf(_ScanResult r) =>
      AdminSearchCollectionCursor(
        lastDoc: r.lastDoc,
        scanned: r.scanned,
        exhausted: r.exhausted,
      );

  Future<_ScanResult> _queryCollection({
    required String collection,
    required String q,
    required AdminSearchCollectionCursor? start,
    required String kind,
    required String Function(Map<String, dynamic>) titleOf,
  }) async {
    final hits = <AdminSearchHit>[];
    DocumentSnapshot<Map<String, dynamic>>? lastDoc =
        start?.lastDoc as DocumentSnapshot<Map<String, dynamic>>?;
    var exhausted = start?.exhausted ?? false;

    while (!exhausted && hits.length < _maxHitsPerPage) {
      Query<Map<String, dynamic>> query = _firestore
          .collection(collection)
          .where('searchTokens', arrayContains: q)
          .orderBy(FieldPath.documentId);
      if (lastDoc != null) query = query.startAfterDocument(lastDoc);
      query = query.limit(_batchSize);

      final snap = await query.get();
      if (snap.docs.isEmpty) {
        exhausted = true;
        break;
      }
      for (final doc in snap.docs) {
        final data = doc.data();
        hits.add(AdminSearchHit(kind, titleOf(data), doc.id));
        if (hits.length >= _maxHitsPerPage) {
          lastDoc = doc;
          break;
        }
      }
      if (hits.length >= _maxHitsPerPage) break;
      lastDoc = snap.docs.last;
      if (snap.docs.length < _batchSize) exhausted = true;
    }

    return _ScanResult(hits, lastDoc, hits.length, exhausted);
  }

  Future<_ScanResult?> _tryQuery(Future<_ScanResult> Function() query) async {
    try {
      return await query();
    } catch (logErr, logSt) {
      AppLogger.nonFatal(
        'features/admin/data/repos_impl/admin_search_repo_impl.dart',
        logErr,
        logSt,
        severity: LoggingSeverity.warning,
      );
      return _ScanResult.empty;
    }
  }

  /// صيانة لمرة واحدة: يضيف `searchTokens` للمستندات القديمة اللي اتحفظت
  /// قبل تفعيل الفهرس. يُستدعى يدوياً من أداة/سكربت صيانة، مش من البحث.
  @override
  Future<int> backfillSearchTokens() async {
    var total = 0;
    total += await _backfill('shops', (data) => SearchTokens.shop(
          shopName: (data['shopName'] as String?) ?? '',
          ownerName: data['ownerName'] as String?,
          phone: (data['shopPhone'] as String?) ?? (data['phone'] as String?),
        ));
    total += await _backfill('products', (data) => SearchTokens.product(
          (data['name'] as String?) ?? '',
        ));
    total += await _backfill('subscription_requests', (data) =>
        SearchTokens.subscriptionRequest(
          shopName: (data['shopName'] as String?) ?? '',
          ownerName: data['ownerName'] as String?,
          phone: data['phone'] as String?,
        ));
    return total;
  }

  Future<int> _backfill(
    String collection,
    List<String> Function(Map<String, dynamic>) tokensOf,
  ) async {
    DocumentSnapshot<Map<String, dynamic>>? last;
    var updated = 0;
    while (true) {
      Query<Map<String, dynamic>> query =
          _firestore.collection(collection).orderBy(FieldPath.documentId);
      if (last != null) query = query.startAfterDocument(last);
      query = query.limit(_batchSize);

      final snap = await query.get();
      if (snap.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        final data = doc.data();
        if (data.containsKey('searchTokens')) continue;
        batch.update(doc.reference, {'searchTokens': tokensOf(data)});
        updated++;
      }
      await batch.commit();
      last = snap.docs.last;
      if (snap.docs.length < _batchSize) break;
    }
    return updated;
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

class _ScanResult {
  const _ScanResult(this.hits, this.lastDoc, this.scanned, this.exhausted);

  final List<AdminSearchHit> hits;
  final Object? lastDoc;
  final int scanned;
  final bool exhausted;

  static const _ScanResult empty =
      _ScanResult(<AdminSearchHit>[], null, 0, true);
}
