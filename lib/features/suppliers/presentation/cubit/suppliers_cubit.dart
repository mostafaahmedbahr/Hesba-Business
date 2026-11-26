import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/log_util.dart';
import '../../../../core/utils/error_message.dart';
import '../../data/models/supplier_model.dart';
import '../../data/repos/suppliers_repo.dart';
import '../states/suppliers_state.dart';
import 'package:hesba/core/services/app_logger.dart';

/// يدير شاشة الموردين: القائمة الحيّة، البحث المحلي/عن بعد، عدّاد
/// المنتجات المرتبطة، والحذف.
class SuppliersCubit extends Cubit<SuppliersState> {
  final SuppliersRepo _repo;
  Timer? _debounce;
  int _searchGeneration = 0;

  SuppliersCubit({required this._repo}) : super(const SuppliersState());

  /// قراءة واحدة للموردين وعدد المنتجات المرتبطة عند فتح الشاشة / السحب.
  Future<void> init() async {
    emit(state.copyWith(status: SuppliersStatus.loading, clearError: true));
    try {
      final results = await Future.wait<Object>([
        _repo.getSuppliers(),
        _repo.getLinkedProductCounts(),
      ]);
      if (isClosed) return;
      emit(state.copyWith(
        status: SuppliersStatus.success,
        suppliers: results[0] as List<SupplierModel>,
        linkedCounts: results[1] as Map<String, int>,
        clearError: true,
      ));
    } catch (e, logSt) {
      AppLogger.nonFatal('features/suppliers/presentation/cubit/suppliers_cubit.dart', e, logSt, severity: LoggingSeverity.warning);
      if (!isClosed) {
        emit(state.copyWith(
          status: SuppliersStatus.failure,
          errorMessage: friendlyError(e),
        ));
      }
    }
  }

  /// تحديث البحث المحلي في القائمة.
  void setSearch(String query) {
    if (query == state.searchQuery) return;
    emit(state.copyWith(searchQuery: query, remoteResults: null));
  }

  /// بحث عن بعد (يُستدعى من قائمة اختيار المورد) مع تأخير 400ms
  /// حتى لا نُرسل طلباً لكل حرف — نفس نمط GlobalSearchCubit.
  void searchRemote(String query) {
    _debounce?.cancel();
    final generation = ++_searchGeneration;
    final q = query.trim();
    if (q.isEmpty) {
      emit(state.copyWith(remoteResults: null, searching: false));
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _runRemote(q, generation));
  }

  Future<void> _runRemote(String q, int generation) async {
    if (isClosed || generation != _searchGeneration) return;
    emit(state.copyWith(searching: true));
    try {
      final results = await _repo.searchSuppliers(q);
      if (isClosed || generation != _searchGeneration) return;
      emit(state.copyWith(searching: false, remoteResults: results));
    } catch (e, logSt) {
      AppLogger.nonFatal('features/suppliers/presentation/cubit/suppliers_cubit.dart', e, logSt, severity: LoggingSeverity.warning);
      logWarning('[SuppliersCubit] search failed: $e');
      if (isClosed || generation != _searchGeneration) return;
      emit(state.copyWith(searching: false, remoteResults: const []));
    }
  }

  /// إعادة تحميل القائمة (سحب للتحديث).
  Future<void> refresh() => init();

  /// يضع المورد المحفوظ في القائمة فوراً (قبل ما قراءة Firestore ترجع)
  /// ثم يعمل تحديث خفيف — عشان يظهر في نفس لحظة الرجوع من الفورم.
  Future<void> applySavedSupplier(SupplierModel supplier) async {
    final next = List<SupplierModel>.from(state.suppliers);
    final idx = next.indexWhere((s) => s.id == supplier.id);
    if (idx >= 0) {
      next[idx] = supplier;
    } else {
      next.insert(0, supplier);
    }
    emit(state.copyWith(
      status: SuppliersStatus.success,
      suppliers: next,
      clearError: true,
    ));
    await refresh();
  }

  /// حذف مورد — يفشل برسالة واضحة لو فيه منتجات مرتبطة.
  Future<bool> deleteSupplier(String supplierId) async {
    try {
      await _repo.deleteSupplier(supplierId);
      await init();
      emit(state.copyWith(clearError: true));
      return true;
    } catch (e, logSt) {
      AppLogger.nonFatal('features/suppliers/presentation/cubit/suppliers_cubit.dart', e, logSt, severity: LoggingSeverity.warning);
      final msg = friendlyError(e);
      logWarning('[SuppliersCubit] delete failed: $msg');
      emit(state.copyWith(errorMessage: msg));
      return false;
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
