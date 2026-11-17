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
  StreamSubscription<List<SupplierModel>>? _suppliersSub;
  StreamSubscription<Map<String, int>>? _countsSub;
  Timer? _debounce;
  int _searchGeneration = 0;

  SuppliersCubit({required this._repo}) : super(const SuppliersState());

  /// يشترك في موردي المحل وعدد المنتجات المرتبطة بهم.
  void init() {
    _suppliersSub ??= _repo.watchSuppliers().listen(
      (list) => emit(
        state.copyWith(
          status: SuppliersStatus.success,
          suppliers: list,
          clearError: true,
        ),
      ),
      onError: (Object e) => emit(
        state.copyWith(status: SuppliersStatus.failure, errorMessage: friendlyError(e)),
      ),
      onDone: () {
        if (state.status == SuppliersStatus.loading) {
          emit(state.copyWith(status: SuppliersStatus.success, suppliers: const []));
        }
      },
    );

    _countsSub ??= _repo.watchLinkedProductCounts().listen(
      (counts) => emit(state.copyWith(linkedCounts: counts)),
      onError: (Object e) => logWarning('[SuppliersCubit] counts: $e'),
    );

    // نبقي status = loading حتى يصل أول انبعاث من الستريم (لعرض مؤشر التحميل).
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
  Future<void> refresh() async {
    _suppliersSub?.cancel();
    _suppliersSub = null;
    emit(state.copyWith(status: SuppliersStatus.loading, clearError: true));
    init();
  }

  /// حذف مورد — يفشل برسالة واضحة لو فيه منتجات مرتبطة.
  Future<bool> deleteSupplier(String supplierId) async {
    try {
      await _repo.deleteSupplier(supplierId);
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
    _suppliersSub?.cancel();
    _countsSub?.cancel();
    return super.close();
  }
}
