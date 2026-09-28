import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repos/category_repo.dart';
import 'category_state.dart';

/// لوجيك الأقسام (الـ View غبية — بتنادي بس).
class CategoryCubit extends Cubit<CategoryState> {
  final CategoryRepo _repo; // بوابة الداتا.
  StreamSubscription<List<String>>? _sub; // ستريم المخصصة.

  CategoryCubit({required CategoryRepo repo})
      : _repo = repo,
        super(const CategoryState());

  /// تجهيز الشاشة: يجيب المحل + الافتراضي + يشترك في المخصصة.
  Future<void> bootstrap() async {
    emit(state.copyWith(status: CategoryStatus.initial, clearError: true, clearSuccess: true));
    final ctx = await _repo.getShopContext();
    // مفيش محل.
    if (!ctx.hasShop) {
      emit(state.copyWith(status: CategoryStatus.failure, shopId: '', businessType: ctx.businessType, errorMessage: 'لم يتم العثور على المتجر'));
      return;
    }
    // يحدد الافتراضي حسب النشاط.
    final defaults = _repo.defaultCategoriesFor(ctx.businessType);
    emit(state.copyWith(shopId: ctx.shopId, businessType: ctx.businessType, defaultCategories: defaults, status: CategoryStatus.loading));
    // يسمع التحديثات live.
    await _sub?.cancel();
    _sub = _repo.watchCustomCategories(ctx.shopId).listen(
      (list) {
        if (isClosed) return;
        emit(state.copyWith(status: CategoryStatus.success, customCategories: list, clearError: true));
      },
      onError: (Object e) {
        if (isClosed) return;
        emit(state.copyWith(status: CategoryStatus.failure, errorMessage: e.toString().replaceAll('Exception: ', '')));
      },
    );
  }

  /// بديل قديم (يفضل bootstrap).
  void init({required String shopId, String? businessType}) {
    final defaults = _repo.defaultCategoriesFor(businessType);
    emit(state.copyWith(shopId: shopId, businessType: businessType, defaultCategories: defaults, status: CategoryStatus.loading, clearError: true, clearSuccess: true));
    _sub?.cancel();
    _sub = _repo.watchCustomCategories(shopId).listen((list) {
      if (!isClosed) emit(state.copyWith(status: CategoryStatus.success, customCategories: list, clearError: true));
    }, onError: (Object e) {
      if (!isClosed) emit(state.copyWith(status: CategoryStatus.failure, errorMessage: e.toString()));
    });
  }

  /// يحدث البحث.
  void setSearch(String query) {
    if (query == state.searchQuery) return;
    emit(state.copyWith(searchQuery: query));
  }

  /// يضيف قسم (مع منع الفاضي/القصير/المكرر).
  Future<bool> addCategory(String raw) async {
    final trimmed = raw.trim();
    // فاضي؟
    if (trimmed.isEmpty) {
      emit(state.copyWith(errorMessage: 'اكتب اسم القسم', status: CategoryStatus.failure));
      return false;
    }
    // قصير؟
    if (trimmed.length < 2) {
      emit(state.copyWith(errorMessage: 'الاسم قصير جداً', status: CategoryStatus.failure));
      return false;
    }
    // مكرر في الافتراضي؟
    final lower = trimmed.toLowerCase();
    if (state.defaultCategories.map((e) => e.trim().toLowerCase()).toSet().contains(lower)) {
      emit(state.copyWith(errorMessage: 'القسم موجود بالفعل في القائمة الافتراضية', status: CategoryStatus.failure));
      return false;
    }
    // مكرر في المخصصة؟
    if (state.customCategories.map((e) => e.trim().toLowerCase()).toSet().contains(lower)) {
      emit(state.copyWith(errorMessage: 'القسم موجود بالفعل', status: CategoryStatus.failure));
      return false;
    }
    // مفيش محل؟
    if (!state.hasShop) {
      emit(state.copyWith(errorMessage: 'لم يتم العثور على المتجر', status: CategoryStatus.failure));
      return false;
    }
    try {
      emit(state.copyWith(status: CategoryStatus.loading, clearError: true, clearSuccess: true));
      await _repo.addCategory(state.shopId, trimmed);
      emit(state.copyWith(status: CategoryStatus.success, successMessage: 'تمت إضافة القسم', clearError: true));
      return true;
    } catch (e) {
      emit(state.copyWith(status: CategoryStatus.failure, errorMessage: e.toString().replaceAll('Exception: ', '')));
      return false;
    }
  }

  /// يحذف قسم.
  Future<bool> removeCategory(String category) async {
    if (!state.hasShop) return false;
    try {
      await _repo.removeCategory(state.shopId, category);
      emit(state.copyWith(successMessage: 'تم حذف القسم', clearError: true));
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString().replaceAll('Exception: ', ''), status: CategoryStatus.failure));
      return false;
    }
  }

  /// يصفر رسائل الـ toast.
  void clearMessages() => emit(state.copyWith(clearError: true, clearSuccess: true));

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
