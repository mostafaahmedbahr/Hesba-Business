import 'dart:async';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/phone_contact.dart';
import '../../../../core/utils/toast.dart';
import '../../../profile/data/models/user_profile.dart';
import '../../../profile/data/repos/account_repo.dart';
import '../../data/models/sale_model.dart';
import '../cubit/sales_list_state.dart';

/// ───────────────────────────────────────────────────────────────
///  إصدار فاتورة البيع كصورة (بهيئة الفواتير المتعارف عليها):
///  - شعار/صورة المحل + اسمه وعنوانه وهاتفه.
///  - رقم الفاتورة والتاريخ والعميل.
///  - جدول أصناف (الصنف / الكمية / السعر / الإجمالي) + الإجماليات.
///  - التصوير عبر [RepaintBoundary.toImage] ثم الإرسال عبر واتساب
///    أو المشاركة بأي تطبيق.
/// ───────────────────────────────────────────────────────────────

/// معرّف مختصر للفاتورة (نفس منطق كارت المبيعات).
String _shortInvoiceId(String saleId) =>
    saleId.length >= 6 ? saleId.substring(0, 6) : saleId;

/// اسم المحل: من البروفايل، وإلا من الفاتورة، وإاسم التطبيق.
String _shopNameOf(SaleModel sale, UserProfile? profile) {
  final fromProfile = profile?.shopName.trim() ?? '';
  if (fromProfile.isNotEmpty) return fromProfile;
  final fromSale = sale.shopName.trim();
  if (fromSale.isNotEmpty) return fromSale;
  return 'appName'.tr();
}

/// عنوان المحل: (عنوان • مدينة • محافظة) وإلا العنوان الجغرافي.
String _addressOf(UserProfile? profile) {
  if (profile == null) return '';
  final parts = [
    profile.address.trim(),
    profile.city.trim(),
    profile.state.trim(),
  ].where((s) => s.isNotEmpty).toList();
  if (parts.isNotEmpty) return parts.join(' • ');
  return profile.locationAddress.trim();
}

/// هاتف المحل (هاتف المحل وإلا رقم صاحب الحساب).
String _phoneOf(UserProfile? profile) {
  if (profile == null) return '';
  final shopPhone = profile.shopPhone.trim();
  if (shopPhone.isNotEmpty) return shopPhone;
  return profile.phone.trim();
}

/// نص الفاتورة المرفق مع الصورة (كـ caption) — يشتغل لوحده لو الصورة
/// ما وصلتش في تطبيق بيخدّف الملفات.
String invoiceShareText(SaleModel sale, {UserProfile? profile}) {
  final currency = 'currencyEGP'.tr();
  final b = StringBuffer();
  b.writeln(
      'salesInvoiceNumber'.tr(namedArgs: {'id': _shortInvoiceId(sale.saleId)}));
  b.writeln(_shopNameOf(sale, profile));
  final address = _addressOf(profile);
  if (address.isNotEmpty) b.writeln(address);
  final phone = _phoneOf(profile);
  if (phone.isNotEmpty) b.writeln(phone);
  if (sale.personName.trim().isNotEmpty) {
    b.writeln('${'invoiceCustomer'.tr()}: ${sale.personName.trim()}');
  }
  b.writeln('');
  for (final it in sale.items) {
    final qty = it.quantity.toStringAsFixed(it.quantity % 1 == 0 ? 0 : 1);
    b.writeln('• ${it.productName} × $qty — '
        '${'moneyAmount'.tr(namedArgs: {'total': it.total.toStringAsFixed(2), 'currency': currency})}');
  }
  b.writeln('');
  if (sale.discount > 0) {
    b.writeln(
        '${'salesDiscount'.tr()}: ${sale.discount.toStringAsFixed(2)} $currency');
  }
  b.writeln(
      '${'saleInvoiceTotal'.tr()}: ${'moneyAmount'.tr(namedArgs: {'total': sale.total.toStringAsFixed(2), 'currency': currency})}');
  b.writeln(
      '${'salePaymentMethod'.tr()}: ${SalesListState.paymentLabel(sale.paymentMethod)}');
  return b.toString();
}

