import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repos/admin_search_repo.dart';
import 'package:hesba/core/services/app_logger.dart';

abstract class GlobalSearchState extends Equatable {
  const GlobalSearchState();
  @override
  List<Object?> get props => [];
}

class SearchIdle extends GlobalSearchState {}

class SearchLoading extends GlobalSearchState {}

class SearchError extends GlobalSearchState {
  const SearchError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class SearchResults extends GlobalSearchState {
  const SearchResults(
    this.hits, {
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final List<SearchHit> hits;

  /// فيه مستندات لسه ما اتعرضتش — فيه صفحة تانية.
  final bool hasMore;
  final bool isLoadingMore;

  @override
  List<Object?> get props => [hits, hasMore, isLoadingMore];
}

class SearchHit {
  const SearchHit(this.kind, this.title, this.id);

  /// Stable id from [AdminSearchHit]: 'shop' | 'product' | 'subscription_request'.
  final String kind;
  final String title;
  final String id;
}

class GlobalSearchCubit extends Cubit<GlobalSearchState> {
  // ignore: prefer_initializing_formals
  GlobalSearchCubit({required AdminSearchRepo searchRepo})
      : _searchRepo = searchRepo,
        super(SearchIdle());

  final AdminSearchRepo _searchRepo;
  Timer? _debounce;

  /// Monotonic request id: a slower response for an older query must never
  /// overwrite results of a newer one.
  int _generation = 0;

  String _currentQuery = '';
  AdminSearchCursor? _cursor;

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> search(String query) async {
    _debounce?.cancel();
    final generation = ++_generation;
    final q = query.trim();
    if (q.isEmpty) {
      _currentQuery = '';
      _cursor = null;
      emit(SearchIdle());
      return;
    }
    // Debounced: one Firestore round-trip per pause in typing, not per keystroke.
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _run(q, generation, cursor: null, append: false),
    );
  }

  /// يجلب الصفحة التالية ويضيفها للنتائج المعروضة (بدل ما يبدأ من أول المستند).
  Future<void> loadMore() async {
    if (isClosed) return;
    final current = state;
    if (current is! SearchResults ||
        !current.hasMore ||
        current.isLoadingMore ||
        _currentQuery.isEmpty ||
        _cursor == null) {
      return;
    }
    await _run(_currentQuery, _generation, cursor: _cursor, append: true);
  }

  Future<void> _run(
    String q,
    int generation, {
    required AdminSearchCursor? cursor,
    required bool append,
  }) async {
    if (isClosed || generation != _generation) return;

    if (append) {
      // حافظ على النتائج الحالية مع مؤشر تحميل صغير في نهاية القائمة.
      final current = state;
      if (current is SearchResults) {
        emit(SearchResults(
          current.hits,
          hasMore: current.hasMore,
          isLoadingMore: true,
        ));
      }
    } else {
      emit(SearchLoading());
    }

    try {
      final page = await _searchRepo.searchPage(q, cursor: cursor);
      if (isClosed || generation != _generation) return;

      _currentQuery = q;
      _cursor = page.nextCursor;

      final previous = <SearchHit>[];
      if (append) {
        final current = state;
        if (current is SearchResults) previous.addAll(current.hits);
      }

      emit(SearchResults([
        ...previous,
        ...page.hits.map((h) => SearchHit(h.kind, h.title, h.id)),
      ], hasMore: page.hasMore));
    } catch (logErr, logSt) {
      AppLogger.nonFatal(
        'features/admin/presentation/cubit/global_search_cubit.dart',
        logErr,
        logSt,
        severity: LoggingSeverity.warning,
      );
      if (isClosed || generation != _generation) return;
      if (append) {
        // ما نرميش النتائج اللي اتحملت بالفعل.
        final current = state;
        if (current is SearchResults) {
          emit(SearchResults(current.hits, hasMore: current.hasMore));
        }
      } else {
        emit(const SearchError('تعذر تنفيذ البحث، حاول مرة أخرى'));
      }
    }
  }

  /// Document behind a hit for the details screens (`null` when missing).
  Future<Map<String, dynamic>?> fetchHitData(SearchHit hit) async {
    try {
      return switch (hit.kind) {
        'shop' => await _searchRepo.fetchShop(hit.id),
        'product' => await _searchRepo.fetchProduct(hit.id),
        _ => await _searchRepo.fetchRequest(hit.id),
      };
    } catch (logErr, logSt) {
      AppLogger.nonFatal(
        'features/admin/presentation/cubit/global_search_cubit.dart',
        logErr,
        logSt,
        severity: LoggingSeverity.warning,
      );
      return null;
    }
  }
}
