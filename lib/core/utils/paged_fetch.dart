/// Result of fetching one page of documents.
///
/// [cursor] is the opaque value to pass back to the next fetch (in Firestore
/// it is the last `DocumentSnapshot` of the page), [hasMore] tells the pager
/// whether another page may exist.
class PageResult<T> {
  const PageResult({
    required this.items,
    this.cursor,
    required this.hasMore,
  });

  final List<T> items;
  final Object? cursor;
  final bool hasMore;
}

/// Result of fetching EVERY page: the complete item list plus a flag telling
/// the caller whether the list is guaranteed complete.
///
/// Callers must never present [items] as complete totals when [isComplete]
/// is false — surface it to the user instead.
class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.isComplete,
  });

  final List<T> items;
  final bool isComplete;
}

/// Safety cap so a pathological collection cannot loop forever.
/// 200 pages × 300 docs/page = 60 000 documents.
const int kDefaultMaxPages = 200;

/// Page size used by the report data sources (well under Firestore's
/// 10 000-document query limit; keeps each read burst small).
const int kReportPageSize = 300;

/// Fetches every document of a query by following cursor pages.
///
/// [fetchPage] receives the cursor of the previous page (`null` for the
/// first page) and must return that page's items plus the next cursor.
/// The loop:
///  - keeps calling [fetchPage] while `hasMore` is true,
///  - stops (and reports `isComplete: false`) if a page fails to advance the
///    cursor (would otherwise spin forever) or if [maxPages] is exceeded,
///  - optionally deduplicates items by [idOf] so a document can never be
///    counted twice even if a page boundary shifts.
///
/// Errors from [fetchPage] propagate to the caller — partial totals are
/// never silently returned as if they were complete.
Future<PagedResult<T>> fetchAllPages<T>({
  required Future<PageResult<T>> Function(Object? cursor) fetchPage,
  String Function(T)? idOf,
  int maxPages = kDefaultMaxPages,
}) async {
  final all = <T>[];
  final seenCursors = <Object>{};
  final seenIds = idOf == null ? null : <String>{};
  Object? cursor;

  for (var pageNo = 0; pageNo < maxPages; pageNo++) {
    final page = await fetchPage(cursor);

    if (idOf == null || seenIds == null) {
      all.addAll(page.items);
    } else {
      for (final item in page.items) {
        final id = idOf(item);
        // Defensive: a shifted page boundary must never double-count a row.
        if (id.isEmpty || seenIds.add(id)) all.add(item);
      }
    }

    if (!page.hasMore || page.cursor == null) {
      return PagedResult(items: all, isComplete: true);
    }
    if (!seenCursors.add(page.cursor!)) {
      // The cursor did not advance — fetching again would loop forever.
      return PagedResult(items: all, isComplete: false);
    }
    cursor = page.cursor;
  }

  // Safety cap reached: the caller must flag these totals as incomplete.
  return PagedResult(items: all, isComplete: false);
}
