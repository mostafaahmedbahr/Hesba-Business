import 'package:equatable/equatable.dart';

enum CategoryStatus { initial, loading, success, failure }

class CategoryState extends Equatable {
  final CategoryStatus status;
  final List<String> customCategories;
  final String? errorMessage;
  final String? successMessage;

  const CategoryState({
    this.status = CategoryStatus.initial,
    this.customCategories = const [],
    this.errorMessage,
    this.successMessage,
  });

  CategoryState copyWith({
    CategoryStatus? status,
    List<String>? customCategories,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return CategoryState(
      status: status ?? this.status,
      customCategories: customCategories ?? this.customCategories,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [status, customCategories, errorMessage, successMessage];
}
