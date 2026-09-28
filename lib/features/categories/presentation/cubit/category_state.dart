import 'package:equatable/equatable.dart';

/// حالة الشاشة.
enum CategoryStatus { initial, loading, success, failure }

/// داتا الشاشة (الـ Cubit هو اللي يملاها).
class CategoryState extends Equatable {
  final CategoryStatus status;
  final String shopId;
  final String? businessType;
  final List<String> defaultCategories; // الافتراضي (عرض فقط).
  final List<String> customCategories; // المخصصة (تتعدل).
  final String searchQuery; // نص البحث.
  final String? errorMessage; // رسالة خطأ (toast).
  final String? successMessage; // رسالة نجاح (toast).

  const CategoryState({
    this.status = CategoryStatus.initial,
    this.shopId = '',
    this.businessType,
    this.defaultCategories = const [],
    this.customCategories = const [],
    this.searchQuery = '',
    this.errorMessage,
    this.successMessage,
  });

  /// لسه بيحمل المحل؟
  bool get isShopLoading => status == CategoryStatus.initial || (status == CategoryStatus.loading && shopId.isEmpty);

  /// في محل؟
  bool get hasShop => shopId.isNotEmpty;

  /// العدد الكلي.
  int get totalCount => defaultCategories.length + customCategories.length;

  /// المخصصة بعد البحث.
  List<String> get filteredCustom {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return customCategories;
    return customCategories.where((c) => c.toLowerCase().contains(q)).toList();
  }

  /// الافتراضية بعد البحث.
  List<String> get filteredDefaults {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return defaultCategories;
    return defaultCategories.where((c) => c.toLowerCase().contains(q)).toList();
  }

  /// نسخ مع تعديل.
  CategoryState copyWith({
    CategoryStatus? status,
    String? shopId,
    String? businessType,
    List<String>? defaultCategories,
    List<String>? customCategories,
    String? searchQuery,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return CategoryState(
      status: status ?? this.status,
      shopId: shopId ?? this.shopId,
      businessType: businessType ?? this.businessType,
      defaultCategories: defaultCategories ?? this.defaultCategories,
      customCategories: customCategories ?? this.customCategories,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [status, shopId, businessType, defaultCategories, customCategories, searchQuery, errorMessage, successMessage];
}
