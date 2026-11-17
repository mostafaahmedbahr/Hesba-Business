/// One match from the admin global search.
class AdminSearchHit {
  const AdminSearchHit(this.kind, this.title, this.id);

  /// 'shop' | 'product' | 'subscription_request'.
  final String kind;
  final String title;
  final String id;
}

/// Global search across shops, products and subscription requests.
///
/// Firestore has no substring index, so the search pages each collection in
/// bounded batches and filters client-side (no document is "too far" to
/// match, up to the repo's per-collection read cap). Callers must debounce
/// keystrokes — see [GlobalSearchCubit].
abstract class AdminSearchRepo {
  Future<List<AdminSearchHit>> search(String query);

  /// Raw documents behind a hit for the admin details screens.
  Future<Map<String, dynamic>?> fetchShop(String id);
  Future<Map<String, dynamic>?> fetchProduct(String id);
  Future<Map<String, dynamic>?> fetchRequest(String id);
}
