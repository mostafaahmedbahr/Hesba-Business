import 'package:equatable/equatable.dart';

import '../../data/models/sale_model.dart';

enum CustomerSalesStatus { initial, loading, success, failure }

/// حالة شاشة «سجل مشتريات العميل».
class CustomerSalesState extends Equatable {
  final CustomerSalesStatus status;
  final String personId;
  final String personName;
  final String personPhone;
  final String shopId;
  final List<SaleModel> sales;
  final String? errorMessage;

  const CustomerSalesState({
    this.status = CustomerSalesStatus.initial,
    this.personId = '',
    this.personName = '',
    this.personPhone = '',
    this.shopId = '',
    this.sales = const [],
    this.errorMessage,
  });

  /// عدد الفواتير.
  int get count => sales.length;

  /// إجمالي قيمة كل مشتريات العميل.
  double get totalPurchases => sales.fold(0, (s, e) => s + e.total);

  /// تاريخ آخر فاتورة (null لو لا توجد).
  DateTime? get lastSaleAt {
    DateTime? latest;
    for (final s in sales) {
      if (latest == null || s.createdAt.isAfter(latest)) {
        latest = s.createdAt;
      }
    }
    return latest;
  }

  CustomerSalesState copyWith({
    CustomerSalesStatus? status,
    String? personId,
    String? personName,
    String? personPhone,
    String? shopId,
    List<SaleModel>? sales,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CustomerSalesState(
      status: status ?? this.status,
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      personPhone: personPhone ?? this.personPhone,
      shopId: shopId ?? this.shopId,
      sales: sales ?? this.sales,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        personId,
        personName,
        personPhone,
        shopId,
        sales,
        errorMessage,
      ];
}
