import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../expenses/data/repos/expenses_repo.dart';
import '../../../returns/data/repos/returns_repo.dart';
import '../../../sales/data/repos/sales_repo.dart';
import '../../data/reports_calculator.dart';
import 'reports_state.dart';

/// لوجيك التقارير: يجلب **كل** سجلات المحل بترقيم cursor (بلا قيود 300)
/// ويفلتر محلياً حسب الفترة (تبديل الفترة فوري)، ثم يحسب المؤشرات مرة
/// واحدة عبر `ReportsCalculator`.
///
/// التحديث الحي: اشتراك خفيف على أحدث مستند في كل مجموعة (limit 1) كـ
/// trigger لإعادة الجلب — بدل الاشتراك في كل الفواتير (الذي كان مقصوصاً
/// لـ 500/300). تعديل سجل قديم قد لا يطلق الـ trigger؛ سحب الشاشة للأسفل
/// يعيد التحميل (RefreshIndicator).
class ReportsCubit extends Cubit<ReportsState> {
  final SalesRepo _salesRepo;
  final ReturnsRepo _returnsRepo;
  final ExpensesRepo _expensesRepo;
  StreamSubscription<void>? _salesSub;
  StreamSubscription<void>? _returnsSub;
  StreamSubscription<void>? _expensesSub;

  /// منع تراكب عمليات الجلب: لو جلب شغّال وحدث جديد وصل، يُعاد بعد
  /// انتهائه ( bitmask: 1=مبيعات، 2=مرتجعات، 4=مصروفات ).
  bool _busy = false;
  int _pendingMask = 0;

  ReportsCubit({
    required SalesRepo salesRepo,
    required ReturnsRepo returnsRepo,
    required ExpensesRepo expensesRepo,
  })  : _salesRepo = salesRepo,
        _returnsRepo = returnsRepo,
        _expensesRepo = expensesRepo,
        super(const ReportsState());

  /// تجهيز: يجيب المحل + يجلب القوائم كاملة + يشترك في التحديث الحي.
  Future<void> bootstrap() async {
    emit(state.copyWith(status: ReportsStatus.loading, clearError: true));
    final shopId = await _salesRepo.getShopId();
    // مفيش محل.
    if (shopId == null || shopId.isEmpty) {
      emit(state.copyWith(
        status: ReportsStatus.failure,
        errorMessage: 'لم يتم العثور على المتجر',
      ));
      return;
    }
    emit(state.copyWith(shopId: shopId));
    await _cancelAll();
    await _reload(mask: 7, showLoading: true);

    // triggers خفيفة (مستند واحد لكل مجموعة) — إعادة الجلب عند أي إضافة.
    _salesSub = _salesRepo.watchLatestSale(shopId: shopId).listen(
          (_) => _reload(mask: 1),
          onError: (Object _) {}, // فشل الـ trigger لا يُفشل الشاشة
        );
    _returnsSub = _returnsRepo.watchLatestReturn(shopId: shopId).listen(
          (_) => _reload(mask: 2),
          onError: (Object _) {},
        );
    _expensesSub = _expensesRepo.watchLatestExpense(shopId: shopId).listen(
          (_) => _reload(mask: 4),
          onError: (Object _) {},
        );
  }

  /// يغير الفترة (فوري — الداتا في الذاكرة، الحساب فقط يعاد).
  void setPeriod(ReportPeriod period) {
    if (period == state.period) return;
    emit(state.copyWith(
      period: period,
      metrics: ReportsCalculator.calculate(
        sales: state.allSales,
        returns: state.allReturns,
        expenses: state.allExpenses,
        start: period.start,
        end: period.endExclusive,
      ),
    ));
  }

  /// جلب المجموعات المطلوبة بـ cursor ثم حساب مؤشرات الفترة مرة واحدة.
  Future<void> _reload({required int mask, bool showLoading = false}) async {
    if (_busy) {
      _pendingMask |= mask;
      return;
    }
    _busy = true;
    if (showLoading) {
      emit(state.copyWith(status: ReportsStatus.loading, clearError: true));
    }
    try {
      final shopId = state.shopId;
      final wantSales = (mask & 1) != 0;
      final wantReturns = (mask & 2) != 0;
      final wantExpenses = (mask & 4) != 0;

      // الجلب بالتوازي (كل مجموعة مستقلة).
      final salesFut = wantSales ? _salesRepo.fetchAllSales(shopId: shopId) : null;
      final returnsFut = wantReturns ? _returnsRepo.fetchAllReturns(shopId: shopId) : null;
      final expensesFut = wantExpenses ? _expensesRepo.fetchAllExpenses(shopId: shopId) : null;

      final salesRes = await salesFut;
      final returnsRes = await returnsFut;
      final expensesRes = await expensesFut;
      if (isClosed) return;

      // اكتمال البيانات: الجلب الكامل يعيد الحساب من جديد؛ جلب المجموعة
      // الواحدة يحافظ على اكتمال البقية ويضيف اكتمالها.
      final allComplete = (mask == 7)
          ? (salesRes?.isComplete ?? true) &&
              (returnsRes?.isComplete ?? true) &&
              (expensesRes?.isComplete ?? true)
          : state.dataComplete &&
              (salesRes?.isComplete ?? true) &&
              (returnsRes?.isComplete ?? true) &&
              (expensesRes?.isComplete ?? true);

      emit(state.copyWith(
        status: ReportsStatus.success,
        allSales: salesRes?.items ?? state.allSales,
        allReturns: returnsRes?.items ?? state.allReturns,
        allExpenses: expensesRes?.items ?? state.allExpenses,
        dataComplete: allComplete,
        metrics: ReportsCalculator.calculate(
          sales: salesRes?.items ?? state.allSales,
          returns: returnsRes?.items ?? state.allReturns,
          expenses: expensesRes?.items ?? state.allExpenses,
          start: state.period.start,
          end: state.period.endExclusive,
        ),
        clearError: true,
      ));
    } catch (e) {
      _fail(e);
    } finally {
      _busy = false;
      if (_pendingMask != 0 && !isClosed) {
        final pending = _pendingMask;
        _pendingMask = 0;
        await _reload(mask: pending);
      }
    }
  }

  void _fail(Object e) {
    if (isClosed) return;
    emit(state.copyWith(
      status: ReportsStatus.failure,
      errorMessage: e.toString().replaceAll('Exception: ', ''),
    ));
  }

  Future<void> _cancelAll() async {
    await _salesSub?.cancel();
    await _returnsSub?.cancel();
    await _expensesSub?.cancel();
    _salesSub = null;
    _returnsSub = null;
    _expensesSub = null;
  }

  @override
  Future<void> close() {
    _cancelAll();
    return super.close();
  }
}
