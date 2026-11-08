import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/error_message.dart';
import '../../../../core/utils/toast.dart';
import '../../data/models/supplier_model.dart';
import '../cubit/supplier_form_cubit.dart';
import '../states/supplier_form_state.dart';
import '../widgets/supplier_field.dart';
import '../../../auth/presentation/widgets/register_widgets/register_constants.dart';
import '../../../subscription/presentation/subscription_gate.dart';

/// نموذج إضافة/تعديل مورد — نفس الشاشة للحالتين.
///
/// اللوجيك كله في [SupplierFormCubit]: التعبئة، التحقق، الحفظ،
/// والحماية من إرسال مزدوج.
class SupplierFormView extends StatelessWidget {
  final SupplierModel? existing;
  const SupplierFormView({super.key, this.existing});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = SupplierFormCubit(repo: sl());
        final supplier = existing;
        if (supplier != null) {
          cubit.initForEdit(
            name: supplier.name,
            phone: supplier.phone,
            companyName: supplier.companyName,
            secondaryPhone: supplier.secondaryPhone,
            email: supplier.email,
            address: supplier.address,
            city: supplier.city,
            notes: supplier.notes,
          );
        }
        return cubit;
      },
      child: _SupplierFormBody(existing: existing),
    );
  }
}

class _SupplierFormBody extends StatelessWidget {
  final SupplierModel? existing;
  const _SupplierFormBody({this.existing});

  bool get _isEdit => existing != null;

