import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminNavState extends Equatable {
  const AdminNavState({this.index = 0, this.collapsed = false});
  final int index;
  final bool collapsed;
  @override
  List<Object?> get props => [index, collapsed];

  AdminNavState copyWith({int? index, bool? collapsed}) =>
      AdminNavState(index: index ?? this.index, collapsed: collapsed ?? this.collapsed);
}

class AdminNavCubit extends Cubit<AdminNavState> {
  AdminNavCubit() : super(const AdminNavState());

  void select(int index) => emit(state.copyWith(index: index));

  void toggleCollapsed() => emit(state.copyWith(collapsed: !state.collapsed));
}
