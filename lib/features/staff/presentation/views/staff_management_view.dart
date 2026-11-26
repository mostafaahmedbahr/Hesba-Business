import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/toast.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/widgets/register_widgets/password_strength_indicator.dart';
import '../../data/models/staff_model.dart';
import '../../data/repos/staff_repo.dart';
import '../cubit/staff_cubit.dart';
import 'package:hesba/core/services/app_logger.dart';

/// شاشة يستخدمها صاحب المحل فقط لإنشاء وإدارة الحسابات الفرعية.
class StaffManagementView extends StatelessWidget {
  const StaffManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StaffCubit(repo: sl<StaffRepo>()),
      child: const _StaffManagementBody(),
    );
  }
}

class _StaffManagementBody extends StatelessWidget {
  const _StaffManagementBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الحسابات الفرعية',style: TextStyle(
          color: Colors.white
        ),),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF0F2F7A), AppTheme.primaryColor, Color(0xFF4A7BFF)],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('إضافة موظف'),
      ),
      body: BlocConsumer<StaffCubit, StaffState>(
        listener: (context, state) {
          if (state.error != null && state.error!.isNotEmpty) {
            AppToast.error(context, state.error!);
          }
        },
        builder: (context, state) {
          if (state.loading) {
            return LoadingWidget(message: 'جاري تحميل الحسابات...');
          }
          if (state.staff.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(32.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.badge_outlined,
                        size: 70.sp, color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                    SizedBox(height: 16.h),
                    Text(
                      'لا توجد حسابات فرعية',
                      style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'أنشئ حسابًا لموظفك ليتمكن من تسجيل البيع والشراء والمرتجع والمصروفات فقط، بدون الاطلاع على التقارير أو الأرباح.',
                      style: TextStyle(fontSize: 13.sp, color: AppTheme.mutedGray),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
            itemCount: state.staff.length,
            itemBuilder: (context, index) =>
                _StaffCard(staff: state.staff[index]),
          );
        },
      ),
    );
  }

  Future<void> _openAddSheet(BuildContext context) async {
    final cubit = context.read<StaffCubit>();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(26.r),
          topRight: Radius.circular(26.r),
        ),
      ),
      builder: (_) => BlocProvider.value(value: cubit, child: const _AddStaffSheet()),
    );
    if (result == true && context.mounted) {
      AppToast.success(context, 'تم إنشاء الحساب الفرعي');
    }
  }
}

class _StaffCard extends StatelessWidget {
  final StaffModel staff;
  const _StaffCard({required this.staff});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppTheme.darkSurface, AppTheme.darkSurfaceAlt]
              : [Colors.white, const Color(0xFFF0F4FF)],
        ),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                  child: Icon(Icons.person_rounded, color: AppTheme.primaryColor),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(staff.name.isEmpty ? '—' : staff.name,
                          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800)),
                      SizedBox(height: 2.h),
                      Text(staff.email,
                          style: TextStyle(fontSize: 12.sp, color: AppTheme.mutedGray)),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: (staff.isActive ? AppTheme.successColor : AppTheme.danger)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    staff.isActive ? 'نشط' : 'موقوف',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: staff.isActive ? AppTheme.successDark : AppTheme.danger,
                    ),
                  ),
                ),
              ],
            ),
            if (staff.phone.isNotEmpty) ...[
              SizedBox(height: 10.h),
              Text('الهاتف: ${staff.phone}',
                  style: TextStyle(fontSize: 12.sp, color: AppTheme.mutedGray)),
            ],
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _edit(context),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('تعديل'),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await context.read<StaffCubit>().resetPassword(staff.email);
                        if (context.mounted) {
                          AppToast.success(context, 'تم إرسال رابط تغيير كلمة المرور');
                        }
                      } catch (e, logSt) {
                        AppLogger.nonFatal('features/staff/presentation/views/staff_management_view.dart', e, logSt, severity: LoggingSeverity.error);
                        if (context.mounted) {
                          AppToast.error(context, 'تعذر إرسال الرابط');
                        }
                      }
                    },
                    icon: const Icon(Icons.lock_reset_outlined, size: 16),
                    label: const Text('كلمة المرور'),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleActive(context),
                    icon: Icon(staff.isActive ? Icons.block_outlined : Icons.check_circle_outline, size: 16),
                    label: Text(staff.isActive ? 'إيقاف' : 'تفعيل'),
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final result = await showDialog<_EditStaffResult>(
      context: context,
      builder: (ctx) => _EditStaffDialog(staff: staff),
    );
    if (result == null || !context.mounted) return;
    try {
      await context.read<StaffCubit>().update(
            uid: staff.uid,
            name: result.name,
            phone: result.phone,
            isActive: staff.isActive,
          );
    } catch (logErr, logSt) { AppLogger.nonFatal('features/staff/presentation/views/staff_management_view.dart', logErr, logSt, severity: LoggingSeverity.warning); }
  }

  Future<void> _toggleActive(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(staff.isActive ? 'إيقاف الحساب؟' : 'تفعيل الحساب؟'),
        content: Text(staff.isActive
            ? 'لن يتمكن الموظف من الدخول أو تسجيل أي عملية حتى تُعيد تفعيله.'
            : 'سيتمكن الموظف من تسجيل العمليات مرة أخرى.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأكيد')),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    try {
      await context.read<StaffCubit>().update(
            uid: staff.uid,
            name: staff.name,
            phone: staff.phone,
            isActive: !staff.isActive,
          );
    } catch (logErr, logSt) { AppLogger.nonFatal('features/staff/presentation/views/staff_management_view.dart', logErr, logSt, severity: LoggingSeverity.warning); }
  }
}

