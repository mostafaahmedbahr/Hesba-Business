import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/core/widgets/loading_widget.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_list_cubit.dart';
import 'package:hesba/features/reports/data/reports_calculator.dart';
import 'package:hesba/features/sales/data/models/sale_model.dart';
import 'package:hesba/features/sales/presentation/cubit/sales_list_state.dart';

class SalesView extends StatefulWidget {
  const SalesView({super.key});

  @override
  State<SalesView> createState() => _SalesViewState();
}

class _SalesViewState extends State<SalesView> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _method = 'الكل';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminListCubit(
        fetch: (startAfter) =>
            sl<AdminRepo>().getSalesPage(startAfter: startAfter),
      )..firstPage(),
      child: BlocBuilder<AdminListCubit, AdminListState>(
        builder: (context, state) {
          if (state.loading && state.docs.isEmpty) {
            return Column(
              children: [
                AdminSearchField(
                  controller: _searchCtrl,
                  hint: 'ابحث برقم العملية أو المحل...',
                  enabled: false,
                ),
                Expanded(child: LoadingWidget()),
              ],
            );
          }
          if (state.error != null && state.docs.isEmpty) {
            return adminError(
              state.error!,
              () => context.read<AdminListCubit>().firstPage(),
            );
          }
          if (state.docs.isEmpty) {
            return Column(
              children: [
                AdminSearchField(
                  controller: _searchCtrl,
                  hint: 'ابحث برقم العملية أو المحل...',
                  enabled: false,
                ),
                Expanded(
                  child: adminEmpty(
                    Icons.point_of_sale_outlined,
                    'لا توجد مبيعات بعد',
                    'عند تسجيل أول عملية بيع ستظهر هنا',
                  ),
                ),
              ],
            );
          }

          final methods = _extractMethods(state.docs);
          final filtered = _applyFilter(state.docs);
          final filtering = _query.isNotEmpty || _method != 'الكل';
          final revenue = filtered.fold<num>(
            0,
            (acc, d) => acc + ((d.data()['total'] as num?) ?? 0),
          );
          final sales = filtered
              .map((d) => SaleModel.fromJson(d.data()))
              .toList();
          final profit = sales.fold<double>(
            0,
            (acc, s) => acc + ReportsCalculator.netProfitForSale(s),
          );
          final unknownLines = sales.fold<int>(
            0,
            (acc, s) => acc + s.items.where((i) => i.costPrice <= 0).length,
          );
          final totalDiscount = sales.fold<double>(
            0,
            (acc, s) => acc + s.discount,
          );

          return RefreshIndicator(
            onRefresh: () => context.read<AdminListCubit>().firstPage(),
            child: Column(
              children: [
                const AdminPageHeader(
                  title: 'المبيعات',
                  description: 'عمليات البيع في جميع المحلات المسجلة',
                ),
                AdminSummaryHeader(
                  icon: Icons.point_of_sale_outlined,
                  title: 'إجمالي الإيرادات (المعروض)',
                  total: revenue.toInt(),
                  unit: 'ج',
                  stats: [
                    'العمليات: ${filtered.length}',
                    'الربح${unknownLines > 0 ? ' (تقديري)' : ''}: ${AdminFmt.money(profit)}',
                    if (totalDiscount > 0)
                      'الخصم: ${AdminFmt.money(totalDiscount)}',
                  ],
                  loading: state.loading,
                  onRefresh: () => context.read<AdminListCubit>().firstPage(),
                ),
                AdminSearchField(
                  controller: _searchCtrl,
                  hint: 'ابحث برقم العملية أو المحل...',
                  onChanged: (v) => setState(() => _query = v),
                ),
                AdminFilterChips(
                  selected: _method,
                  onSelect: (k) => setState(() => _method = k),
                  // القيمة خام للفلترة (cash/...) واللي يظهر عربي زي شاشة العميل.
                  items: [
                    for (final m in methods)
                      AdminChipItem(
                        m,
                        m == 'الكل' ? m : SalesListState.paymentLabel(m),
                      ),
                  ],
                ),
                if (filtering)
                  AdminResultCount(
                    count: filtered.length,
                    onClear: () => setState(() {
                      _query = '';
                      _searchCtrl.clear();
                      _method = 'الكل';
                    }),
                  ),
                Expanded(
                  child: filtered.isEmpty
                      ? adminEmpty(
                          Icons.search_off_outlined,
                          'لا توجد نتائج مطابقة لبحثك',
                          'جرّب كلمة مختلفة أو امسح الفلتر',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            0,
                            AdminSpace.xs,
                            0,
                            AdminSpace.lg,
                          ),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AdminSpace.sm),
                          itemBuilder: (context, i) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AdminSpace.md,
                            ),
                            child: _SaleCard(
                              key: ValueKey(filtered[i].id),
                              doc: filtered[i],
                            ),
                          ),
                        ),
                ),
                if (state.hasMore)
                  AdminLoadMore(
                    loading: state.loading,
                    label: 'تحميل المزيد (${state.docs.length} معروض)',
                    onLoad: () => context.read<AdminListCubit>().nextPage(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<String> _extractMethods(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final set = <String>{};
    for (final d in docs) {
      final m = (d.data()['paymentMethod'] as String?)?.trim() ?? '';
      if (m.isNotEmpty) set.add(m);
    }
    return ['الكل', ...set.toList()..sort()];
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applyFilter(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final q = _query.trim();
    return docs.where((d) {
      final data = d.data();
      if (_method != 'الكل' &&
          (data['paymentMethod'] as String? ?? '') != _method) {
        return false;
      }
      if (q.isEmpty) return true;
      // البحث يشمل القيمة الخام (cash) والاسم العربي (نقدي).
      final rawMethod = (data['paymentMethod'] as String?) ?? '';
      final haystack = [
        data['shopId'],
        rawMethod,
        SalesListState.paymentLabel(rawMethod),
        data['personName'],
        data['personPhone'],
        d.id,
      ].whereType<String>().join(' ');
      return haystack.contains(q);
    }).toList();
  }
}

class _SaleCard extends StatefulWidget {
  const _SaleCard({super.key, required this.doc});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  State<_SaleCard> createState() => _SaleCardState();
}

class _SaleCardState extends State<_SaleCard> {
  /// الكارد يبدأ صغير، ويفضل مفتوح مكانه لحد ما تضغط تاني.
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final d = doc.data();

    final shopName = (d['shopName'] as String?) ?? '-';
    final total = (d['total'] as num?) ?? 0;
    final method = (d['paymentMethod'] as String?)?.trim() ?? '';
    final date = AdminFmt.dateNum(d['createdAt']);
    final customerName = (d['personName'] as String?)?.trim() ?? '';
    final customerPhone = (d['personPhone'] as String?)?.trim() ?? '';

    final sale = SaleModel.fromJson(d);
    final itemsCount = sale.items.length;
    final pieces = sale.items.fold<double>(0, (acc, i) => acc + i.quantity);
    final purchase = ReportsCalculator.saleCogs(sale);
    final profit = ReportsCalculator.netProfitForSale(sale);
    final unknownLines = sale.items.where((i) => i.costPrice <= 0).length;
    final discount = sale.discount;

    final secondary = AdminColors.textSecondary(context);

    return AdminCard(
      padding: const EdgeInsets.all(AdminSpace.md),
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop Header
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AdminColors.success.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AdminColors.success,
                  size: 23,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shopName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'اسم المحل',
                      style: TextStyle(color: secondary, fontSize: 11),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AdminColors.success.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'عملية بيع',
                  style: TextStyle(
                    color: AdminColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // الحالة المطوية: كارد صغير بالأرقام المهمة بس.
          if (!_expanded) ...[
            Text(
              '$itemsCount أصناف • ${_qty(pieces)} قطعة',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _miniStat(
                  'ربح',
                  '${AdminFmt.money(profit)}${unknownLines > 0 ? '*' : ''}',
                  AdminColors.success,
                  context,
                ),
                _miniStat(
                  'بيع',
                  AdminFmt.money(total),
                  AdminColors.info,
                  context,
                ),
                _miniStat(
                  'شراء',
                  AdminFmt.money(purchase),
                  AdminColors.warning,
                  context,
                ),
                if (discount > 0)
                  _miniStat(
                    'خصم',
                    AdminFmt.money(discount),
                    AdminColors.error,
                    context,
                  ),
              ],
            ),
          ],

          // الحالة المفتوحة: التفاصيل الكاملة، وتفضل مفتوحة لحد ما تضغط تاني.
          if (_expanded) ...[
            // Sale Details
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AdminColors.success.withValues(alpha: 0.045),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AdminColors.success.withValues(alpha: 0.09),
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 15,
                                color: secondary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'تفاصيل البيع',
                                style: TextStyle(
                                  color: secondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Text(
                            '$itemsCount أصناف • ${_qty(pieces)} قطعة',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 6),
                          _metricLine(
                            Icons.trending_up_rounded,
                            'الربح',
                            '${AdminFmt.money(profit)}${unknownLines > 0 ? ' (تقديري)' : ''}',
                            AdminColors.success,
                            secondary,
                          ),
                          const SizedBox(height: 4),
                          _metricLine(
                            Icons.point_of_sale_outlined,
                            'سعر البيع',
                            AdminFmt.money(total),
                            AdminColors.info,
                            secondary,
                          ),
                          const SizedBox(height: 4),
                          _metricLine(
                            Icons.shopping_cart_outlined,
                            'سعر الشراء',
                            '${AdminFmt.money(purchase)}${unknownLines > 0 ? ' (جزئي)' : ''}',
                            AdminColors.warning,
                            secondary,
                          ),
                          if (discount > 0) ...[
                            const SizedBox(height: 4),
                            _metricLine(
                              Icons.discount_outlined,
                              'الخصم',
                              AdminFmt.money(discount),
                              AdminColors.error,
                              secondary,
                            ),
                          ],

                          if (method.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.wallet_outlined,
                                  size: 14,
                                  color: secondary,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    SalesListState.paymentLabel(method),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: secondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          if (customerName.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 14,
                                  color: secondary,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    customerPhone.isNotEmpty
                                        ? '$customerName • $customerPhone'
                                        : customerName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: secondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    Container(
                      width: 1,
                      color: AdminColors.success.withValues(alpha: 0.15),
                    ),

                    const SizedBox(width: 12),

                    Column(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AdminColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.point_of_sale_rounded,
                            color: AdminColors.success,
                            size: 22,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          AdminFmt.money(total),
                          style: const TextStyle(
                            color: AdminColors.success,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // تفصيل الأصناف: العدد × الاسم + سعر الشراء والبيع + إجمالي السطر
            // ثم الإجمالي قبل/بعد الخصم — نفس منطق فاتورة تفاصيل المحل.
            _SaleBreakdown(data: d),

            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    showAdminSheet(context, _SaleDetailsSheet(doc: doc)),
                icon: const Icon(Icons.open_in_full_outlined, size: 16),
                label: const Text('تفاصيل كاملة'),
              ),
            ),

            const SizedBox(height: 8),
          ],

          const SizedBox(height: 2),

          // Footer
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 15, color: secondary),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  date,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              CopyableId(id: doc.id),
              const SizedBox(width: 6),
              Icon(
                _expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 18,
                color: secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
    String label,
    String value,
    Color color,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AdminRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: TextStyle(
              fontSize: 10.5,
              color: AdminColors.textSecondary(context),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricLine(
    IconData icon,
    String label,
    String value,
    Color color,
    Color secondary,
  ) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text('$label: ', style: TextStyle(color: secondary, fontSize: 11.5)),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

String _qty(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();

// ── Invoice breakdown: items, prices, discount, profit ────────

class _SaleBreakdown extends StatelessWidget {
  const _SaleBreakdown({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final sale = SaleModel.fromJson(data);
    final discount = sale.discount;
    final total = sale.total;
    // فواتير قديمة بلا subtotal → نشتقه من الإجمالي + الخصم.
    final subtotal =
        (data['subtotal'] as num?)?.toDouble() ?? (total + discount);
    final purchase = ReportsCalculator.saleCogs(sale);
    final profit = ReportsCalculator.netProfitForSale(sale);
    final unknown = sale.items.where((i) => i.costPrice <= 0).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sale.items.isEmpty)
          Text(
            'لا توجد أصناف مسجلة',
            style: TextStyle(
              color: AdminColors.textSecondary(context),
              fontSize: 12,
            ),
          ),
        for (final item in sale.items) _itemRow(context, item),
        const Divider(height: 16),
        _totalRow(context, 'قبل الخصم', subtotal),
        if (discount > 0) ...[
          const SizedBox(height: 2),
          _totalRow(context, 'الخصم', -discount, negative: true),
        ],
        const SizedBox(height: 2),
        _totalRow(context, 'سعر البيع (بعد الخصم)', total, bold: true),
        const SizedBox(height: 2),
        _totalRow(
          context,
          unknown > 0 ? 'سعر الشراء (تقديري)' : 'سعر الشراء',
          purchase,
        ),
        const SizedBox(height: 2),
        _totalRow(
          context,
          unknown > 0 ? 'الربح (تقديري)' : 'الربح',
          profit,
          bold: true,
          profit: true,
        ),
        const SizedBox(height: 2),
        Text(
          'الربح = سعر البيع − سعر الشراء',
          style: TextStyle(
            fontSize: 10.5,
            color: AdminColors.textMuted(context),
          ),
        ),
        if (unknown > 0) ...[
          const SizedBox(height: 4),
          Text(
            '* ${AdminFmt.number(unknown)} سطر بلا سعر شراء — استُبعد من حساب التكلفة',
            style: TextStyle(color: AdminColors.warning, fontSize: 10.5),
          ),
        ],
      ],
    );
  }

  Widget _itemRow(BuildContext context, SaleItemModel item) {
    // الفواتير القديمة بلا سعر شراء → نعرض سعر البيع فقط، ولا نفترض تكلفة صفرية.
    final prices = item.costPrice > 0
        ? 'شراء: ${AdminFmt.money(item.costPrice)} • بيع: ${AdminFmt.money(item.unitPrice)}'
        : 'سعر البيع: ${AdminFmt.money(item.unitPrice)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AdminColors.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AdminRadius.tag),
            ),
            child: Text(
              '×${_qty(item.quantity)}',
              style: const TextStyle(
                color: AdminColors.info,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  prices,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AdminColors.textSecondary(context),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            AdminFmt.money(item.total),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(
    BuildContext context,
    String label,
    num amount, {
    bool bold = false,
    bool negative = false,
    bool profit = false,
  }) {
    final color = profit || bold
        ? AdminColors.success
        : negative
        ? AdminColors.error
        : AdminColors.textSecondary(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AdminColors.textSecondary(context),
              fontSize: 12.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          AdminFmt.money(amount),
          style: TextStyle(
            color: color,
            fontSize: bold ? 14 : 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ── Details sheet ─────────────────────────────────────────────

class _SaleDetailsSheet extends StatelessWidget {
  const _SaleDetailsSheet({required this.doc});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    final sale = SaleModel.fromJson(d);
    final method = sale.paymentMethod.trim();
    final methodLabel = method.isEmpty
        ? ''
        : SalesListState.paymentLabel(method);
    final customer = [
      sale.personName,
      sale.personPhone,
    ].map((s) => s.trim()).where((s) => s.isNotEmpty).join(' • ');
    final pieces = sale.items.fold<double>(0, (acc, i) => acc + i.quantity);

    return AdminSheetShell(
      title: sale.shopName.isEmpty ? 'فاتورة مبيعات' : sale.shopName,
      subtitle: 'فاتورة مبيعات • ${AdminFmt.date(d['createdAt'])}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminInfoRow(
            icon: Icons.storefront_outlined,
            label: 'المحل',
            value: sale.shopName.isEmpty ? '-' : sale.shopName,
          ),
          const Divider(height: 16),
          AdminInfoRow(
            icon: Icons.inventory_2_outlined,
            label: 'الكمية',
            value:
                '${AdminFmt.number(sale.items.length)} أصناف • ${_qty(pieces)} قطعة',
          ),
          const Divider(height: 14),
          AdminInfoRow(
            icon: Icons.wallet_outlined,
            label: 'طريقة الدفع',
            value: methodLabel.isEmpty ? '-' : methodLabel,
          ),
          if (customer.isNotEmpty) ...[
            const Divider(height: 14),
            AdminInfoRow(
              icon: Icons.person_outline_rounded,
              label: 'العميل',
              value: customer,
            ),
          ],
          if (sale.note.trim().isNotEmpty) ...[
            const Divider(height: 14),
            AdminInfoRow(
              icon: Icons.notes_outlined,
              label: 'ملاحظة',
              value: sale.note.trim(),
            ),
          ],
          const Divider(height: 18),
          _SaleBreakdown(data: d),
          const Divider(height: 18),
          CopyableId(id: doc.id, full: true, label: 'رقم العملية'),
        ],
      ),
    );
  }
}