/// سؤال "إصدار فاتورة؟" الذي يظهر بعد حفظ البيع.
Future<bool> askIssueInvoice(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: AppTheme.primaryColor, size: 22),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'invoiceAskTitle'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        'invoiceAskMessage'.tr(),
        style: const TextStyle(
          fontSize: 13.5,
          height: 1.6,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, false),
          child: Text(
            'dialogCancel'.tr(),
            style: const TextStyle(
                color: Colors.grey, fontFamily: AppTheme.fontFamily),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, true),
          child: Text(
            'invoiceIssue'.tr(),
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w800,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// فتح عرض الفاتورة (صورة قابلة للإرسال).
Future<void> showInvoiceSheet(BuildContext context, SaleModel sale) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _InvoiceSheet(sale: sale),
  );
}

/// أزرار الإرسال — لتحديد أي زرار عليه تحميل لوحده.
enum _SendBtn { whatsapp, share }

class _InvoiceSheet extends StatefulWidget {
  final SaleModel sale;
  const _InvoiceSheet({required this.sale});

  @override
  State<_InvoiceSheet> createState() => _InvoiceSheetState();
}

class _InvoiceSheetState extends State<_InvoiceSheet> {
  /// حدّ الالتقاط للصورة.
  final _boundaryKey = GlobalKey();

  /// الزرار الشغّال دلوقتي (null = ولا زرار) — التحميل يظهر على زرار
  /// واحد بس والباقي معطّل لحد ما يخلص.
  _SendBtn? _busyBtn;