/// القيم الراجعة من ديالوج تعديل بيانات الموظف بعد الحفظ.
class _EditStaffResult {
  final String name;
  final String phone;
  const _EditStaffResult({required this.name, required this.phone});
}

/// ديالوج تعديل بيانات الموظف بنفس طابع التصميم الـ premium المستخدم في الشاشة.
class _EditStaffDialog extends StatefulWidget {
  final StaffModel staff;
  const _EditStaffDialog({required this.staff});

  @override
  State<_EditStaffDialog> createState() => _EditStaffDialogState();
}

class _EditStaffDialogState extends State<_EditStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.staff.name);
    _phone = TextEditingController(text: widget.staff.phone);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _EditStaffResult(name: _name.text.trim(), phone: _phone.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26.r)),
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _field(
                      controller: _name,
                      label: 'اسم الموظف',
                      icon: Icons.person_outline,
                      isDark: isDark,
                      validator: (v) => Validators.required(v, 'اكتب اسم الموظف'),
                    ),
                    SizedBox(height: 12.h),
                    _field(
                      controller: _phone,
                      label: 'الهاتف (اختياري)',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      isDark: isDark,
                      validator: Validators.optionalEgyptianPhone,
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Expanded(child: _secondaryButton()),
                        SizedBox(width: 10.w),
                        Expanded(flex: 2, child: _primaryButton()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 14.w, 18.h),
      decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
      child: Row(
        children: [
          Container(
            width: 46.w,
            height: 46.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(Icons.edit_rounded, color: Colors.white, size: 24.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تعديل بيانات الموظف',
                  style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                ),
                SizedBox(height: 3.h),
                Text(
                  widget.staff.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11.5.sp,
                      color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, color: Colors.white, size: 20.sp),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    final accent = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: TextStyle(
        fontSize: 13.5.sp,
        fontWeight: FontWeight.w700,
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 12.5.sp,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 4.w, 12.h),
          child: Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.primarySoft,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 17.sp, color: accent),
          ),
        ),
        filled: true,
        fillColor: isDark ? AppTheme.darkSurfaceAlt : AppTheme.slatePale,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
        border: _border(isDark),
        enabledBorder: _border(isDark),
        focusedBorder: _border(isDark, color: accent, width: 1.5),
        errorBorder: _border(isDark, color: AppTheme.danger),
        focusedErrorBorder: _border(isDark, color: AppTheme.danger, width: 1.5),
      ),
    );
  }

  OutlineInputBorder _border(bool isDark, {Color? color, double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: BorderSide(
        color: color ?? (isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
        width: width,
      ),
    );
  }

  Widget _secondaryButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 48.h,
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
          side: BorderSide(
              color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
        ),
        child: Text('إلغاء',
            style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.slateDark)),
      ),
    );
  }

  Widget _primaryButton() {
    return SizedBox(
      height: 48.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _save,
            borderRadius: BorderRadius.circular(14.r),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, size: 18.sp, color: Colors.white),
                  SizedBox(width: 8.w),
                  Text('حفظ التعديلات',
                      style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddStaffSheet extends StatefulWidget {
  const _AddStaffSheet();

  @override
  State<_AddStaffSheet> createState() => _AddStaffSheetState();
}

class _AddStaffSheetState extends State<_AddStaffSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 18.w,
        right: 18.w,
        top: 18.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // مقبض السحب.
              Center(
                child: Container(
                  width: 42.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkBorder
                        : AppTheme.borderSoft,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46.w,
                      height: 46.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(Icons.person_add_alt_1_rounded,
                          color: Colors.white, size: 24.sp),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('إضافة حساب فرعي',
                              style: TextStyle(
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                          SizedBox(height: 3.h),
                          Text('بيانات الدخول للموظف الجديد',
                              style: TextStyle(
                                  fontSize: 11.5.sp,
                                  color: Colors.white.withValues(alpha: 0.85))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              _PermissionHint(),
              SizedBox(height: 18.h),
              _field(
                controller: _name,
                label: 'اسم الموظف',
                icon: Icons.person_outline,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              SizedBox(height: 12.h),
              _field(
                controller: _email,
                label: 'البريد الإلكتروني',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                // نفس سياسة التحقق المستخدمة في شاشة إنشاء الحساب.
                validator: Validators.email,
              ),
              SizedBox(height: 12.h),
              _field(
                controller: _phone,
                label: 'الهاتف',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                // نفس سياسة موبايل مصر المستخدمة في شاشة إنشاء الحساب.
                validator: Validators.egyptianPhone,
              ),
              SizedBox(height: 12.h),
              _field(
                controller: _password,
                label: 'ownerPassword'.tr(),
                icon: Icons.lock_outline,
                obscure: _obscurePassword,
                onToggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'ownerPasswordEmpty'.tr();
                  if (!PasswordStrengthIndicator.isStrong(v)) {
                    return 'ownerPasswordWeak'.tr();
                  }
                  return null;
                },
              ),
              // نفس مؤشر القوة المعروض في شاشة إنشاء الحساب.
              ListenableBuilder(
                listenable: _password,
                builder: (context, _) {
                  if (_password.text.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return PasswordStrengthIndicator(password: _password.text);
                },
              ),
              SizedBox(height: 12.h),
              _field(
                controller: _confirmPassword,
                label: 'ownerConfirmPassword'.tr(),
                icon: Icons.lock_outline,
                obscure: _obscureConfirm,
                onToggleObscure: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'ownerConfirmEmpty'.tr();
                  if (v != _password.text) return 'ownerPasswordMismatch'.tr();
                  return null;
                },
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _saving ? null : _save,
                      borderRadius: BorderRadius.circular(15.r),
                      child: Center(
                        child: _saving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person_add_alt_1_rounded,
                                      size: 18.sp, color: Colors.white),
                                  SizedBox(width: 8.w),
                                  Text('إنشاء الحساب',
                                      style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 12.5.sp,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 4.w, 12.h),
          child: Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.primarySoft,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 17.sp, color: accent),
          ),
        ),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                onPressed: onToggleObscure,
                color: accent,
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20.sp,
                ),
              )
            : null,
        filled: true,
        fillColor: isDark ? AppTheme.darkSurfaceAlt : AppTheme.slatePale,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
        border: _fieldBorder(isDark),
        enabledBorder: _fieldBorder(isDark),
        focusedBorder: _fieldBorder(isDark, color: accent, width: 1.5),
        errorBorder: _fieldBorder(isDark, color: AppTheme.danger),
        focusedErrorBorder:
            _fieldBorder(isDark, color: AppTheme.danger, width: 1.5),
      ),
    );
  }

  OutlineInputBorder _fieldBorder(bool isDark, {Color? color, double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: BorderSide(
        color: color ?? (isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
        width: width,
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<StaffCubit>().add(
            name: _name.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            password: _password.text,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e, logSt) {
      AppLogger.nonFatal('features/staff/presentation/views/staff_management_view.dart', e, logSt, severity: LoggingSeverity.error);
      if (mounted) {
        setState(() => _saving = false);
        AppToast.error(context, 'تعذر إنشاء الحساب: ${e.toString()}');
      }
    }
  }
}

/// بطاقة توضّح للمستخدم صلاحيات الحساب الفرعي بشكل بصري.
class _PermissionHint extends StatelessWidget {
  const _PermissionHint();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.mintLight : AppTheme.successDark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.09 : 0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.24 : 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined, size: 17.sp, color: accent),
              SizedBox(width: 7.w),
              Text('صلاحيات محدودة',
                  style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w900,
                      color: accent)),
            ],
          ),
          SizedBox(height: 8.h),
          _hintLine('يستطيع: بيع، شراء، مرتجع، مصروف', isDark),
          SizedBox(height: 4.h),
          _hintLine('لا يطلع على التقارير أو الأرباح أو المنتجات', isDark),
        ],
      ),
    );
  }

  Widget _hintLine(String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_rounded,
            size: 13.sp,
            color: isDark ? AppTheme.mintLight : AppTheme.successDark),
        SizedBox(width: 5.w),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 11.sp,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.textPrimary.withValues(alpha: 0.75))),
        ),
      ],
    );
  }
}
