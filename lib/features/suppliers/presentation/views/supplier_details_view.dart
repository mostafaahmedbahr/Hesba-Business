import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../../../../core/models/product.dart';
import '../../../../core/utils/error_message.dart';
import '../../data/models/supplier_model.dart';
import '../cubit/supplier_details_cubit.dart';
import '../states/supplier_details_state.dart';
import '../widgets/supplier_contact.dart';
import '../widgets/supplier_delete_dialog.dart';
import '../widgets/supplier_field.dart';
import 'supplier_form_view.dart';
import '../../../subscription/presentation/subscription_gate.dart';

/// شاشة تفاصيل المورد: البيانات + المنتجات المرتبطة + الملاحظات + الأزرار.
class SupplierDetailsView extends StatelessWidget {
  final String supplierId;
  const SupplierDetailsView({super.key, required this.supplierId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SupplierDetailsCubit(repo: sl())..load(supplierId),
      child: const _SupplierDetailsBody(),
    );
  }
}

class _SupplierDetailsBody extends StatelessWidget {
  const _SupplierDetailsBody();

  Future<void> _openEdit(BuildContext context) async {
    if (!await SubscriptionGate.ensureCanModify(context)) return;
    if (!context.mounted) return;
    final supplier = context.read<SupplierDetailsCubit>().state.supplier;
    if (supplier == null) return;
    final updated = await Navigator.push<SupplierModel>(
      context,
      MaterialPageRoute(builder: (_) => SupplierFormView(existing: supplier)),
    );
    if (updated != null && context.mounted) {
      await context.read<SupplierDetailsCubit>().load(supplier.id);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<SupplierDetailsCubit>();
    final supplier = cubit.state.supplier;
    if (supplier == null) return;
    if (!await SubscriptionGate.ensureCanModify(context)) return;
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => SupplierDeleteDialog(name: supplier.displayName),
    );
    if (ok != true || !context.mounted) return;

    final deleted = await cubit.delete();
    if (!context.mounted) return;
    if (deleted) {
      AppToast.success(context, 'supplierDeleted'.tr());
      Navigator.pop(context, true);
    } else {
      // عادةً: المورد مرتبط بمنتجات ولا يمكن حذفه.
      AppToast.error(context, translateError(cubit.state.errorMessage));
    }
  }

