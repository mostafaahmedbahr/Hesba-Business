import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../profile/data/models/user_profile.dart';
import '../../../data/models/sale_model.dart';
import '../../cubit/sales_list_state.dart';
import 'invoice_helpers.dart';
import 'package:hesba/core/services/app_logger.dart';

/// بطاقة الفاتورة بهيئة الفواتير المتعارف عليها — ثابتة الألوان (أبيض)
/// عشان تطلع واضحة في الصورة سواء التطبيق فاتح أو غامق.
class InvoiceCard extends StatelessWidget {
  final SaleModel sale;
  final UserProfile? profile;
  const InvoiceCard({super.key, required this.sale, this.profile});

  static const _ink = Color(0xFF111827);
  static const _grey = Color(0xFF64748B);
  static const _hairline = Color(0xFFE6EAF2);
  static const _soft = Color(0xFFF7F9FE);

  // أعمدة جدول الأصناف.
  static const _numW = 18.0;
  static const _qtyW = 40.0;
  static const _priceW = 58.0;
  static const _totalW = 64.0;

  String _date(BuildContext context) {
    final pattern = 'dd/MM/yyyy  •  hh:mm a';
    final locale = context.locale.languageCode;
    try {
      return DateFormat(pattern, locale).format(sale.createdAt);
    } catch (logErr, logSt) {
      AppLogger.nonFatal('features/sales/presentation/widgets/invoice/invoice_card.dart', logErr, logSt, severity: LoggingSeverity.warning);
      return DateFormat(pattern).format(sale.createdAt);
    }
  }

