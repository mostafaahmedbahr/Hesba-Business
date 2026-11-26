import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/error_message.dart';
import '../../data/repos/category_repo.dart';
import 'category_state.dart';
import 'package:hesba/core/services/app_logger.dart';
import 'package:easy_localization/easy_localization.dart';

/// لوجيك الأقسام (الـ View غبية — بتنادي بس).
class CategoryCubit extends Cubit<CategoryState> {
  final CategoryRepo _repo; // بوابة الداتا.

  // ignore: prefer_initializing_formals
  CategoryCubit({required this._repo})
      : super(const CategoryState());

  /// تجهيز الشاشة: يجيب المحل + الافتراضي + يشترك في المخصصة.
  Future<void> bootstrap() async {
    emit(state.copyWith(status: CategoryStatus.initial, clearError: true, clearSuccess: true));
    final ctx = await _repo.getShopContext();
    // مفيش محل.
    if (!ctx.hasShop) {
      emit(state.copyWith(status: CategoryStatus.failure, shopId: '', businessType: ctx.businessType, errorMessage: 'لم يتم العثور على المتجر'.tr()));
      return;
    }
    // يحدد الافتراضي حسب النشاط.
    final defaults = _repo.defaultCategoriesFor(ctx.businessType);
    emit(state.copyWith(shopId: ctx.shopId, businessType: ctx.businessType, defaultCategories: defaults, status: CategoryStatus.loading));
    await _loadCustom(ctx.shopId);
  }

  /// قراءة واحدة عند الطلب / بعد إضافة أو حذف قسم.
  Future<void> _loadCustom(String shopId) async {
    try {
      final list = await _repo.getCustomCategories(shopId);
      if (!isClosed) {
        emit(state.copyWith(status: CategoryStatus.success, customCategories: list, clearError: true));
      }
    } catch (e, logSt) {
      AppLogger.nonFatal('features/categories/presentation/cubit/category_cubit.dart', e, logSt, severity: LoggingSeverity.warning);
      if (!isClosed) {
        emit(state.copyWith(status: CategoryStatus.failure, errorMessage: friendlyError(e)));
      }
    }
  }

  /// تحديث عند الطلب (سحب للتحديث).
  Future<void> refresh() async {
    if (state.hasShop) await _loadCustom(state.shopId);
  }

  /// بديل قديم (يفضل bootstrap).
  Future<void> init({required String shopId, String? businessType}) async {
    final defaults = _repo.defaultCategoriesFor(businessType);
    emit(state.copyWith(shopId: shopId, businessType: businessType, defaultCategories: defaults, status: CategoryStatus.loading, clearError: true, clearSuccess: true));
    await _loadCustom(shopId);
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
      emit(state.copyWith(errorMessage: 'اكتب اسم القسم'.tr(), status: CategoryStatus.failure));
      return false;
    }
    // قصير؟
    if (trimmed.length < 2) {
      emit(state.copyWith(errorMessage: 'الاسم قصير جداً'.tr(), status: CategoryStatus.failure));
      return false;
    }
    // مكرر في الافتراضي؟
    final lower = trimmed.toLowerCase();
    if (state.defaultCategories.map((e) => e.trim().toLowerCase()).toSet().contains(lower)) {
      emit(state.copyWith(errorMessage: 'القسم موجود بالفعل في القائمة الافتراضية'.tr(), status: CategoryStatus.failure));
      return false;
    }
    // مكرر في المخصصة؟
    if (state.customCategories.map((e) => e.trim().toLowerCase()).toSet().contains(lower)) {
      emit(state.copyWith(errorMessage: 'القسم موجود بالفعل'.tr(), status: CategoryStatus.failure));
      return false;
    }
    // مفيش محل؟
    if (!state.hasShop) {
      emit(state.copyWith(errorMessage: 'لم يتم العثور على المتجر'.tr(), status: CategoryStatus.failure));
      return false;
    }
    try {
      emit(state.copyWith(status: CategoryStatus.loading, clearError: true, clearSuccess: true));
      await _repo.addCategory(state.shopId, trimmed);
      await _loadCustom(state.shopId);
      emit(state.copyWith(status: CategoryStatus.success, successMessage: 'تمت إضافة القسم'.tr(), clearError: true));
      return true;
    } catch (e, logSt) {
      AppLogger.nonFatal('features/categories/presentation/cubit/category_cubit.dart', e, logSt, severity: LoggingSeverity.warning);
      emit(state.copyWith(status: CategoryStatus.failure, errorMessage: friendlyError(e)));
      return false;
    }
  }

  /// يحذف قسم.
  Future<bool> removeCategory(String category) async {
    if (!state.hasShop) return false;
    try {
      await _repo.removeCategory(state.shopId, category);
      await _loadCustom(state.shopId);
      emit(state.copyWith(successMessage: 'تم حذف القسم'.tr(), clearError: true));
      return true;
    } catch (e, logSt) {
      AppLogger.nonFatal('features/categories/presentation/cubit/category_cubit.dart', e, logSt, severity: LoggingSeverity.warning);
      emit(state.copyWith(errorMessage: friendlyError(e), status: CategoryStatus.failure));
      return false;
    }
  }

  /// يصفر رسائل الـ toast.
  void clearMessages() => emit(state.copyWith(clearError: true, clearSuccess: true));

}