  Future<void> _saveNotes(BuildContext context, String notes) async {
    final cubit = context.read<SupplierDetailsCubit>();
    if (cubit.state.busy) return;
    if (!await SubscriptionGate.ensureCanModify(context)) return;
    if (!context.mounted) return;
    final saved = await cubit.saveNotes(notes);
    if (!context.mounted) return;
    if (saved) {
      AppToast.success(context, 'supplierNotesSaved'.tr());
    } else {
      AppToast.error(context, translateError(cubit.state.errorMessage));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SupplierDetailsCubit, SupplierDetailsState>(
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        if (state.status == SupplierDetailsStatus.loading) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: _appBar(context, null),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final supplier = state.supplier;
        if (supplier == null || state.status == SupplierDetailsStatus.failure) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: _appBar(context, null),
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(28.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 46.sp,
                      color: AppTheme.danger,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      translateError(state.errorMessage),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.sp),
                    ),
                    SizedBox(height: 16.h),
                    FilledButton.icon(
                      onPressed: () => context
                          .read<SupplierDetailsCubit>()
                          .load(supplier?.id ?? ''),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.violetDeep,
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text('suppliersRetry'.tr()),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: _appBar(context, supplier),
          body: RefreshIndicator(
            color: AppTheme.violetDeep,
            onRefresh: () =>
                context.read<SupplierDetailsCubit>().load(supplier.id),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SupplierInfoCard(supplier: supplier, isDark: isDark),
                  SizedBox(height: 14.h),
                  _LinkedProductsSection(state: state, isDark: isDark),
                  SizedBox(height: 14.h),
                  _NotesSection(
                    state: state,
                    isDark: isDark,
                    onSave: (notes) => _saveNotes(context, notes),
                  ),
                  SizedBox(height: 18.h),
                  _ActionButtons(
                    supplier: supplier,
                    isDark: isDark,
                    onEdit: () => _openEdit(context),
                    onDelete: () => _confirmDelete(context),
                    busy: state.busy,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _appBar(BuildContext context, SupplierModel? supplier) {
    return AppBar(
      backgroundColor: AppTheme.violetDeep,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      title: Text(
        'suppliersDetails'.tr(),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      actions: [
        if (supplier != null)
          IconButton(
            tooltip: 'suppliersEdit'.tr(),
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => _openEdit(context),
          ),
        if (supplier != null)
          IconButton(
            tooltip: 'supplierDelete'.tr(),
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _confirmDelete(context),
          ),
      ],
    );
  }
}

// ─────────────────────────── بيانات المورد ───────────────────────────

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);
}

class _SupplierInfoCard extends StatelessWidget {
  final SupplierModel supplier;
  final bool isDark;
  const _SupplierInfoCard({required this.supplier, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final rows = <_InfoRow>[
      _InfoRow(
        Icons.business_outlined,
        'supplierFieldLabelCompany'.tr(),
        supplier.companyName,
      ),
      _InfoRow(
        Icons.call_outlined,
        'supplierFieldLabelPhone'.tr(),
        supplier.phone,
      ),
      _InfoRow(
        Icons.phone_iphone_rounded,
        'supplierFieldLabelSecondaryPhone'.tr(),
        supplier.secondaryPhone,
      ),
      _InfoRow(
        Icons.email_outlined,
        'supplierFieldLabelEmail'.tr(),
        supplier.email,
      ),
      _InfoRow(
        Icons.location_city_outlined,
        'supplierFieldLabelCity'.tr(),
        supplier.city,
      ),
      _InfoRow(
        Icons.place_outlined,
        'supplierFieldLabelAddress'.tr(),
        supplier.address,
      ),
    ].where((r) => r.value.trim().isNotEmpty).toList();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFE8ECF3),
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.violetDeep, AppTheme.violetSoft],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.local_shipping_rounded,
                  size: 21.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppTheme.ink,
                      ),
                    ),
                    if (supplier.companyName.trim().isNotEmpty &&
                        supplier.companyName.trim() !=
                            supplier.name.trim()) ...[
                      SizedBox(height: 2.h),
                      Text(
                        supplier.companyName.trim(),
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: AppTheme.slateGray,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (rows.isNotEmpty) ...[
            SizedBox(height: 14.h),
            const Divider(height: 1),
            SizedBox(height: 6.h),
            for (final row in rows)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(row.icon, size: 15.sp, color: AppTheme.violetDeep),
                    SizedBox(width: 8.w),
                    SizedBox(
                      width: 92.w,
                      child: Text(
                        row.label,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: AppTheme.mutedGray,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value.trim(),
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          color: isDark ? Colors.white : AppTheme.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────── المنتجات المرتبطة ───────────────────────────

class _LinkedProductsSection extends StatelessWidget {
  final SupplierDetailsState state;
  final bool isDark;
  const _LinkedProductsSection({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final products = state.linkedProducts;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFE8ECF3),
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory_2_rounded,
                size: 17.sp,
                color: AppTheme.violetDeep,
              ),
              SizedBox(width: 7.w),
              Expanded(
                child: Text(
                  'supplierLinkedProducts'.tr(),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppTheme.ink,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppTheme.violetDeep.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: AppTheme.violetDeep.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  'supplierLinkedCount'.tr(args: ['${state.linkedCount}']),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.violetDeep,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (products.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.slatePale,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.hairline,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.remove_shopping_cart_outlined,
                    size: 30.sp,
                    color: AppTheme.mutedGray,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'supplierNoLinkedProducts'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppTheme.ink,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'supplierNoLinkedProductsHint'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppTheme.mutedGray,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < products.length; i++) ...[
                  if (i > 0) SizedBox(height: 8.h),
                  _LinkedProductTile(product: products[i], isDark: isDark),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _LinkedProductTile extends StatelessWidget {
  final Product product;
  final bool isDark;
  const _LinkedProductTile({required this.product, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final image = product.imageUrl.trim();
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.slatePale,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.hairline,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: image.isEmpty
                ? Icon(
                    Icons.inventory_2_rounded,
                    size: 20.sp,
                    color: AppTheme.violetSoft,
                  )
                : CachedNetworkImage(
                    imageUrl: image,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Icon(
                      Icons.inventory_2_rounded,
                      size: 20.sp,
                      color: AppTheme.violetSoft,
                    ),
                  ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.ink,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Text(
                      'supplierProductPrice'.tr(
                        args: [
                          product.price.toStringAsFixed(
                            product.price % 1 == 0 ? 0 : 2,
                          ),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.successDark,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'supplierProductStock'.tr(
                        args: [
                          product.stock.toStringAsFixed(
                            product.stock % 1 == 0 ? 0 : 2,
                          ),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.slateGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── الملاحظات ───────────────────────────

class _NotesSection extends StatefulWidget {
  final SupplierDetailsState state;
  final bool isDark;
  final ValueChanged<String> onSave;
  const _NotesSection({
    required this.state,
    required this.isDark,
    required this.onSave,
  });

  @override
  State<_NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends State<_NotesSection> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.state.supplier?.notes ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _NotesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.state.supplier?.notes ?? '';
    // نحدّث النص فقط لو المورد نفسه اتغيّر (تعديل ناجح من شاشة تانية).
    if (widget.state.supplier?.id != oldWidget.state.supplier?.id ||
        (next.isNotEmpty && next != _controller.text)) {
      _controller.text = next;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final busy = widget.state.busy;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFE8ECF3),
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notes_rounded,
                size: 17.sp,
                color: AppTheme.violetDeep,
              ),
              SizedBox(width: 7.w),
              Text(
                'supplierNotesLabel'.tr(),
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppTheme.ink,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: _controller,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            style: TextStyle(fontSize: 13.sp),
            decoration: supplierFieldDecoration(
              context,
              label: 'supplierNotesLabel'.tr(),
              hint: 'supplierNotesHint'.tr(),
              icon: Icons.notes_rounded,
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: FilledButton.icon(
              onPressed: busy ? null : () => widget.onSave(_controller.text),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.violetDeep,
                disabledBackgroundColor: AppTheme.violetDeep.withValues(
                  alpha: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              icon: busy
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 17),
              label: Text(
                'supplierNotesSave'.tr(),
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── الأزرار ───────────────────────────

class _ActionButtons extends StatelessWidget {
  final SupplierModel supplier;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool busy;

  const _ActionButtons({
    required this.supplier,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhone = SupplierContact.hasPhone(supplier.phone);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _BigAction(
                icon: Icons.call_rounded,
                label: 'supplierCall'.tr(),
                color: AppTheme.successDark,
                enabled: hasPhone,
                onTap: () => SupplierContact.call(context, supplier.phone),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _BigAction(
                icon: Icons.chat_rounded,
                label: 'supplierWhatsApp'.tr(),
                color: const Color(0xFF25D366),
                enabled: hasPhone,
                onTap: () => SupplierContact.whatsapp(context, supplier.phone),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _BigAction(
                icon: Icons.copy_rounded,
                label: 'supplierCopyPhone'.tr(),
                color: AppTheme.violetDeep,
                enabled: true,
                onTap: () => SupplierContact.copyPhone(context, supplier.phone),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _BigAction(
                icon: Icons.edit_outlined,
                label: 'suppliersEdit'.tr(),
                color: AppTheme.primaryColor,
                enabled: !busy,
                onTap: onEdit,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _BigAction(
                icon: Icons.delete_outline_rounded,
                label: 'supplierDelete'.tr(),
                color: AppTheme.danger,
                enabled: !busy,
                onTap: onDelete,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BigAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _BigAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onTap();
            }
          : null,
      borderRadius: BorderRadius.circular(12.r),
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 11.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: color.withValues(alpha: 0.16)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18.sp, color: color),
              SizedBox(height: 4.h),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