  Future<void> _save(BuildContext context) async {
    // حارس الإرسال المزدوج موجود في الـ Cubit كمان (طبقة ثانية).
    if (!await SubscriptionGate.ensureCanModify(context)) return;
    if (!context.mounted) return;
    final cubit = context.read<SupplierFormCubit>();
    if (cubit.state.isSaving) return;
    final saved = await cubit.submit(supplierId: existing?.id);
    if (saved == null || !context.mounted) return;
    HapticFeedback.mediumImpact();
    // يرجع المورد المحفوظ (لإختياره تلقائياً من فورم المنتج).
    Navigator.pop(context, saved);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocConsumer<SupplierFormCubit, SupplierFormState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == SupplierFormStatus.failure &&
            state.errorMessage != null) {
          AppToast.error(context, translateError(state.errorMessage));
        }
      },
      builder: (context, state) {
        final cubit = context.read<SupplierFormCubit>();
        final nameError = state.nameError != null
            ? translateError(state.nameError)
            : null;
        final phoneError = state.phoneError != null
            ? translateError(state.phoneError)
            : null;
        final secondaryPhoneError = state.secondaryPhoneError != null
            ? translateError(state.secondaryPhoneError)
            : null;
        final emailError = state.emailError != null
            ? translateError(state.emailError)
            : null;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: AppTheme.violetDeep,
            foregroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            title: Text(
              _isEdit ? 'suppliersEdit'.tr() : 'suppliersAdd'.tr(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 24.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionLabel(
                          title: 'supplierFormSectionMain'.tr(),
                          isDark: isDark,
                        ),
                        SizedBox(height: 10.h),
                        SupplierField(
                          labelKey: 'supplierFieldLabelName',
                          hintKey: 'supplierFieldHintName',
                          icon: Icons.badge_outlined,
                          required: true,
                          autofocus: !_isEdit,
                          initialValue: state.name,
                          textInputAction: TextInputAction.next,
                          hasError: nameError != null,
                          onChanged: cubit.onNameChanged,
                        ),
                        if (nameError != null) ...[
                          SizedBox(height: 6.h),
                          _FieldError(message: nameError),
                        ],
                        SizedBox(height: 14.h),
                        SupplierField(
                          labelKey: 'supplierFieldLabelPhone',
                          hintKey: 'supplierFieldHintPhone',
                          icon: Icons.call_outlined,
                          required: true,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9٠-٩+ ()\-]'),
                            ),
                          ],
                          initialValue: state.phone,
                          hasError: phoneError != null,
                          onChanged: cubit.onPhoneChanged,
                        ),
                        if (phoneError != null) ...[
                          SizedBox(height: 6.h),
                          _FieldError(message: phoneError),
                        ],
                        SizedBox(height: 14.h),
                        SupplierField(
                          labelKey: 'supplierFieldLabelCompany',
                          hintKey: 'supplierFieldHintCompany',
                          icon: Icons.business_outlined,
                          textInputAction: TextInputAction.next,
                          initialValue: state.companyName,
                          onChanged: cubit.onCompanyNameChanged,
                        ),
                        SizedBox(height: 14.h),
                        SupplierField(
                          labelKey: 'supplierFieldLabelSecondaryPhone',
                          hintKey: 'supplierFieldHintSecondaryPhone',
                          icon: Icons.phone_iphone_rounded,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9٠-٩+ ()\-]'),
                            ),
                          ],
                          initialValue: state.secondaryPhone,
                          hasError: secondaryPhoneError != null,
                          onChanged: cubit.onSecondaryPhoneChanged,
                        ),
                        if (secondaryPhoneError != null) ...[
                          SizedBox(height: 6.h),
                          _FieldError(message: secondaryPhoneError),
                        ],
                        SizedBox(height: 14.h),
                        SupplierField(
                          labelKey: 'supplierFieldLabelEmail',
                          hintKey: 'supplierFieldHintEmail',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          initialValue: state.email,
                          hasError: emailError != null,
                          onChanged: cubit.onEmailChanged,
                        ),
                        if (emailError != null) ...[
                          SizedBox(height: 6.h),
                          _FieldError(message: emailError),
                        ],
                        SizedBox(height: 14.h),
                        // المدينة: قائمة منسدلة (المحافظات) بدل الكتابة اليدوية.
                        _CityDropdown(
                          currentValue: state.city,
                          onChanged: cubit.onCityChanged,
                        ),
                        SizedBox(height: 14.h),
                        SupplierField(
                          labelKey: 'supplierFieldLabelAddress',
                          hintKey: 'supplierFieldHintAddress',
                          icon: Icons.place_outlined,
                          textInputAction: TextInputAction.next,
                          initialValue: state.address,
                          onChanged: cubit.onAddressChanged,
                        ),
                        SizedBox(height: 14.h),
                        SupplierField(
                          labelKey: 'supplierFieldLabelNotes',
                          hintKey: 'supplierFieldHintNotes',
                          icon: Icons.notes_rounded,
                          maxLines: 4,
                          textInputAction: TextInputAction.newline,
                          initialValue: state.notes,
                          onChanged: cubit.onNotesChanged,
                        ),
                      ],
                    ),
                  ),
                ),
                // شريط الحفظ الثابت.
                Container(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? AppTheme.darkBorder : AppTheme.hairline,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: FilledButton.icon(
                      onPressed: state.isSaving ? null : () => _save(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.violetDeep,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme.violetDeep.withValues(
                          alpha: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      icon: state.isSaving
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _isEdit ? Icons.save_rounded : Icons.add_rounded,
                              size: 18,
                            ),
                      label: Text(
                        state.isSaving
                            ? 'suppliersSaving'.tr()
                            : (_isEdit
                                  ? 'suppliersSaveChanges'.tr()
                                  : 'suppliersAdd'.tr()),
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// عنوان قسم داخل الفورم.
class _SectionLabel extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionLabel({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 16.h,
          decoration: BoxDecoration(
            color: AppTheme.violetDeep,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppTheme.ink,
          ),
        ),
      ],
    );
  }
}

/// رسالة خطأ تحت الحقل.
/// قائمة منسدلة بالمدينة (المحافظات المصرية) — تمنع الأخطاء الإملائية
/// وتوحد تنسيق البحث والفلترة. القيمة الحالية تُدرج دائمًا حتى لو لم
/// تكن ضمن القائمة (حفاظًا على بيانات قديمة مكتوبة يدويًا).
class _CityDropdown extends StatelessWidget {
  final String currentValue;
  final ValueChanged<String> onChanged;

  const _CityDropdown({required this.currentValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = currentValue.trim();
    final items = <String>{
      ...RegisterConstants.governorates,
      if (current.isNotEmpty) current,
    }.toList();
    return DropdownButtonFormField<String>(
      initialValue: current.isEmpty ? null : current,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      borderRadius: BorderRadius.circular(14.r),
      dropdownColor: isDark ? AppTheme.darkSurfaceAlt : Colors.white,
      elevation: 4,
      decoration: supplierFieldDecoration(
        context,
        label: 'supplierFieldLabelCity'.tr(),
        hint: 'supplierFieldHintCity'.tr(),
        icon: Icons.location_city_outlined,
      ),
      items: [
        for (final city in items)
          DropdownMenuItem(
            value: city,
            child: Text(city, style: TextStyle(fontSize: 13.sp)),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _FieldError extends StatelessWidget {
  final String message;
  const _FieldError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.error_outline_rounded, size: 14.sp, color: AppTheme.danger),
        SizedBox(width: 5.w),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.danger,
            ),
          ),
        ),
      ],
    );
  }
}