  /// شعار المحل (صورة مدوّرة أو أيقونة بديلة).
  Widget _logo(String url) {
    const fallback = Icon(Icons.storefront_rounded,
        color: AppTheme.primaryColor, size: 30);
    return Container(
      width: 66,
      height: 66,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.30), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: url.isEmpty
            ? Container(
                color: AppTheme.primarySoft,
                alignment: Alignment.center,
                child: fallback,
              )
            : Image.network(
                url,
                width: 60,
                height: 60,
                // Decode at 2x the displayed size to keep invoice lists light.
                cacheWidth: 120,
                cacheHeight: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppTheme.primarySoft,
                  alignment: Alignment.center,
                  child: fallback,
                ),
                // مكان الصورة لحد ما أول إطار يوصل (أحسن من دائرة فاضية).
                frameBuilder: (ctx, child, frame, wasSync) {
                  if (wasSync) return child;
                  if (frame == null) {
                    return Container(
                      color: AppTheme.primarySoft,
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.primaryColor),
                      ),
                    );
                  }
                  return child;
                },
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = 'currencyEGP'.tr();
    final id = shortInvoiceId(sale.saleId);
    final shopName = shopNameOf(sale, profile);
    final address = invoiceAddressOf(profile);
    final phone = invoicePhoneOf(profile);
    final customer = sale.personName.trim();
    final customerPhone = sale.personPhone.trim();
    String qtyFmt(double q) => q.toStringAsFixed(q % 1 == 0 ? 0 : 1);

    // خلية بيانات صغيرة (عنوان + قيمة).
    Widget metaCell(
      String label,
      String value, {
      bool ltr = false,
    }) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                color: _grey,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: ltr ? ui.TextDirection.ltr : null,
              style: const TextStyle(
                fontSize: 12,
                color: _ink,
                fontWeight: FontWeight.w800,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        );

    // خلية في جدول الأصناف.
    Widget cell(
      String text, {
      double? width,
      TextAlign align = TextAlign.start,
      bool header = false,
      bool bold = false,
      int maxLines = 1,
    }) {
      final style = TextStyle(
        fontSize: header ? 10.5 : (bold ? 11 : 10.5),
        color: header ? Colors.white : _ink,
        fontWeight: header
            ? FontWeight.w800
            : (bold ? FontWeight.w800 : FontWeight.w600),
        fontFamily: AppTheme.fontFamily,
      );
      final child = width == null
          ? Expanded(
              child: Text(
                text,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                textAlign: align,
                style: style,
              ),
            )
          : SizedBox(
              width: width,
              child: Text(text,
                  textAlign: align,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: style),
            );
      return child;
    }

    // صف جدول (رقم / صنف / كمية / سعر / إجمالي).
    Widget itemRow(int index, {required bool header, SaleItemModel? it}) {
      final isHeader = header;
      final bg = isHeader
          ? AppTheme.primaryColor
          : (index.isEven ? Colors.white : _soft);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          border: isHeader
              ? null
              : const Border(bottom: BorderSide(color: _hairline)),
        ),
        child: Row(
          children: [
            cell(isHeader ? '#' : '${index + 1}', width: _numW, header: isHeader),
            cell(
              isHeader ? 'invoiceColItem'.tr() : it!.productName,
              header: isHeader,
              bold: !isHeader,
              maxLines: isHeader ? 1 : 2,
            ),
            cell(
              isHeader ? 'invoiceColQty'.tr() : qtyFmt(it!.quantity),
              width: _qtyW,
              align: TextAlign.center,
              header: isHeader,
            ),
            cell(
              isHeader
                  ? 'invoiceColPrice'.tr()
                  : it!.unitPrice.toStringAsFixed(2),
              width: _priceW,
              align: TextAlign.end,
              header: isHeader,
            ),
            cell(
              isHeader
                  ? 'invoiceColTotal'.tr()
                  : it!.total.toStringAsFixed(2),
              width: _totalW,
              align: TextAlign.end,
              header: isHeader,
              bold: !isHeader,
            ),
          ],
        ),
      );
    }

    // صف إجمالي (عنوان + قيمة).
    Widget totalRow(String label, String value, {Color color = _ink}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11.5,
                      color: _grey,
                      fontWeight: FontWeight.w700,
                      fontFamily: AppTheme.fontFamily)),
              Text(value,
                  style: TextStyle(
                      fontSize: 12.5,
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontFamily: AppTheme.fontFamily)),
            ],
          ),
        );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // شريط علوي ملوّن.
            Container(
              height: 5,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A1F5C), AppTheme.primaryColor],
                ),
              ),
            ),
            // ── هيدر المحل ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
              child: Column(
                children: [
                  _logo(profile?.shopImageUrl.trim() ?? ''),
                  const SizedBox(height: 10),
                  Text(
                    shopName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      color: _ink,
                      fontWeight: FontWeight.w900,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      address,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _grey,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone_rounded,
                            size: 12, color: _grey),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _grey,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  // عنوان المستند (فاتورة مبيعات).
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color:
                              AppTheme.primaryColor.withValues(alpha: 0.20)),
                    ),
                    child: Text(
                      'invoiceDocTitle'.tr(),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.w900,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: _hairline),
            // ── بيانات الفاتورة ───────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              color: _soft,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: metaCell(
                              'invoiceNumber'.tr(), '\u200E#$id', ltr: true)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: metaCell('invoiceDate'.tr(), _date(context),
                              ltr: true)),
                    ],
                  ),
                  if (customer.isNotEmpty || customerPhone.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: metaCell(
                            'invoiceCustomer'.tr(),
                            customer.isEmpty ? '—' : customer,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: metaCell(
                            'invoicePhone'.tr(),
                            customerPhone.isEmpty ? '—' : customerPhone,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: _hairline),
            // ── جدول الأصناف ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _hairline),
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    itemRow(0, header: true),
                    for (var i = 0; i < sale.items.length; i++)
                      itemRow(i, header: false, it: sale.items[i]),
                  ],
                ),
              ),
            ),
            // ── الإجماليات ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.18)),
                ),
                child: Column(
                  children: [
                    if (sale.discount > 0) ...[
                      totalRow(
                        'salesBeforeDiscount'.tr(),
                        'moneyAmount'.tr(namedArgs: {
                          'total': (sale.subtotal > 0
                                  ? sale.subtotal
                                  : sale.total + sale.discount)
                              .toStringAsFixed(2),
                          'currency': currency,
                        }),
                      ),
                      totalRow(
                        'salesDiscount'.tr(),
                        '- ${sale.discount.toStringAsFixed(2)} $currency',
                        color: AppTheme.danger,
                      ),
                      const SizedBox(height: 4),
                      const Divider(height: 1, color: _hairline),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'saleInvoiceTotal'.tr(),
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: AppTheme.primaryDark,
                            fontWeight: FontWeight.w900,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        Text(
                          'moneyAmount'.tr(namedArgs: {
                            'total': sale.total.toStringAsFixed(2),
                            'currency': currency,
                          }),
                          style: const TextStyle(
                            fontSize: 17,
                            color: AppTheme.primaryDark,
                            fontWeight: FontWeight.w900,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // ── الدفع والملاحظة ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: metaCell('salePaymentMethod'.tr(),
                        SalesListState.paymentLabel(sale.paymentMethod)),
                  ),
                  if (sale.note.trim().isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Expanded(
                        child: metaCell(
                            'invoiceNote'.tr(), sale.note.trim())),
                  ],
                ],
              ),
            ),
            // ── الفوتر ────────────────────────────────────
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                color: _soft,
                border: Border(top: BorderSide(color: _hairline)),
              ),
              child: Column(
                children: [
                  Text(
                    'invoiceThanks'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w900,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'invoiceFooter'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: _grey,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
