import 'package:equatable/equatable.dart';

import '../../data/models/supplier_model.dart';

enum SuppliersStatus { loading, success, failure }

/// حالة شاشة الموردين (القائمة + البحث).
class SuppliersState extends Equatable {
  final SuppliersStatus status;
  final List<SupplierModel> suppliers;
  final String? errorMessage;

  /// نص البحث في القائمة (فلترة محلية — نفس نمط المنتجات/المصروفات).
  final String searchQuery;

  /// عدد المنتجات المرتبطة بكل مورد (معرّف المورد → العدد).
  final Map<String, int> linkedCounts;

  /// نتائج البحث عن بعد المستخدمة في قائمة اختيار المورد
  /// (`null` = لا يوجد بحث عن بعد جارٍ).
  final List<SupplierModel>? remoteResults;

  /// هل البحث عن بعد يشتغل الآن؟
  final bool searching;

  const SuppliersState({
    this.status = SuppliersStatus.loading,
    this.suppliers = const [],
    this.errorMessage,
    this.searchQuery = '',
    this.linkedCounts = const {},
    this.remoteResults,
    this.searching = false,
  });

  /// إجمالي عدد الموردين (هو كل ملخص الشاشة — بلا أي أرقام مالية).
  int get totalCount => suppliers.length;

  /// عدد المنتجات المرتبطة بمورد معيّن.
  int linkedCountOf(String supplierId) => linkedCounts[supplierId] ?? 0;

  /// القائمة بعد البحث المحلي.
  List<SupplierModel> get filtered {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return suppliers;
    final qPhone = SupplierModel.normalizePhone(q);
    return suppliers.where((s) {
      if (s.name.toLowerCase().contains(q)) return true;
      if (s.companyName.toLowerCase().contains(q)) return true;
      if (s.city.toLowerCase().contains(q)) return true;
      if (qPhone.isNotEmpty && s.normalizedPhone.contains(qPhone)) return true;
      return false;
    }).toList();
  }

  /// نتائج اختيار المورد: بحث عن بعد إن وُجد، وإلا القائمة كاملة.
  List<SupplierModel> get pickerResults => remoteResults ?? suppliers;

  /// هل بحث الاختيار عن بعد أظهر صفر نتائج؟
  bool get pickerSearchEmpty => remoteResults != null && remoteResults!.isEmpty;

  static const _sentinel = Object();

  SuppliersState copyWith({
    SuppliersStatus? status,
    List<SupplierModel>? suppliers,
    Object? errorMessage = _sentinel,
    bool clearError = false,
    String? searchQuery,
    Map<String, int>? linkedCounts,
    Object? remoteResults = _sentinel,
    bool? searching,
  }) {
    return SuppliersState(
      status: status ?? this.status,
      suppliers: suppliers ?? this.suppliers,
      errorMessage: clearError
          ? null
          : identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      searchQuery: searchQuery ?? this.searchQuery,
      linkedCounts: linkedCounts ?? this.linkedCounts,
      remoteResults: identical(remoteResults, _sentinel)
          ? this.remoteResults
          : remoteResults as List<SupplierModel>?,
      searching: searching ?? this.searching,
    );
  }

  @override
  List<Object?> get props => [
    status,
    suppliers,
    errorMessage,
    searchQuery,
    linkedCounts,
    remoteResults,
    searching,
  ];
}
