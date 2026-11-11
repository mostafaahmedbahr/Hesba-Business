import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../../../../core/utils/phone_contact.dart';
import '../../data/models/sale_model.dart';
import '../cubit/sales_list_state.dart';

/// كارت فاتورة مختصر — ضغطة تفتح التفاصيل بأنيميشن.
/// [fromCustomerHistory] تُخفي زرار "فواتير العميل" (اللي بيفاتح نفس
/// الشاشة) عند استخدام الكارت داخل شاشة سجل مشتريات العميل.
class SalesListCard extends StatefulWidget {
  final SaleModel sale;
  final bool fromCustomerHistory;
  const SalesListCard({
    super.key,
    required this.sale,
    this.fromCustomerHistory = false,
  });

  @override
  State<SalesListCard> createState() => _SalesListCardState();
}

/// حالة الفتح/القفل للكارت.
class _SalesListCardState extends State<SalesListCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sale = widget.sale;
    final dateStr = DateFormat('dd/MM/yyyy  •  hh:mm a', 'ar').format(sale.createdAt);
    final idShort = sale.saleId.length >= 6 ? sale.saleId.substring(0, 6) : sale.saleId;
    final itemsLabel = sale.items.isEmpty
        ? 'salesInvoice'.tr()
        : sale.items.length == 1
            ? sale.items.first.productName
            : '${sale.items.first.productName} +${sale.items.length - 1}';
    final customerSuffix =
        sale.personName.trim().isNotEmpty ? ' • ${sale.personName.trim()}' : '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: _expanded
              ? AppTheme.primaryColor.withValues(alpha: 0.35)
              : (isDark ? AppTheme.darkBorder : const Color(0xFFE8ECF3)),
        ),
        boxShadow: _expanded
            ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.12), blurRadius: 22, offset: const Offset(0, 10))]
            : AppTheme.cardShadow(context),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(22.r),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _expanded = !_expanded);
          },
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الملخص الدائم.
                Row(children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppTheme.primaryColor, Color(0xFF6D9BFF)]),
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Icon(Icons.receipt_long_rounded, size: 22.sp, color: Colors.white),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Flexible(child: Text('salesInvoiceNumber'.tr(namedArgs: {'id': idShort}), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.ink))),
                          if (sale.discount > 0) ...[
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                              decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8.r)),
                              child: Text('salesDiscount'.tr(), style: TextStyle(fontSize: 9.5.sp, fontWeight: FontWeight.w800, color: AppTheme.danger)),
                            ),
                          ],
                        ]),
                        SizedBox(height: 3.h),
                        Text('$itemsLabel$customerSuffix • $dateStr', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.sp, color: AppTheme.mutedGray, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(sale.total.toStringAsFixed(2), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, color: AppTheme.successDark, height: 1)),
                      Text('ج.م', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: AppTheme.mutedGray)),
                    ],
                  ),
                  SizedBox(width: 4.w),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: BoxDecoration(color: _expanded ? AppTheme.primaryColor.withValues(alpha: 0.10) : Colors.transparent, shape: BoxShape.circle),
                      child: Icon(Icons.keyboard_arrow_down_rounded, size: 20.sp, color: _expanded ? AppTheme.primaryColor : AppTheme.mutedGray),
                    ),
                  ),
                ]),
                // التفاصيل (تظهر بالضغطة).
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: _Details(sale: sale, isDark: isDark, fromCustomerHistory: widget.fromCustomerHistory),
                  crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 260),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// تفاصيل الفاتورة (عميل + أصناف + دفع + مرتجع).
