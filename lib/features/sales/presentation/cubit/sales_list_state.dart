import 'package:equatable/equatable.dart';

import '../../data/models/sale_model.dart';

/// حالة قائمة المبيعات.
enum SalesListStatus { initial, loading, success, failure }

/// داتا القائمة (الـ Cubit هو اللي يملاها).
class SalesListState extends Equatable {
  final SalesListStatus status;
  final String shopId;
  final List<SaleModel> sales;
  final String searchQuery; // نص البحث.
  final String paymentFilter; // فلتر الدفع (الكل/نقدي/بطاقة/محفظة).
  final String? errorMessage;

  const SalesListState({
    this.status = SalesListStatus.initial,
    this.shopId = '',
    this.sales = const [],
    this.searchQuery = '',
    this.paymentFilter = 'الكل',
    this.errorMessage,
  });

  /// في محل؟
  bool get hasShop => shopId.isNotEmpty;

  /// المبيعات بعد البحث + الفلتر.
  List<SaleModel> get filtered {
    final q = searchQuery.trim().toLowerCase();
    return sales.where((s) {
      final matchesSearch = q.isEmpty ||
          s.saleId.toLowerCase().contains(q) ||
          s.items.any((it) => it.productName.toLowerCase().contains(q)) ||
          s.note.toLowerCase().contains(q);
      final matchesPayment =
          paymentFilter == 'الكل' || paymentLabel(s.paymentMethod) == paymentFilter;
      return matchesSearch && matchesPayment;
    }).toList();
  }

  /// إجمالي كل المبيعات.
  double get totalValue => sales.fold<double>(0, (s, e) => s + e.total);

  /// مبيعات النهاردة.
  List<SaleModel> get todaySales {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return sales.where((s) => s.createdAt.isAfter(start)).toList();
  }

  /// إجمالي النهاردة.
  double get todayValue => todaySales.fold<double>(0, (s, e) => s + e.total);

  /// اسم طريقة الدفع بالعربي.
  static String paymentLabel(String method) {
    switch (method) {
      case 'cash':
        return 'نقدي';
      case 'card':
        return 'بطاقة';
      case 'mobile_wallet':
      case 'wallet':
        return 'محفظة';
      default:
        return method;
    }
  }

  /// فلاتر الدفع المتاحة.
  static const paymentFilters = ['الكل', 'نقدي', 'بطاقة', 'محفظة'];

  /// نسخ مع تعديل.
  SalesListState copyWith({
    SalesListStatus? status,
    String? shopId,
    List<SaleModel>? sales,
    String? searchQuery,
    String? paymentFilter,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SalesListState(
      status: status ?? this.status,
      shopId: shopId ?? this.shopId,
      sales: sales ?? this.sales,
      searchQuery: searchQuery ?? this.searchQuery,
      paymentFilter: paymentFilter ?? this.paymentFilter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, shopId, sales, searchQuery, paymentFilter, errorMessage];
}

/// تنسيق رقم (صحيح من غير كسور).
String fmtPrice(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
