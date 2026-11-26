import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/core/widgets/loading_widget.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';
import 'package:hesba/features/sales/presentation/cubit/sales_list_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hesba/core/utils/dynamic_text.dart';

/// تاب عام لعرض عناصر محل (منتجات / مبيعات / مصروفات) حسب [collection].
class ShopItemsTab extends StatelessWidget {
  const ShopItemsTab({super.key, required this.collection, required this.shopId});
  final String collection;
  final String shopId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      future: sl<AdminRepo>().getShopItems(collection: collection, shopId: shopId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const LoadingWidget();
        if (snap.hasError) return adminError('تعذر تحميل البيانات'.tr(), () => (context as Element).markNeedsBuild());
        final docs = [...(snap.data ?? [])]
          ..sort((a, b) {
            final da = AdminFmt.toDate(a.data()['createdAt']);
            final db = AdminFmt.toDate(b.data()['createdAt']);
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return db.compareTo(da);
          });
        if (docs.isEmpty) {
          return adminEmpty(
            collection == 'products' ? Icons.inventory_2_outlined : collection == 'sales' ? Icons.point_of_sale_outlined : Icons.money_off_outlined,
            'لا توجد عناصر'.tr(),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(AdminSpace.md, AdminSpace.xs, AdminSpace.md, AdminSpace.lg),
          itemCount: docs.length + 1,
          separatorBuilder: (_, i) => const SizedBox(height: AdminSpace.sm),
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AdminSpace.xs),
                child: Text(uiTr('العدد: ${docs.length}${docs.length >= 50 ? ' (أول 50)'.tr() : ''}'),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AdminColors.textSecondary(context), fontWeight: FontWeight.w700)),
              );
            }
            final d = docs[i - 1];
            return _itemRow(context, d.id, d.data());
          },
        );
      },
    );
  }

  Widget _itemRow(BuildContext context, String id, Map<String, dynamic> data) {
    switch (collection) {
      case 'products':
        return AdminCard(
          padding: const EdgeInsets.all(AdminSpace.md),
          child: Row(
            children: [
              AdminThumbnail(url: (data['imageUrl'] as String?) ?? '', size: 46, icon: Icons.inventory_2_outlined),
              const SizedBox(width: AdminSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((data['name'] as String?) ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text('${data['category'] ?? '-uiTr('} • الكمية: ${data[')stock'] ?? 0}',
                        style: TextStyle(color: AdminColors.textSecondary(context), fontSize: 12)),
                    const SizedBox(height: 2),
                    CopyableId(id: id),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AdminRadius.tag)),
                child: Text(AdminFmt.money((data['price'] as num?) ?? 0),
                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w800, fontSize: 12.5)),
              ),
            ],
          ),
        );
      case 'sales':
        return _saleCard(context, id, data);
      default:
        return AdminCard(
          padding: const EdgeInsets.all(AdminSpace.md),
          child: Row(
            children: [
              const AdminIconTile(icon: Icons.money_off_outlined, color: AdminColors.error, size: 46),
              const SizedBox(width: AdminSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((data['title'] as String?) ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text('${data['category'] ?? '-'} • ${AdminFmt.dateNum(data['createdAt'] ?? data['date'])}',
                        style: TextStyle(color: AdminColors.textSecondary(context), fontSize: 12)),
                    const SizedBox(height: 2),
                    CopyableId(id: id),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: AdminColors.error.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AdminRadius.tag)),
                child: Text(AdminFmt.money((data['amount'] as num?) ?? 0),
                    style: const TextStyle(color: AdminColors.error, fontWeight: FontWeight.w800, fontSize: 12.5)),
              ),
            ],
          ),
        );
    }
  }

  /// كارت فاتورة مبيعات كامل: المنتجات (الاسم × العدد + سعر الشراء والبيع)
  /// ثم الإجمالي قبل الخصم وبعده — حتى يفهم الأدمن الفاتورة من غير ما يفتحها.
  Widget _saleCard(BuildContext context, String id, Map<String, dynamic> data) {
    final items = (data['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final discount = (data['discount'] as num?) ?? 0;
    final total = (data['total'] as num?) ?? 0;
    // فواتير قديمة بلا subtotal → نشتقه من الإجمالي + الخصم.
    final subtotal = (data['subtotal'] as num?) ?? (total + discount);

    // طريقة الدفع بالعربي زي شاشة العميل (نقدي / بطاقة / محفظة).
    final method = (data['paymentMethod'] as String?) ?? '';
    final methodLabel = method.isEmpty ? '' : SalesListState.paymentLabel(method);

    return AdminCard(
      padding: const EdgeInsets.all(AdminSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AdminIconTile(icon: Icons.point_of_sale_outlined, color: AdminColors.success, size: 46),
              const SizedBox(width: AdminSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('فاتورة مبيعات'.tr(), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      '${AdminFmt.dateNum(data['createdAt'])}${methodLabel.isNotEmpty ? ' • $methodLabel' : ''}',
                      style: TextStyle(color: AdminColors.textSecondary(context), fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    CopyableId(id: id),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: AdminColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AdminRadius.tag)),
                child: Text(AdminFmt.money(total),
                    style: const TextStyle(color: AdminColors.success, fontWeight: FontWeight.w800, fontSize: 12.5)),
              ),
            ],
          ),
          if (items.isNotEmpty) ...[
            const Divider(height: 16),
            for (final item in items) _saleItemRow(context, item),
          ],
          const Divider(height: 16),
          _saleTotalRow(context, 'قبل الخصم'.tr(), subtotal),
          if (discount > 0) ...[
            const SizedBox(height: 2),
            _saleTotalRow(context, 'الخصم'.tr(), -discount, negative: true),
          ],
          const SizedBox(height: 2),
          _saleTotalRow(context, 'بعد الخصم'.tr(), total, bold: true),
        ],
      ),
    );
  }

  /// صنف داخل الفاتورة: اسم المنتج × العدد + سعر الشراء وسعر البيع
  /// (الفواتير القديمة بلا costPrice → نعرض سعر البيع فقط).
  Widget _saleItemRow(BuildContext context, Map<String, dynamic> item) {
    final name = (item['productName'] as String?) ?? '-';
    final qtyNum = (item['quantity'] as num?) ?? 0;
    final qty = qtyNum == qtyNum.roundToDouble() ? '${qtyNum.toInt()}' : '$qtyNum';
    final cost = (item['costPrice'] as num?) ?? 0;
    final price = (item['unitPrice'] as num?) ?? 0;
    final lineTotal = (item['total'] as num?) ?? (qtyNum * price);

    final prices = cost > 0
        ? uiTr('شراء: ${AdminFmt.money(cost)} • بيع: ${AdminFmt.money(price)}')
        : uiTr('سعر البيع: ${AdminFmt.money(price)}');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AdminRadius.tag)),
            child: Text('×$qty',
                style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w800, fontSize: 11.5)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 1),
                Text(prices,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AdminColors.textSecondary(context), fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(AdminFmt.money(lineTotal),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
        ],
      ),
    );
  }

  /// سطر إجمالي في أسفل الفاتورة (قبل الخصم / الخصم / بعد الخصم).
  Widget _saleTotalRow(BuildContext context, String label, num amount,
      {bool bold = false, bool negative = false}) {
    final color = negative
        ? AdminColors.error
        : (bold ? AdminColors.success : AdminColors.textSecondary(context));
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(
                color: AdminColors.textSecondary(context),
                fontSize: 12.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              )),
        ),
        Text(AdminFmt.money(amount),
            style: TextStyle(
              color: color,
              fontSize: bold ? 14 : 12.5,
              fontWeight: FontWeight.w800,
            )),
      ],
    );
  }
}