  /// بيانات المحل (شعار + عنوان + هاتف) — بتيجي مرة واحدة وحدة.
  UserProfile? _profile;
  final _profileReady = Completer<void>();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await sl<AccountRepo>()
          .getProfile()
          .timeout(const Duration(seconds: 6));
      if (mounted) setState(() => _profile = p);
    } catch (_) {
      // نكمّل بدون بيانات المحل (الفاتورة هتطلع باسم المحل من البيع).
    } finally {
      if (!_profileReady.isCompleted) _profileReady.complete();
    }
  }

  Future<void> _run(_SendBtn target, Future<void> Function() action) async {
    if (_busyBtn != null) return;
    HapticFeedback.mediumImpact();
    setState(() => _busyBtn = target);
    try {
      await action();
    } catch (_) {
      if (mounted) AppToast.error(context, 'errorGeneric'.tr());
    } finally {
      if (mounted) setState(() => _busyBtn = null);
    }
  }

  /// تأكد إن شعار المحل اتحمّل قبل تصوير الفاتورة.
  Future<void> _preloadLogo() async {
    if (!mounted) return;
    final url = _profile?.shopImageUrl.trim() ?? '';
    if (url.isEmpty) return;
    try {
      await precacheImage(NetworkImage(url), context)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // لو الصورة مش متاحة هتظهر أيقونة بديلة في الصورة.
    }
  }

  /// تحويل محتوى الفاتورة لصورة PNG.
  Future<Uint8List?> _capturePng() async {
    // استنى بيانات المحل (لو لسه بتيجي) — أقصى 5 ثواني.
    try {
      await _profileReady.future.timeout(const Duration(seconds: 5));
    } catch (_) {}
    if (!mounted) return null;
    await _preloadLogo();
    // استنى أول رسم بعد تحميل البيانات.
    await WidgetsBinding.instance.endOfFrame;
    final ro = _boundaryKey.currentContext?.findRenderObject();
    if (ro is! RenderRepaintBoundary) return null;
    final image = await ro.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }

  /// توليد الصورة ثم فتح قائمة المشاركة (واتساب من ضمنها).
  Future<void> _share() async {
    final bytes = await _capturePng();
    if (bytes == null) {
      if (mounted) AppToast.error(context, 'invoiceImageError'.tr());
      return;
    }
    final result = await SharePlus.instance.share(ShareParams(
      files: [
        XFile.fromData(
          bytes,
          mimeType: 'image/png',
          name: 'invoice_${_shortInvoiceId(widget.sale.saleId)}.png',
        ),
      ],
      text: invoiceShareText(widget.sale, profile: _profile),
      title: 'salesInvoiceNumber'
          .tr(namedArgs: {'id': _shortInvoiceId(widget.sale.saleId)}),
    ));
    if (result.status == ShareResultStatus.unavailable && mounted) {
      AppToast.error(context, 'invoiceShareUnavailable'.tr());
    }
  }

  /// زرار واتساب: حفظ الصورة في المعرض ثم فتح واتساب على شات العميل
  /// مباشرة والنص جاهز (الصورة تُرفق بضغطة 📎 — واتساب مش بيقبل
  /// إرفاق صورة تلقائياً عبر الرابط).
  Future<void> _shareWhatsApp() async {
    final phone = widget.sale.personPhone.trim();
    // بدون رقم عميل → قائمة المشاركة العادية (يدوّر على واتساب بنفسه).
    if (!PhoneContact.hasPhone(phone)) return _share();

    final bytes = await _capturePng();
    if (bytes == null) {
      if (mounted) AppToast.error(context, 'invoiceImageError'.tr());
      return;
    }

    // نسخة في المعرض عشان تُرفق في المحادثة بسرعة.
    try {
      await Gal.putImageBytes(
        bytes,
        name: 'invoice_${_shortInvoiceId(widget.sale.saleId)}',
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      // الحفش فشل (إذن مرفوض...) → المشاركة العادية بالصورة والنص.
      if (mounted) AppToast.warning(context, 'invoiceGalleryError'.tr());
      await _share();
      return;
    }

    if (!mounted) return;
    AppToast.success(context, 'invoiceGallerySaved'.tr());
    // وقت يكفي لقراءة التنبيه قبل الانتقال لواتساب.
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    await PhoneContact.whatsapp(
      context,
      phone,
      text: invoiceShareText(widget.sale, profile: _profile),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sheetBg = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkSurfaceAlt
        : Colors.white;

    return Container(
      constraints: BoxConstraints(maxHeight: 0.86.sh),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // مقبض السحب.
          Container(
            width: 44.w,
            height: 4.h,
            margin: EdgeInsets.only(top: 10.h, bottom: 6.h),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // الهيدر.
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 8.w, 6.h),
            child: Row(
              children: [
                Icon(Icons.receipt_long_rounded,
                    size: 20.sp, color: AppTheme.primaryColor),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'invoiceTitle'.tr(),
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppTheme.ink,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded,
                      size: 22.sp,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : AppTheme.slateGray),
                ),
              ],
            ),
          ),
          // معاينة الفاتورة (قابلة للتمرير + التصوير).
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 10.h),
              child: RepaintBoundary(
                key: _boundaryKey,
                child: KeyedSubtree(
                  key: const Key('invoice_card'),
                  child: _InvoiceCard(sale: widget.sale, profile: _profile),
                ),
              ),
            ),
          ),
          // تلميح اختيار التطبيق.
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 6.h),
            child: Text(
              'invoiceShareHint'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedGray,
              ),
            ),
          ),
          // أزرار الإرسال.
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 18.h),
            child: Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    color: const Color(0xFF25D366),
                    icon: Icons.chat_rounded,
                    label: 'invoiceWhatsApp'.tr(),
                    busy: _busyBtn == _SendBtn.whatsapp,
                    blocked:
                        _busyBtn != null && _busyBtn != _SendBtn.whatsapp,
                    onTap: () => _run(_SendBtn.whatsapp, _shareWhatsApp),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _ActionBtn(
                    color: AppTheme.primaryColor,
                    icon: Icons.share_rounded,
                    label: 'invoiceShare'.tr(),
                    busy: _busyBtn == _SendBtn.share,
                    blocked: _busyBtn != null && _busyBtn != _SendBtn.share,
                    onTap: () => _run(_SendBtn.share, _share),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// زرار إرسال ملوّن (واتساب / مشاركة).
class _ActionBtn extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  /// عليه دوّارة التحميل (الزرار اللي اتضغط عليه).
  final bool busy;

  /// معطّل من غير تحميل (لما زرار تاني شغّال).
  final bool blocked;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.color,
    required this.icon,
    required this.label,
    required this.busy,
    this.blocked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.h,
      child: ElevatedButton.icon(
        onPressed: (busy || blocked) ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        icon: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon, size: 18.sp),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
      ),
    );
  }
}

/// بطاقة الفاتورة بهيئة الفواتير المتعارف عليها — ثابتة الألوان (أبيض)
/// عشان تطلع واضحة في الصورة سواء التطبيق فاتح أو غامق.
class _InvoiceCard extends StatelessWidget {
  final SaleModel sale;
  final UserProfile? profile;
  const _InvoiceCard({required this.sale, this.profile});

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
    } catch (_) {
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
    final id = _shortInvoiceId(sale.saleId);
    final shopName = _shopNameOf(sale, profile);
    final address = _addressOf(profile);
    final phone = _phoneOf(profile);
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