class _Details extends StatelessWidget {
  final SaleModel sale;
  final bool isDark;
  final bool fromCustomerHistory;
  const _Details({required this.sale, required this.isDark, this.fromCustomerHistory = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.slatePale,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE6EAF2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sale.hasCustomer) ...[
              _CustomerBlock(
                sale: sale,
                isDark: isDark,
                fromCustomerHistory: fromCustomerHistory,
              ),
              SizedBox(height: 10.h),
            ],
            ...sale.items.map((it) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 7.w, height: 7.w, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppTheme.primaryColor, Color(0xFF6D9BFF)]))),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              '${it.productName} × ${it.quantity.toStringAsFixed(it.quantity % 1 == 0 ? 0 : 1)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                            ),
                          ),
                          Text('moneyAmount'.tr(namedArgs: {'total': it.total.toStringAsFixed(2), 'currency': 'currencyEGP'.tr()}), style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppTheme.slateGray)),
                        ],
                      ),
                      // سعر الشراء وسعر البيع للصنف (الفواتير القديمة بلا تكلفة → البيع فقط).
                      Padding(
                        padding: EdgeInsets.only(left: 15.w, top: 2.h),
                        child: Text(
                          it.costPrice > 0
                              ? 'saleItemCostSale'.tr(namedArgs: {
                                  'cost': it.costPrice.toStringAsFixed(2),
                                  'price': it.unitPrice.toStringAsFixed(2),
                                  'currency': 'currencyEGP'.tr(),
                                })
                              : 'saleItemSalePrice'.tr(namedArgs: {
                                  'price': it.unitPrice.toStringAsFixed(2),
                                  'currency': 'currencyEGP'.tr(),
                                }),
                          style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w600, color: AppTheme.mutedGray),
                        ),
                      ),
                    ],
                  ),
                )),
            if (sale.discount > 0) ...[
              // المجموع قبل الخصم (المجموع الكلي للأصناف).
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('salesBeforeDiscount'.tr(), style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: AppTheme.slateGray)),
                    Text(
                      'moneyAmount'.tr(namedArgs: {
                        'total': (sale.subtotal > 0 ? sale.subtotal : sale.total + sale.discount).toStringAsFixed(2),
                        'currency': 'currencyEGP'.tr(),
                      }),
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: AppTheme.slateGray),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(10.r)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('salesAfterDiscount'.tr(namedArgs: {'discount': sale.discount.toStringAsFixed(0), 'currency': 'currencyEGP'.tr()}), style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: AppTheme.danger)),
                    Text('moneyAmount'.tr(namedArgs: {'total': sale.total.toStringAsFixed(2), 'currency': 'currencyEGP'.tr()}), style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w900, color: AppTheme.successDark)),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
            ],
            Row(children: [
              SalesPaymentChip(method: sale.paymentMethod, isDark: isDark),
              const Spacer(),
              Text(dateTimeLabel(sale.createdAt), style: TextStyle(fontSize: 10.5.sp, color: AppTheme.mutedGray, fontWeight: FontWeight.w600)),
            ]),
            if (sale.note.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.notes_rounded, size: 13.sp, color: AppTheme.mutedGray),
                SizedBox(width: 5.w),
                Expanded(child: Text(sale.note, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5.sp, color: isDark ? AppTheme.darkTextSecondary : AppTheme.slateGray))),
              ]),
            ],
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              height: 44.h,
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pushNamed(context, AppRoutes.addReturnView, arguments: {'originalSaleId': sale.saleId});
                },
                icon: Icon(Icons.assignment_return_rounded, size: 17.sp, color: AppTheme.amberDeep),
                label: Text('salesReturnLinked'.tr(), style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: AppTheme.amberDeep)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.warningAmber.withValues(alpha: 0.35)),
                  backgroundColor: AppTheme.warningAmber.withValues(alpha: 0.07),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// وقت مختصر (اليوم / أمس / تاريخ).
String dateTimeLabel(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(day).inDays;
  final time = DateFormat('hh:mm a').format(dt);
  if (diff == 0) return 'dayToday'.tr(namedArgs: {'time': time});
  if (diff == 1) return 'dayYesterday'.tr(namedArgs: {'time': time});
  return '${DateFormat('dd/MM').format(dt)} • $time';
}

