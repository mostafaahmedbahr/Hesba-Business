import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminListState extends Equatable {
  const AdminListState({
    this.loading = false,
    this.docs = const [],
    this.lastDoc,
    this.hasMore = false,
    this.error,
  });

  final bool loading;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;
  final String? error;

  @override
  List<Object?> get props => [loading, docs, lastDoc, hasMore, error];

  AdminListState copyWith({
    bool? loading,
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? docs,
    DocumentSnapshot? lastDoc,
    bool? hasMore,
    String? error,
  }) =>
      AdminListState(
        loading: loading ?? this.loading,
        docs: docs ?? this.docs,
        lastDoc: lastDoc ?? this.lastDoc,
        hasMore: hasMore ?? this.hasMore,
        error: error,
      );
}

class AdminListCubit extends Cubit<AdminListState> {
  AdminListCubit({required this.fetch}) : super(const AdminListState());

  final Future<QuerySnapshot<Map<String, dynamic>>> Function(
    DocumentSnapshot? startAfter,
  ) fetch;

  Future<void> firstPage() async {
    emit(const AdminListState(loading: true));
    try {
      final snap = await fetch(null);
      emit(AdminListState(
        docs: snap.docs,
        lastDoc: snap.docs.isEmpty ? null : snap.docs.last,
        hasMore: snap.docs.length >= 20,
      ));
    } catch (e) {
      emit(AdminListState(error: e.toString()));
    }
  }

  Future<void> nextPage() async {
    final current = state;
    if (current.loading || !current.hasMore || current.lastDoc == null) return;
    emit(current.copyWith(loading: true));
    try {
      final snap = await fetch(current.lastDoc);
      emit(AdminListState(
        docs: [...current.docs, ...snap.docs],
        lastDoc: snap.docs.isEmpty ? current.lastDoc : snap.docs.last,
        hasMore: snap.docs.length >= 20,
      ));
    } catch (e) {
      emit(current.copyWith(loading: false, error: e.toString()));
    }
  }
}
