import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../../../../core/utils/phone_contact.dart';
import '../../data/models/return_model.dart';

/// كارت مرتجع مختصر — ضغطة تفتح التفاصيل.
class ReturnsListCard extends StatefulWidget {
  final ReturnModel ret;
  const ReturnsListCard({super.key, required this.ret});

  @override
  State<ReturnsListCard> createState() => _ReturnsListCardState();
}

/// حالة الفتح/القفل للكارت.
class _ReturnsListCardState extends State<ReturnsListCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ret = widget.ret;
    final dateStr = DateFormat('dd/MM/yyyy  •  hh:mm a', 'ar').format(ret.createdAt);
    final idShort = ret.returnId.length >= 6 ? ret.returnId.substring(0, 6) : ret.returnId;
    final itemsLabel = ret.items.isEmpty
        ? (ret.reason.isEmpty ? 'مرتجع' : ret.reason)
        : ret.items.length == 1
            ? ret.items.first.productName
            : '${ret.items.first.productName} +${ret.items.length - 1}';
    final customerSuffix =
        ret.personName.trim().isNotEmpty ? ' • ${ret.personName.trim()}' : '';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: _expanded ? AppTheme.warningAmber.withValues(alpha: 0.35) : (isDark ? AppTheme.darkBorder : AppTheme.hairline),
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
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
                    width: 46.w,
                    height: 46.w,
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.warningAmber, AppTheme.goldLight]), borderRadius: BorderRadius.circular(13.r)),
                    child: Icon(Icons.assignment_return_rounded, size: 21.sp, color: Colors.white),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('retReturnNumber'.tr(namedArgs: {'id': idShort}), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.ink)),
                        SizedBox(height: 3.h),
                        Text('$itemsLabel$customerSuffix • $dateStr', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.sp, color: AppTheme.mutedGray, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('-${ret.total.toStringAsFixed(2)}', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: AppTheme.danger, height: 1)),
                      Text('ج.م', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: AppTheme.mutedGray)),
                    ],
                  ),
                  SizedBox(width: 6.w),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down_rounded, size: 22.sp, color: AppTheme.mutedGray),
                  ),
                ]),
                // التفاصيل (تظهر بالضغطة).
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: _Details(ret: ret, isDark: isDark),
                  crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// صف عميل الفاتورة داخل تفاصيل المرتجع: الاسم/الرقم + تواصل
/// + زرار فتح سجل مشتريات العميل (لو متوفّر personId).
class _ReturnCustomerRow extends StatelessWidget {
  final ReturnModel ret;
  final bool isDark;
  const _ReturnCustomerRow({required this.ret, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final name = ret.personName.trim();
    final phone = ret.personPhone.trim();
    final canOpenHistory = ret.personId.isNotEmpty;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(13.r),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_rounded, size: 13.sp, color: AppTheme.mutedGray),
              SizedBox(width: 5.w),
              Text(
                'saleCustomerTitle'.tr(),
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.mutedGray,
                ),
              ),
              const Spacer(),
              if (phone.isNotEmpty) ...[
                _MiniContactButton(
                  icon: Icons.call_rounded,
                  tooltip: 'contactCall'.tr(),
                  onTap: () => PhoneContact.call(context, phone),
                ),
                SizedBox(width: 4.w),
                _MiniContactButton(
                  icon: Icons.chat_rounded,
                  tooltip: 'contactWhatsApp'.tr(),
                  onTap: () => PhoneContact.whatsapp(context, phone),
                ),
              ],
            ],
          ),
          SizedBox(height: 5.h),
          Row(
            children: [
              CircleAvatar(
                radius: 15.r,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                child: Text(
                  name.isEmpty ? '؟' : name.substring(0, 1),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
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
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.slateGray,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (canOpenHistory) ...[
            SizedBox(height: 8.h),
            SizedBox(
              width: double.infinity,
              height: 38.h,
              child: TextButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.pushNamed(
                    context,
                    AppRoutes.customerSalesView,
                    arguments: {
                      'personId': ret.personId,
                      'personName': ret.personName,
                      'personPhone': ret.personPhone,
                      'shopId': ret.shopId,
                    },
                  );
                },
                icon: Icon(Icons.receipt_long_rounded,
                    size: 15.sp, color: AppTheme.primaryColor),
                label: Text(
                  'customerSalesHistoryButton'.tr(),
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// زرار دائري صغير لاتصال/واتساب داخل صف العميل.
class _MiniContactButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _MiniContactButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppTheme.primaryColor.withValues(alpha: 0.10),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: EdgeInsets.all(7.w),
            child: Icon(icon, size: 15.sp, color: AppTheme.primaryColor),
          ),
        ),
      ),
    );
  }
}

/// تفاصيل المرتجع (أصناف + سبب + ملاحظة).
class _Details extends StatelessWidget {
  final ReturnModel ret;
  final bool isDark;
  const _Details({required this.ret, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.canvasLight,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ret.personName.trim().isNotEmpty) ...[
              _ReturnCustomerRow(ret: ret, isDark: isDark),
              SizedBox(height: 10.h),
            ],
            ...ret.items.map((it) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${it.productName} × ${it.quantity.toStringAsFixed(it.quantity % 1 == 0 ? 0 : 1)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text('${it.total.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppTheme.slateGray)),
                    ],
                  ),
                )),
            Row(children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: const Color(0xFFFDBA74))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.info_outline_rounded, size: 12.sp, color: AppTheme.amberDeep),
                  SizedBox(width: 5.w),
                  Text(ret.reason.isEmpty ? 'retNoReason'.tr() : ret.reason, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: AppTheme.amberDeep)),
                ]),
              ),
              if (ret.originalSaleId != null) ...[
                SizedBox(width: 6.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: const Color(0xFFBFDBFE))),
                  child: Text('retLinkedInvoice'.tr(), style: TextStyle(fontSize: 10.sp, color: AppTheme.blueBright, fontWeight: FontWeight.w700)),
                ),
              ],
              const Spacer(),
              Text(dateTimeLabel(ret.createdAt), style: TextStyle(fontSize: 10.5.sp, color: AppTheme.mutedGray)),
            ]),
            if (ret.note.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(ret.note, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5.sp, color: isDark ? AppTheme.darkTextSecondary : AppTheme.slateGray)),
            ],
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
