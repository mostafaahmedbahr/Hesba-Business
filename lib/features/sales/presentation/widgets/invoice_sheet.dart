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
import 'invoice/action_button.dart';
import 'invoice/invoice_card.dart';
import 'invoice/invoice_helpers.dart';
import 'invoice/sheet_header.dart';
import 'package:hesba/core/services/app_logger.dart';

export 'invoice/ask_issue_invoice.dart' show askIssueInvoice;
export 'invoice/invoice_helpers.dart' show invoiceShareText;

/// ───────────────────────────────────────────────────────────────
///  إصدار فاتورة البيع كصورة (بهيئة الفواتير المتعارف عليها):
///  - شعار/صورة المحل + اسمه وعنوانه وهاتفه.
///  - رقم الفاتورة والتاريخ والعميل.
///  - جدول أصناف (الصنف / الكمية / السعر / الإجمالي) + الإجماليات.
///  - التصوير عبر [RepaintBoundary.toImage] ثم الإرسال عبر واتساب
///    أو المشاركة بأي تطبيق.
/// ───────────────────────────────────────────────────────────────

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
    } catch (logErr, logSt) {
      AppLogger.nonFatal('features/sales/presentation/widgets/invoice_sheet.dart', logErr, logSt, severity: LoggingSeverity.warning);
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
    } catch (logErr, logSt) {
      AppLogger.nonFatal('features/sales/presentation/widgets/invoice_sheet.dart', logErr, logSt, severity: LoggingSeverity.error);
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
    } catch (logErr, logSt) {
      AppLogger.nonFatal('features/sales/presentation/widgets/invoice_sheet.dart', logErr, logSt, severity: LoggingSeverity.warning);
      // لو الصورة مش متاحة هتظهر أيقونة بديلة في الصورة.
    }
  }

  /// تحويل محتوى الفاتورة لصورة PNG.
  Future<Uint8List?> _capturePng() async {
    // استنى بيانات المحل (لو لسه بتيجي) — أقصى 5 ثواني.
    try {
      await _profileReady.future.timeout(const Duration(seconds: 5));
    } catch (logErr, logSt) { AppLogger.nonFatal('features/sales/presentation/widgets/invoice_sheet.dart', logErr, logSt, severity: LoggingSeverity.warning); }
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
          name: 'invoice_${shortInvoiceId(widget.sale.saleId)}.png',
        ),
      ],
      text: invoiceShareText(widget.sale, profile: _profile),
      title: 'salesInvoiceNumber'
          .tr(namedArgs: {'id': shortInvoiceId(widget.sale.saleId)}),
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
        name: 'invoice_${shortInvoiceId(widget.sale.saleId)}',
      ).timeout(const Duration(seconds: 10));
    } catch (logErr, logSt) {
      AppLogger.nonFatal('features/sales/presentation/widgets/invoice_sheet.dart', logErr, logSt, severity: LoggingSeverity.warning);
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
          // المقبض + الهيدر.
          const InvoiceSheetHeader(),
          // معاينة الفاتورة (قابلة للتمرير + التصوير).
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 10.h),
              child: RepaintBoundary(
                key: _boundaryKey,
                child: KeyedSubtree(
                  key: const Key('invoice_card'),
                  child: InvoiceCard(sale: widget.sale, profile: _profile),
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
                  child: InvoiceActionButton(
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
                  child: InvoiceActionButton(
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
