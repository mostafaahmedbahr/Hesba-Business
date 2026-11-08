import 'package:equatable/equatable.dart';

import '../../data/models/debt_model.dart';
import '../../data/models/person_model.dart';

enum AccountsStatus { loading, success, failure }

/// تبويبات شاشة الحسابات.
enum AccountsTab { customer, supplier }

/// حالة شاشة الحسابات (القائمة + البحث + الفلاتر + الإجماليات).
class AccountsState extends Equatable {
  final AccountsStatus status;
  final List<DebtModel> debts;

  /// قائمة الأشخاص الحيّة — تُستخدم في اقتراحات نموذج الإضافة.
  /// تُملأ من ستريم واحد فوق نفس الشاشة.
  final List<PersonModel> persons;

  final AccountsTab activeTab;
  final String searchQuery;

  /// فلتر حالة السداد — `null` يعني الكل.
  final DebtStatus? statusFilter;

  /// فلتر بالتاريخ (من/إلى) — `null` يعني بدون حد.
  final DateTime? dateFrom;
  final DateTime? dateTo;

  final String? errorMessage;

  const AccountsState({
    this.status = AccountsStatus.loading,
    this.debts = const [],
    this.persons = const [],
    this.activeTab = AccountsTab.customer,
    this.searchQuery = '',
    this.statusFilter,
    this.dateFrom,
    this.dateTo,
    this.errorMessage,
  });

  /// المديونيات الخاصة بالتبويب الحالي بعد البحث والفلاتر.
  List<DebtModel> get visibleDebts {
    final party =
        activeTab == AccountsTab.customer ? DebtParty.customer : DebtParty.supplier;
    final q = searchQuery.trim().toLowerCase();
    final qPhone = PersonModel.normalizePhone(q);
    final from = dateFrom;
    final to = dateTo;
    final list = debts.where((d) {
      if (d.partyType != party) return false;
      if (statusFilter != null && d.status != statusFilter) return false;
      final created = d.createdAt;
      if (from != null && created != null && created.isBefore(from)) {
        return false;
      }
      if (to != null && created != null) {
        // "إلى" شاملة لليوم كله.
        final end = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
        if (created.isAfter(end)) return false;
      }
      if (q.isEmpty) return true;
      if (d.personName.toLowerCase().contains(q)) return true;
      if (qPhone.isNotEmpty &&
          PersonModel.normalizePhone(d.personPhone).contains(qPhone)) {
        return true;
      }
      return false;
    }).toList();
    list.sort((a, b) {
      final ta = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final tb = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return tb.compareTo(ta);
    });
    return list;
  }

  /// إجمالي ما ليّا (كل الاتجاهات receivable) — بغض النظر عن التبويب.
  double get receivableTotal => debts
      .where((d) => d.direction == DebtDirection.receivable)
      .fold(0.0, (sum, d) => sum + d.remaining);

  /// إجمالي ما عليّ (كل الاتجاهات payable) — بغض النظر عن التبويب.
  double get payableTotal => debts
      .where((d) => d.direction == DebtDirection.payable)
      .fold(0.0, (sum, d) => sum + d.remaining);

  /// الصافي: موجب = السوق مديون لك، سالب = أنت مدين للسوق.
  double get netTotal => receivableTotal - payableTotal;

  /// عدد المديونيات غير المسددة بالكامل لكل طرف (لشارة التبويب).
  int openCount(AccountsTab tab) {
    final party = tab == AccountsTab.customer ? DebtParty.customer : DebtParty.supplier;
    return debts
        .where((d) => d.partyType == party && d.status != DebtStatus.paid)
        .length;
  }

  int get totalCount => debts.length;

  bool get hasActiveFilter =>
      statusFilter != null || dateFrom != null || dateTo != null;

  /// أشخاص الاقتراحات: الأولوية لنفس نوع التبويب ثم الباقي،
  /// مع فلترة بالنص المكتوب. أول [limit] نتيجة فقط.
  List<PersonModel> personSuggestions(String query, {int limit = 6}) {
    final q = query.trim();
    bool matches(PersonModel p) {
      if (q.isEmpty) return true;
      final lower = q.toLowerCase();
      if (p.name.toLowerCase().contains(lower)) return true;
      final qPhone = PersonModel.normalizePhone(q);
      if (qPhone.isNotEmpty && p.normalizedPhone.contains(qPhone)) return true;
      return false;
    }

    final filtered = persons.where(matches).toList();
    int rank(PersonModel p) =>
        (activeTab == AccountsTab.customer ? p.isCustomer : p.isSupplier)
            ? 0
            : 1;
    filtered.sort((a, b) {
      final aMatch = rank(a);
      final bMatch = rank(b);
      if (aMatch != bMatch) return aMatch.compareTo(bMatch);
      final ta = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final tb = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return tb.compareTo(ta);
    });
    return filtered.take(limit).toList();
  }

  static const _sentinel = Object();

  AccountsState copyWith({
    AccountsStatus? status,
    List<DebtModel>? debts,
    List<PersonModel>? persons,
    AccountsTab? activeTab,
    String? searchQuery,
    Object? statusFilter = _sentinel,
    Object? dateFrom = _sentinel,
    Object? dateTo = _sentinel,
    Object? errorMessage = _sentinel,
    bool clearError = false,
  }) {
    return AccountsState(
      status: status ?? this.status,
      debts: debts ?? this.debts,
      persons: persons ?? this.persons,
      activeTab: activeTab ?? this.activeTab,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: identical(statusFilter, _sentinel)
          ? this.statusFilter
          : statusFilter as DebtStatus?,
      dateFrom: identical(dateFrom, _sentinel)
          ? this.dateFrom
          : dateFrom as DateTime?,
      dateTo: identical(dateTo, _sentinel)
          ? this.dateTo
          : dateTo as DateTime?,
      errorMessage: clearError
          ? null
          : identical(errorMessage, _sentinel)
              ? this.errorMessage
              : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        debts,
        persons,
        activeTab,
        searchQuery,
        statusFilter,
        dateFrom,
        dateTo,
        errorMessage,
      ];
}
