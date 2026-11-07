import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../../../../core/utils/error_message.dart';
import '../../../subscription/presentation/subscription_gate.dart';
import '../cubit/stock_purchase_cubit.dart';
import '../cubit/stock_purchase_state.dart';
import '../widgets/purchase_confirm_dialog.dart';
import '../widgets/purchase_header.dart';
import '../widgets/purchase_line_card.dart';

/// شاشة زيادة المخزون (فاتورة شراء متعددة الأصناف).
///
/// البيانات كلها في StockPurchaseCubit (بلا setState): أسطر الفاتورة،
/// التاريخ، إجماليات حيّة، وحالة الحفظ (حماية نقر مزدوج).
class StockPurchaseView extends StatefulWidget {
  const StockPurchaseView({super.key});

  @override
  State<StockPurchaseView> createState() => _StockPurchaseViewState();
}

class _StockPurchaseViewState extends State<StockPurchaseView> {
  final _supplierController = TextEditingController();
  final _phoneController = TextEditingController();
  final _invoiceNoController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _supplierController.dispose();
    _phoneController.dispose();
    _invoiceNoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _money(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

  /// التحقق → مراجعة الفاتورة → الحفظ. [innerContext] من داخل BlocProvider.
  Future<void> _submit(BuildContext innerContext) async {
    if (!await SubscriptionGate.ensureCanModify(innerContext)) return;
    if (!innerContext.mounted) return;

    final cubit = innerContext.read<StockPurchaseCubit>();
    final state = cubit.state;

    // تحقق مسبق برسائل واضحة قبل الدايالوج (نفس نمط شاشة البيع).
    if (state.lines.isEmpty || !state.hasSelection) {
      AppToast.warning(innerContext, 'purchaseErrEmptyLines'.tr());
      return;
    }
    for (var i = 0; i < state.lines.length; i++) {
      final errorKey = state.lines[i].validationErrorKey;
      if (errorKey != null) {
        AppToast.warning(innerContext, translateError(errorKey, {'row': '${i + 1}'}));
        return;
      }
    }

    // مراجعة إجمالي الفاتورة الكامل قبل التأكيد.
    final confirmed = await showDialog<bool>(
      context: innerContext,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => PurchaseConfirmDialog(
        itemCount: state.itemCount,
        totalAmount: state.totalAmount,
        purchaseDate: state.purchaseDate,
      ),
    );
    if (confirmed != true || !mounted) return;

    HapticFeedback.mediumImpact();
    await cubit.submit(
      supplierName: _supplierController.text.trim(),
      supplierPhone: _phoneController.text.trim(),
      invoiceNumber: _invoiceNoController.text.trim(),
      notes: _notesController.text.trim(),
    );
  }

  Future<void> _pickDate(BuildContext innerContext) async {
    final cubit = innerContext.read<StockPurchaseCubit>();
    final picked = await showDatePicker(
      context: innerContext,
      initialDate: cubit.state.purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: innerContext.locale,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.successDark),
        ),
        child: child!,
      ),
    );
    if (picked != null) cubit.setDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocProvider(
      create: (_) => StockPurchaseCubit(repo: sl(), productsRepo: sl())..reset(),
      child: BlocListener<StockPurchaseCubit, StockPurchaseState>(
        listener: (ctx, state) {
          if (state.status == StockPurchaseStatus.success) {
            HapticFeedback.mediumImpact();
            AppToast.success(ctx, 'purchaseSaved'.tr());
            Navigator.pop(ctx, true);
          }
          if (state.status == StockPurchaseStatus.error) {
            AppToast.error(ctx, translateError(state.errorMessage, state.errorArgs));
          }
        },
        child: Builder(
          builder: (innerContext) {
            final cubit = innerContext.read<StockPurchaseCubit>();
            return BlocBuilder<StockPurchaseCubit, StockPurchaseState>(
              builder: (context, state) {
                return Scaffold(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  body: SafeArea(
                    top: false,
                    child: CustomScrollView(
                      slivers: [
                        PurchaseHeader(state: state),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── بيانات الفاتورة ──
                                _SectionTitle('purchaseInvoiceInfo'.tr()),
                                SizedBox(height: 10.h),
                                Container(
                                  padding: EdgeInsets.all(14.w),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppTheme.darkSurface
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(18.r),
                                    border: Border.all(
                                      color: isDark
                                          ? AppTheme.darkBorder
                                          : AppTheme.hairline,
                                    ),
                                    boxShadow: AppTheme.cardShadow(context),
                                  ),
                                  child: Column(
                                    children: [
                                      _Field(
                                        controller: _supplierController,
                                        label: 'purchaseSupplierName'.tr(),
                                        hint: 'purchaseSupplierName'.tr(),
                                        icon: Icons.person_outline_rounded,
                                        isDark: isDark,
                                        color: AppTheme.successDark,
                                      ),
                                      SizedBox(height: 12.h),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _Field(
                                              controller: _phoneController,
                                              label: 'purchaseSupplierPhone'.tr(),
                                              hint: '01xxxxxxxxx',
                                              icon: Icons.phone_outlined,
                                              isDark: isDark,
                                              color: AppTheme.successDark,
                                              keyboardType: TextInputType.phone,
                                            ),
                                          ),
                                          SizedBox(width: 10.w),
                                          Expanded(
                                            child: _Field(
                                              controller: _invoiceNoController,
                                              label: 'purchaseInvoiceNumber'.tr(),
                                              hint: '—',
                                              icon: Icons.tag_rounded,
                                              isDark: isDark,
                                              color: AppTheme.successDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12.h),
                                      // تاريخ الشراء (يحدّث الحالة بلا setState).
                                      InkWell(
                                        onTap: () => _pickDate(innerContext),
                                        borderRadius: BorderRadius.circular(14.r),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12.w,
                                            vertical: 11.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppTheme.darkSurfaceAlt
                                                : AppTheme.slatePale,
                                            borderRadius:
                                                BorderRadius.circular(14.r),
                                            border: Border.all(
                                              color: isDark
                                                  ? AppTheme.darkBorder
                                                  : AppTheme.borderSoft,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 34.w,
                                                height: 34.w,
                                                decoration: BoxDecoration(
                                                  color: AppTheme.successDark
                                                      .withValues(alpha: 0.10),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10.r),
                                                ),
                                                child: Icon(
                                                  Icons
                                                      .calendar_today_rounded,
                                                  size: 16.sp,
                                                  color: AppTheme.successDark,
                                                ),
                                              ),
                                              SizedBox(width: 10.w),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'purchaseDateLabel'.tr(),
                                                      style: TextStyle(
                                                        fontSize: 10.5.sp,
                                                        color:
                                                            AppTheme.mutedGray,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    SizedBox(height: 2.h),
                                                    Text(
                                                      DateFormat(
                                                        'd MMMM yyyy',
                                                        context
                                                            .locale
                                                            .languageCode,
                                                      ).format(
                                                          state.purchaseDate),
                                                      style: TextStyle(
                                                        fontSize: 13.sp,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: isDark
                                                            ? Colors.white
                                                            : AppTheme.ink,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                Icons
                                                    .keyboard_arrow_down_rounded,
                                                color: AppTheme.mutedGray,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 12.h),
                                      _Field(
                                        controller: _notesController,
                                        label: 'purchaseNotesLabel'.tr(),
                                        hint: 'purchaseNotesLabel'.tr(),
                                        icon: Icons.notes_rounded,
                                        isDark: isDark,
                                        color: AppTheme.successDark,
                                        maxLines: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20.h),

                                // ── المنتجات ──
                                _SectionTitle('purchaseProductsSection'.tr()),
                                SizedBox(height: 10.h),
                                if (!state.productsLoaded)
                                  _loadingProducts(isDark)
                                else if (state.products.isEmpty)
                                  _emptyProducts(isDark)
                                else ...[
                                  for (var i = 0; i < state.lines.length; i++)
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 12.h),
                                      child: PurchaseLineCard(
                                        key: ValueKey(state.lines[i].id),
                                        index: i,
                                        line: state.lines[i],
                                        products: state.products,
                                        canDelete: state.lines.length > 1,
                                        onProductSelected: (product) =>
                                            product == null
                                                ? cubit.clearProduct(
                                                    state.lines[i].id)
                                                : cubit.selectProduct(
                                                    state.lines[i].id,
                                                    product),
                                        onQtyChanged: (text) =>
                                            cubit.updateLineText(
                                          state.lines[i].id,
                                          qtyText: text,
                                        ),
                                        onCostChanged: (text) =>
                                            cubit.updateLineText(
                                          state.lines[i].id,
                                          costText: text,
                                        ),
                                        onDelete: () => cubit
                                            .removeLine(state.lines[i].id),
                                      ),
                                    ),
                                  // إضافة سطر جديد للفاتورة.
                                  InkWell(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      cubit.addLine();
                                    },
                                    borderRadius: BorderRadius.circular(16.r),
                                    child: Container(
                                      width: double.infinity,
                                      padding:
                                          EdgeInsets.symmetric(vertical: 13.h),
                                      decoration: BoxDecoration(
                                        color: AppTheme.successDark
                                            .withValues(alpha: 0.06),
                                        borderRadius:
                                            BorderRadius.circular(16.r),
                                        border: Border.all(
                                          color: AppTheme.successDark
                                              .withValues(alpha: 0.35),
                                          style: BorderStyle.solid,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_rounded,
                                            size: 18.sp,
                                            color: AppTheme.successDark,
                                          ),
                                          SizedBox(width: 6.w),
                                          Text(
                                            'purchaseAddProduct'.tr(),
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.successDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                SizedBox(height: 110.h),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // شريط الحفظ الثابت (الإجمالي + تأكيد الفاتورة).
                  bottomNavigationBar: _bottomBar(
                    innerContext,
                    isDark,
                    state,
                    () => _submit(innerContext),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _bottomBar(
    BuildContext innerContext,
    bool isDark,
    StockPurchaseState state,
    VoidCallback onSubmit,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.hairline,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'purchaseTotalLabel'.tr(),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppTheme.mutedGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      '${_money(state.totalAmount)} ${'currencyEGP'.tr()}',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.successDark,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52.h,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.successDark, AppTheme.mintLight],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.successDark.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: FilledButton(
                    // الحماية من النقر المزدوج أثناء الحفظ.
                    onPressed: state.isSaving ? null : onSubmit,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    child: state.isSaving
                        ? SizedBox(
                            width: 22.w,
                            height: 22.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_rounded,
                                size: 19.sp,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'purchaseConfirmAction'.tr(),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingProducts(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.hairline,
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 24.w,
          height: 24.w,
          child: const CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppTheme.successDark,
          ),
        ),
      ),
    );
  }

  /// حالة عدم وجود منتجات أصلاً في المخزون.
  Widget _emptyProducts(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.hairline,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              color: AppTheme.successDark.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              size: 30.sp,
              color: AppTheme.successDark,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'purchaseEmptyProducts'.tr(),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.ink,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'purchaseEmptyProductsHint'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.mutedGray,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// عنوان سكشن صغير.
class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.w900,
        color: isDark ? Colors.white : AppTheme.ink,
      ),
    );
  }
}

/// حقل نصي موحد بلمحة خضراء (هوية شاشة الشراء).
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isDark;
  final int maxLines;
  final Color color;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.maxLines = 1,
    this.color = AppTheme.successDark,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12.sp, color: AppTheme.mutedGray),
        labelStyle: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w600),
        prefixIcon: Container(
          margin: EdgeInsets.all(8.w),
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, size: 16.sp, color: color),
        ),
        filled: true,
        fillColor: isDark ? AppTheme.darkSurfaceAlt : AppTheme.slatePale,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: color, width: 1.6),
        ),
      ),
    );
  }
}
