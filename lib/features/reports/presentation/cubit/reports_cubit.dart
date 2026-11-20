import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/app_events.dart';
import '../../../../core/utils/error_message.dart';
import '../../../expenses/data/repos/expenses_repo.dart';
import '../../../returns/data/repos/returns_repo.dart';
import '../../../sales/data/repos/sales_repo.dart';
import '../../data/reports_calculator.dart';
import 'reports_state.dart';
import 'package:hesba/core/services/app_logger.dart';

/// لوجيك التقارير: يجلب **كل** سجلات المحل بترقيم cursor (بلا قيود 300)
/// ويفلتر محلياً حسب الفترة (تبديل الفترة فوري)، ثم يحسب المؤشرات مرة
/// واحدة عبر `ReportsCalculator`.
///
/// التحديث: مفيش أي listener على Firestore. التقارير بتتحمل عند فتح الشاشة
/// ([bootstrap])، وبتتجدد بعد عمليات الكتابة عبر `AppEvents` (بـ debounce
/// عشان ما يتعملش جلب كامل لكل حدث)، وبالسحب للتحديث ([refresh]).
/// كده تعديل سجل قديم كمان بيظهر — الـ trigger القديم (limit 1) كان بيفتقده.
class ReportsCubit extends Cubit<ReportsState> {
  final SalesRepo _salesRepo;
  final ReturnsRepo _returnsRepo;
  final ExpensesRepo _expensesRepo;
  StreamSubscription<AppEvent>? _appEventSub;
  Timer? _refreshDebounce;

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

  /// تجهيز: يجيب المحل + يجلب القوائم كاملة مرة واحدة.
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
    _listenAppEvents();
    await _reload(mask: 7, showLoading: true);
  }

  /// إعادة جلب كاملة عند الطلب (السحب للتحديث) أو بعد عمليات الكتابة.
  Future<void> refresh() async {
    if (!state.hasShop) return bootstrap();
    await _reload(mask: 7, showLoading: true);
  }

  void _listenAppEvents() {
    if (_appEventSub != null) return;
    _appEventSub = AppEvents.instance.stream.listen((event) {
      if (event.type != AppEventType.saleCreated &&
          event.type != AppEventType.returnCreated &&
          event.type != AppEventType.expenseCreated &&
          event.type != AppEventType.expenseUpdated &&
          event.type != AppEventType.expenseDeleted) {
        return;
      }
      // كل عملية بتبعت أكتر من حدث (مثلاً saleCreated + productChanged)؛
      // debounce بيحوّلهم لجلب كامل واحد بدل جلب لكل حدث.
      _refreshDebounce?.cancel();
      _refreshDebounce = Timer(const Duration(milliseconds: 500), () {
        if (!isClosed) refresh();
      });
    });
  }

  /// يغير الفترة (فوري — الداتا في الذاكرة، الحساب فقط يعاد).
  void setPeriod(ReportPeriod period) {
    if (period == state.period) return;
    final wasAll = state.period == ReportPeriod.all;
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
    // Recent periods share one 30-day window fetched at bootstrap, so their
    // switching stays instant. Only "all" needs a different (full) dataset.
    if ((period == ReportPeriod.all) != wasAll) {
      // ignore: unawaited_futures
      _reload(mask: 7, showLoading: true);
    }
  }

  /// Recent periods (today/7/30 days) all fit inside one bounded window.
  static DateTime? _fetchFrom(ReportPeriod period) => period == ReportPeriod.all
      ? null
      : DateTime.now().subtract(const Duration(days: 30));

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
      final from = _fetchFrom(state.period);
      final salesFut = wantSales
          ? _salesRepo.fetchAllSales(shopId: shopId, from: from)
          : null;
      final returnsFut = wantReturns
          ? _returnsRepo.fetchAllReturns(shopId: shopId, from: from)
          : null;
      final expensesFut = wantExpenses
          ? _expensesRepo.fetchAllExpenses(shopId: shopId, from: from)
          : null;

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
    } catch (e, logSt) {
      AppLogger.nonFatal('features/reports/presentation/cubit/reports_cubit.dart', e, logSt, severity: LoggingSeverity.warning);
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
      errorMessage: friendlyError(e),
    ));
  }

  @override
  Future<void> close() {
    _refreshDebounce?.cancel();
    _appEventSub?.cancel();
    return super.close();
  }
}
