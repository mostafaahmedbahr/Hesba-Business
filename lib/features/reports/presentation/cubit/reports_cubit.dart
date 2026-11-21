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

  /// بداية نافذة البيانات المحمّلة في الذاكرة. null = كل التاريخ محمّل.
  /// نستخدمها لتجنّب إعادة المسح الكامل عند التبديل بين «الكل» والفترات.
  DateTime? _loadedFrom;
  bool _hasLoaded = false;

  ReportsCubit({
    required this._salesRepo,
    required this._returnsRepo,
    required this._expensesRepo,
  })  : super(const ReportsState());

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

  /// إعادة جلب عند الطلب (السحب للتحديث) أو بعد عمليات الكتابة.
  /// نحافظ على نفس نافذة البيانات المحمّلة — لا نوسّعها بالقوة إلى «الكل»
  /// لمجرد أن المستخدم فتح شاشة التقارير على فترة قصيرة.
  Future<void> refresh() async {
    if (!state.hasShop) return bootstrap();
    await _reload(mask: 7, showLoading: true, from: _loadedFrom);
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

  /// يغير الفترة. الحساب من الذاكرة دائمًا (فوري)؛ لا تُقرأ Firestore إلا
  /// عندما نحتاج نافذة أوسع من المحمّلة فعلًا (أول مرة يُختار «الكل»).
  /// الرجوع من «الكل» لفترة قصيرة لا يُسقط بيانات «الكل»، فالتبديل العكسي
  /// صار بلا مسح كامل متكرر.
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
    final needsFullHistory = period == ReportPeriod.all;
    final hasFullHistory = _hasLoaded && _loadedFrom == null;
    if (needsFullHistory && !hasFullHistory) {
      // ignore: unawaited_futures
      _reload(mask: 7, showLoading: true, from: null);
    }
  }

  /// Recent periods (today/7/30 days) all fit inside one bounded window.
  static DateTime? _fetchFrom(ReportPeriod period) => period == ReportPeriod.all
      ? null
      : DateTime.now().subtract(const Duration(days: 30));

  /// جلب المجموعات المطلوبة بـ cursor ثم حساب مؤشرات الفترة مرة واحدة.
  Future<void> _reload({
    required int mask,
    bool showLoading = false,
    DateTime? from,
  }) async {
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
      final effectiveFrom = from ?? _fetchFrom(state.period);
      final salesFut = wantSales
          ? _salesRepo.fetchAllSales(shopId: shopId, from: effectiveFrom)
          : null;
      final returnsFut = wantReturns
          ? _returnsRepo.fetchAllReturns(shopId: shopId, from: effectiveFrom)
          : null;
      final expensesFut = wantExpenses
          ? _expensesRepo.fetchAllExpenses(shopId: shopId, from: effectiveFrom)
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

      // تتبّع النافذة المحمّلة — أساس قرار «هل نحتاج مسحًا كاملًا؟».
      if (mask == 7) {
        _loadedFrom = effectiveFrom;
        _hasLoaded = true;
      }

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
        await _reload(mask: pending, from: _loadedFrom);
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
