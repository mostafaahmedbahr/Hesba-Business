import 'package:equatable/equatable.dart';

import '../../../../core/models/product.dart';
import '../../data/models/supplier_model.dart';

enum SupplierDetailsStatus { loading, success, failure }

/// حالة شاشة تفاصيل المورد (المورد + منتجاته المرتبطة).
class SupplierDetailsState extends Equatable {
  final SupplierDetailsStatus status;

  /// null بعد الفشل أو قبل الوصول للمورد.
  final SupplierModel? supplier;
  final List<Product> linkedProducts;
  final String? errorMessage;

  /// حالة حفظ/حذف منفصلة عن التحميل.
  final bool busy;

  const SupplierDetailsState({
    this.status = SupplierDetailsStatus.loading,
    this.supplier,
    this.linkedProducts = const [],
    this.errorMessage,
    this.busy = false,
  });

  /// إجمالي المنتجات المرتبطة (يُعرض في الهيدر).
  int get linkedCount => linkedProducts.length;

  SupplierDetailsState copyWith({
    SupplierDetailsStatus? status,
    Object? supplier = _sentinel,
    List<Product>? linkedProducts,
    Object? errorMessage = _sentinel,
    bool clearError = false,
    bool? busy,
  }) {
    return SupplierDetailsState(
      status: status ?? this.status,
      supplier: identical(supplier, _sentinel)
          ? this.supplier
          : supplier as SupplierModel?,
      linkedProducts: linkedProducts ?? this.linkedProducts,
      errorMessage: clearError
          ? null
          : identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      busy: busy ?? this.busy,
    );
  }

  static const _sentinel = Object();

  @override
  List<Object?> get props => [
    status,
    supplier,
    linkedProducts,
    errorMessage,
    busy,
  ];
}
