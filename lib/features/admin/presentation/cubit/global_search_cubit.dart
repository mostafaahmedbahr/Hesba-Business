import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repos/admin_search_repo.dart';

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
  const SearchResults(this.hits);
  final List<SearchHit> hits;
  @override
  List<Object?> get props => [hits];
}

class SearchHit {
  const SearchHit(this.kind, this.title, this.id);

  /// Stable id from [AdminSearchHit]: 'shop' | 'product' | 'subscription_request'.
  final String kind;
  final String title;
  final String id;
}

class GlobalSearchCubit extends Cubit<GlobalSearchState> {
  GlobalSearchCubit({required AdminSearchRepo searchRepo})
      : _searchRepo = searchRepo,
        super(SearchIdle());

  final AdminSearchRepo _searchRepo;
  Timer? _debounce;

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> search(String query) async {
    _debounce?.cancel();
    final q = query.trim();
    if (q.isEmpty) {
      emit(SearchIdle());
      return;
    }
    // Debounced: one Firestore round-trip per pause in typing, not per keystroke.
    _debounce = Timer(const Duration(milliseconds: 400), () => _run(q));
  }

  Future<void> _run(String q) async {
    emit(SearchLoading());
    try {
      final hits = await _searchRepo.search(q);
      emit(SearchResults(
          hits.map((h) => SearchHit(h.kind, h.title, h.id)).toList()));
    } catch (_) {
      emit(const SearchError('تعذر تنفيذ البحث، حاول مرة أخرى'));
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
    } catch (_) {
      return null;
    }
  }
}
