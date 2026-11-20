/// One match from the admin global search.
class AdminSearchHit {
  const AdminSearchHit(this.kind, this.title, this.id);

  /// 'shop' | 'product' | 'subscription_request'.
  final String kind;
  final String title;
  final String id;
}

/// موضع المسح داخل كل مجموعة — يُستخدم لاستكمال البحث من نفس النقطة
/// في الصفحة التالية بدل إعادة المسح من أول المستند.
class AdminSearchCollectionCursor {
  const AdminSearchCollectionCursor({
    this.lastDoc,
    this.scanned = 0,
    this.exhausted = false,
  });

  final Object? lastDoc;
  final int scanned;
  final bool exhausted;
}

class AdminSearchCursor {
  const AdminSearchCursor({
    required this.shops,
    required this.products,
    required this.requests,
  });

  final AdminSearchCollectionCursor shops;
  final AdminSearchCollectionCursor products;
  final AdminSearchCollectionCursor requests;
}

/// صفحة نتائج: النتائج + مؤشر الاستكمال (null = خلصت كل المجموعات).
class AdminSearchPage {
  const AdminSearchPage(this.hits, this.nextCursor);

  final List<AdminSearchHit> hits;
  final AdminSearchCursor? nextCursor;

  bool get hasMore => nextCursor != null;
}

/// Global search across shops, products and subscription requests.
///
/// Firestore has no substring index, so the search scans each collection in
/// bounded batches and filters client-side. The scan is paginated: a page
/// stops after a bounded number of documents, and [AdminSearchCursor] keeps
/// the position so the next page continues from there — every document is
/// reachable, with no silent global cap. Callers must debounce keystrokes.
abstract class AdminSearchRepo {
  Future<AdminSearchPage> searchPage(String query, {AdminSearchCursor? cursor});

  /// صيانة لمرة واحدة: تضيف `searchTokens` للمستندات القديمة، وترجع عدد
  /// المستندات اللي اتحدّثت.
  Future<int> backfillSearchTokens();

  /// Raw documents behind a hit for the admin details screens.
  Future<Map<String, dynamic>?> fetchShop(String id);
  Future<Map<String, dynamic>?> fetchProduct(String id);
  Future<Map<String, dynamic>?> fetchRequest(String id);
}
