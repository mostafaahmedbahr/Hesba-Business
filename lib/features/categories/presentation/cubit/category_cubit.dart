import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/repos/category_repo.dart';
import 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final CategoryRepo _repo;
  StreamSubscription<List<String>>? _sub;
  String? _shopId;
  String? _businessType;

  CategoryCubit({required CategoryRepo repo}) : _repo = repo, super(const CategoryState());

  void init({required String shopId, String? businessType}) {
    _shopId = shopId;
    _businessType = businessType;
    _sub?.cancel();
    emit(state.copyWith(status: CategoryStatus.loading, clearError: true, clearSuccess: true));
    _sub = _repo.watchCustomCategories(shopId).listen((list) {
      if (!isClosed) emit(state.copyWith(status: CategoryStatus.success, customCategories: list, clearError: true));
    }, onError: (e) {
      if (!isClosed) emit(state.copyWith(status: CategoryStatus.failure, errorMessage: e.toString()));
    });
  }

  List<String> _defaultCategories() {
    if (_businessType != null && AppConstants.productCategoriesByBusinessType.containsKey(_businessType)) {
      return AppConstants.productCategoriesByBusinessType[_businessType]!;
    }
    return AppConstants.defaultProductCategories;
  }

  Future<bool> addCategory(String raw) async {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      emit(state.copyWith(errorMessage: 'اكتب اسم القسم', status: CategoryStatus.failure));
      return false;
    }
    if (trimmed.length < 2) {
      emit(state.copyWith(errorMessage: 'الاسم قصير جداً', status: CategoryStatus.failure));
      return false;
    }
    // منع التكرار (حساس لحالة الأحرف والمسافات)
    final lower = trimmed.toLowerCase();
    final defaults = _defaultCategories().map((e) => e.trim().toLowerCase()).toSet();
    if (defaults.contains(lower)) {
      emit(state.copyWith(errorMessage: 'القسم موجود بالفعل في القائمة الافتراضية', status: CategoryStatus.failure));
      return false;
    }
    final customs = state.customCategories.map((e) => e.trim().toLowerCase()).toSet();
    if (customs.contains(lower)) {
      emit(state.copyWith(errorMessage: 'القسم موجود بالفعل', status: CategoryStatus.failure));
      return false;
    }
    if (_shopId == null || _shopId!.isEmpty) {
      emit(state.copyWith(errorMessage: 'لم يتم العثور على المتجر', status: CategoryStatus.failure));
      return false;
    }
    try {
      emit(state.copyWith(status: CategoryStatus.loading, clearError: true, clearSuccess: true));
      await _repo.addCategory(_shopId!, trimmed);
      emit(state.copyWith(status: CategoryStatus.success, successMessage: 'تمت إضافة القسم', clearError: true));
      return true;
    } catch (e) {
      emit(state.copyWith(status: CategoryStatus.failure, errorMessage: e.toString().replaceAll('Exception: ', '')));
      return false;
    }
  }

  Future<bool> removeCategory(String category) async {
    if (_shopId == null || _shopId!.isEmpty) return false;
    try {
      await _repo.removeCategory(_shopId!, category);
      emit(state.copyWith(successMessage: 'تم حذف القسم', clearError: true));
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString().replaceAll('Exception: ', ''), status: CategoryStatus.failure));
      return false;
    }
  }

  void clearMessages() => emit(state.copyWith(clearError: true, clearSuccess: true));

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