/// بلوك عميل الفاتورة داخل التفاصيل: اسم + رقم + اتصال/واتساب
/// + زرار فتح سجل مشتريات العميل.
class _CustomerBlock extends StatelessWidget {
  final SaleModel sale;
  final bool isDark;
  final bool fromCustomerHistory;
  const _CustomerBlock({
    required this.sale,
    required this.isDark,
    required this.fromCustomerHistory,
  });

  @override
  Widget build(BuildContext context) {
    final name = sale.personName.trim();
    final phone = sale.personPhone.trim();
    final idShort = sale.personId.length >= 6 ? sale.personId.substring(0, 6) : sale.personId;
    final canOpenHistory = sale.personId.isNotEmpty && !fromCustomerHistory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person_rounded, size: 12.sp, color: AppTheme.mutedGray),
            SizedBox(width: 5.w),
            Text(
              'saleCustomerTitle'.tr(),
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w800,
                color: AppTheme.mutedGray,
              ),
            ),
            if (idShort.isNotEmpty) ...[
              SizedBox(width: 6.w),
              Text(
                '#$idShort',
                style: TextStyle(
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.mutedGray,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(13.r),
            border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 17.r,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                child: Text(
                  name.isEmpty ? '؟' : name.substring(0, 1),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? '—' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppTheme.ink,
                      ),
                    ),
                    if (phone.isNotEmpty)
                      Text(
                        phone,
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.slateGray,
                        ),
                      ),
                  ],
                ),
              ),
              if (phone.isNotEmpty) ...[
                _ContactIconButton(
                  icon: Icons.call_rounded,
                  tooltip: 'contactCall'.tr(),
                  onTap: () => PhoneContact.call(context, phone),
                ),
                SizedBox(width: 4.w),
                _ContactIconButton(
                  icon: Icons.chat_rounded,
                  tooltip: 'contactWhatsApp'.tr(),
                  onTap: () => PhoneContact.whatsapp(context, phone),
                ),
              ],
            ],
          ),
        ),
        if (canOpenHistory) ...[
          SizedBox(height: 8.h),
          SizedBox(
            width: double.infinity,
            height: 40.h,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.pushNamed(
                  context,
                  AppRoutes.customerSalesView,
                  arguments: {
                    'personId': sale.personId,
                    'personName': sale.personName,
                    'personPhone': sale.personPhone,
                    'shopId': sale.shopId,
                  },
                );
              },
              icon: Icon(Icons.receipt_long_rounded, size: 16.sp, color: AppTheme.primaryColor),
              label: Text(
                'customerSalesHistoryButton'.tr(),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.35)),
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.06),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// زرار دائري صغير لاتصال/واتساب داخل بلوك العميل.
class _ContactIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _ContactIconButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppTheme.primaryColor.withValues(alpha: 0.10),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          customBorder: const CircleBorder(),
          child: Padding(
            padding: EdgeInsets.all(8.w),
            child: Icon(icon, size: 17.sp, color: AppTheme.primaryColor),
          ),
        ),
      ),
    );
  }
}

/// شارة طريقة الدفع.
class SalesPaymentChip extends StatelessWidget {
  final String method;
  final bool isDark;
  const SalesPaymentChip({super.key, required this.method, required this.isDark});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (method) {
      case 'cash':
        icon = Icons.money_rounded;
        break;
      case 'card':
        icon = Icons.credit_card_rounded;
        break;
      case 'mobile_wallet':
      case 'wallet':
        icon = Icons.account_balance_wallet_rounded;
        break;
      case 'credit':
        icon = Icons.schedule_rounded;
        break;
      default:
        icon = Icons.payment_rounded;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12.sp, color: AppTheme.slateGray),
        SizedBox(width: 5.w),
        Text(SalesListState.paymentLabel(method), style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: AppTheme.slateGray)),
      ]),
    );
  }
}
