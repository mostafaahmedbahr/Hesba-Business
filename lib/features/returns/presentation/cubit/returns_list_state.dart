import 'package:equatable/equatable.dart';

import '../../data/models/return_model.dart';

/// حالة قائمة المرتجعات.
enum ReturnsListStatus { initial, loading, success, failure }

/// داتا القائمة (الـ Cubit هو اللي يملاها).
class ReturnsListState extends Equatable {
  final ReturnsListStatus status;
  final String shopId;
  final List<ReturnModel> returns;
  final String searchQuery; // نص البحث.
  final String reasonFilter; // فلتر السبب (الكل + الأسباب الموجودة).
  final String? errorMessage;

  const ReturnsListState({
    this.status = ReturnsListStatus.initial,
    this.shopId = '',
    this.returns = const [],
    this.searchQuery = '',
    this.reasonFilter = 'الكل',
    this.errorMessage,
  });

  /// في محل؟
  bool get hasShop => shopId.isNotEmpty;

  /// المرتجعات بعد البحث + الفلتر.
  List<ReturnModel> get filtered {
    final q = searchQuery.trim().toLowerCase();
    return returns.where((r) {
      final matchesSearch = q.isEmpty ||
          r.returnId.toLowerCase().contains(q) ||
          r.reason.toLowerCase().contains(q) ||
          r.items.any((it) => it.productName.toLowerCase().contains(q));
      final matchesReason = reasonFilter == 'الكل' || r.reason == reasonFilter;
      return matchesSearch && matchesReason;
    }).toList();
  }

  /// إجمالي كل المرتجعات.
  double get totalValue => returns.fold<double>(0, (s, e) => s + e.total);

  /// مرتجعات النهاردة.
  List<ReturnModel> get todayReturns {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return returns.where((r) => r.createdAt.isAfter(start)).toList();
  }

  /// إجمالي النهاردة.
  double get todayValue => todayReturns.fold<double>(0, (s, e) => s + e.total);

  /// الأسباب الموجودة (للفلتر).
  List<String> get reasons {
    final set = <String>{'الكل'};
    for (final r in returns) {
      if (r.reason.trim().isNotEmpty) set.add(r.reason);
    }
    return set.toList();
  }

  /// نسخ مع تعديل.
  ReturnsListState copyWith({
    ReturnsListStatus? status,
    String? shopId,
    List<ReturnModel>? returns,
    String? searchQuery,
    String? reasonFilter,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReturnsListState(
      status: status ?? this.status,
      shopId: shopId ?? this.shopId,
      returns: returns ?? this.returns,
      searchQuery: searchQuery ?? this.searchQuery,
      reasonFilter: reasonFilter ?? this.reasonFilter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, shopId, returns, searchQuery, reasonFilter, errorMessage];
}

/// تنسيق رقم (صحيح من غير كسور).
String fmtReturn(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
