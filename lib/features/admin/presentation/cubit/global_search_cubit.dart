import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class GlobalSearchState extends Equatable {
  const GlobalSearchState();
  @override
  List<Object?> get props => [];
}

class SearchIdle extends GlobalSearchState {}

class SearchLoading extends GlobalSearchState {}

class SearchResults extends GlobalSearchState {
  const SearchResults(this.hits);
  final List<SearchHit> hits;
  @override
  List<Object?> get props => [hits];
}

class SearchHit {
  const SearchHit(this.kind, this.title, this.id);
  final String kind;
  final String title;
  final String id;
}

class GlobalSearchCubit extends Cubit<GlobalSearchState> {
  GlobalSearchCubit() : super(SearchIdle());

  Timer? _debounce;

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> search(String query) async {
    _debounce?.cancel();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      emit(SearchIdle());
      return;
    }
    // Debounced: one Firestore round-trip per pause in typing, not per keystroke.
    _debounce = Timer(const Duration(milliseconds: 400), () => _run(q));
  }

  Future<void> _run(String q) async {
    emit(SearchLoading());
    final hits = <SearchHit>[];
    bool matches(dynamic v) => v != null && v.toString().toLowerCase().contains(q);

    final shops = await FirebaseFirestore.instance.collection('shops').limit(50).get();
    for (final d in shops.docs) {
      final data = d.data();
      if (matches(data['shopName']) || matches(data['ownerName']) || matches(data['phone'])) {
        hits.add(SearchHit('محل', data['shopName'] as String? ?? '-', d.id));
      }
    }

    final products = await FirebaseFirestore.instance.collection('products').limit(50).get();
    for (final d in products.docs) {
      final data = d.data();
      if (matches(data['name'])) {
        hits.add(SearchHit('منتج', data['name'] as String? ?? '-', d.id));
      }
    }

    final requests = await FirebaseFirestore.instance.collection('subscription_requests').limit(50).get();
    for (final d in requests.docs) {
      final data = d.data();
      if (matches(data['shopName']) || matches(data['phone']) || matches(data['ownerName'])) {
        hits.add(SearchHit('طلب اشتراك', data['shopName'] as String? ?? '-', d.id));
      }
    }

    emit(SearchResults(hits));
  }
}
