import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/toast.dart';
import '../../../auth/presentation/widgets/register_widgets/governorate_centers.dart';
import '../../../auth/presentation/widgets/register_widgets/register_constants.dart';
import '../../data/repos/account_repo.dart';
import '../cubit/profile_cubit.dart';
import '../states/profile_state.dart';
import '../widgets/app_scaffold.dart';

/// تعديل كل بيانات التسجيل (ما عدا الإيميل والباسورد).
class UpdateProfileView extends StatefulWidget {
  const UpdateProfileView({super.key});

  @override
  State<UpdateProfileView> createState() => _UpdateProfileViewState();
}

class _UpdateProfileViewState extends State<UpdateProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _locationController = TextEditingController();

  /// قيم ثابتة من التسجيل (التخصص والصورة مش قابلين للتعديل هنا).
  String _businessType = '';
  String _shopImageUrl = '';
  String? _governorate;
  bool _prefilled = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _shopNameController.dispose();
    _shopPhoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// يملى الخانات مرة واحدة لما البروفايل يحمل.
  void _prefill(ProfileState state) {
    final p = state.profile;
    if (p == null || _prefilled || _loading) return;
    _prefilled = true;
    _nameController.text = p.ownerName;
    _phoneController.text = p.phone;
    _shopNameController.text = p.shopName;
    _shopPhoneController.text = p.shopPhone;
    _addressController.text = p.address;
    _cityController.text = p.city;
    _locationController.text = p.locationUrl;
    _businessType = p.businessType.trim();
    _shopImageUrl = p.shopImageUrl.trim();
    final gov = p.state.trim();
    if (gov.isNotEmpty) _governorate = gov;
  }

  /// مدن المحافظة المختارة.
  List<String> get _centers =>
      _governorate == null ? [] : GovernorateData.getCenters(_governorate!);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppScaffold(
      title: 'updateProfileTitle'.tr(),
      body: BlocProvider(
        create: (_) => ProfileCubit(repo: sl<AccountRepo>())..loadProfile(),
        child: Builder(
          builder: (innerContext) => BlocListener<ProfileCubit, ProfileState>(
            listener: (context, state) {
              if (state.profile != null) {
                _prefill(state);
                setState(() {});
              }
            },
            child: BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, state) {
                if (state.status == ProfileStatus.loading && state.profile == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                    children: [
                      _SectionCard(
                        isDark: isDark,
                        icon: Icons.person_outline_rounded,
                        title: 'بياناتك',
                        gradient: const [Color(0xFF1A4FD6), Color(0xFF4A7BFF)],
                        child: Column(children: [
                          _Field(
                            isDark: isDark,
                            controller: _nameController,
                            label: 'updateProfileName'.tr(),
                            icon: Icons.person_outline_rounded,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'updateProfileNameEmpty'.tr() : null,
                          ),
                          SizedBox(height: 12.h),
                          _Field(
                            isDark: isDark,
                            controller: _phoneController,
                            label: 'updateProfilePhone'.tr(),
                            icon: Icons.phone_outlined,
                            keyboard: TextInputType.phone,
                            validator: (v) => RegisterConstants.validateEgyptianPhone(v),
                          ),
                          SizedBox(height: 12.h),
                          _ReadOnlyBox(
                            isDark: isDark,
                            icon: Icons.email_outlined,
                            label: 'profileEmail'.tr(),
                            value: state.profile?.email ?? '',
                            hint: 'يتغير من إعدادات الحساب فقط',
                          ),
                        ]),
                      ),
                      SizedBox(height: 14.h),
                      _SectionCard(
                        isDark: isDark,
                        icon: Icons.storefront_rounded,
                        title: 'بيانات المحل',
                        gradient: const [Color(0xFF059669), Color(0xFF34D399)],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Field(
                              isDark: isDark,
                              controller: _shopNameController,
                              label: 'shopName'.tr(),
                              hint: 'shopNameHint'.tr(),
                              icon: Icons.store_rounded,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'shopNameEmpty'.tr() : null,
                            ),
                            SizedBox(height: 12.h),
                            _Field(
                              isDark: isDark,
                              controller: _shopPhoneController,
                              label: 'shopPhone'.tr(),
                              hint: 'shopPhoneHint'.tr(),
                              icon: Icons.phone_android_rounded,
                              keyboard: TextInputType.phone,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                return RegisterConstants.validateEgyptianPhone(v);
                              },
                            ),
                            SizedBox(height: 12.h),
                            _Field(
                              isDark: isDark,
                              controller: _addressController,
                              label: 'shopAddress'.tr(),
                              hint: 'shopAddressHint'.tr(),
                              icon: Icons.location_on_outlined,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'shopAddressEmpty'.tr() : null,
                            ),
                            SizedBox(height: 12.h),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _governorate,
                                    decoration: _dropdownDecoration(isDark, 'shopGovernorate'.tr(), Icons.map_outlined),
                                    items: [
                                      for (final g in RegisterConstants.governorates)
                                        DropdownMenuItem(value: g, child: Text(g, style: TextStyle(fontSize: 13.sp))),
                                    ],
                                    onChanged: (v) => setState(() {
                                      _governorate = v;
                                      if (_cityController.text.isNotEmpty && !_centers.contains(_cityController.text)) {
                                        _cityController.clear();
                                      }
                                    }),
                                    validator: (v) => (v == null || v.isEmpty) ? 'shopGovernorateEmpty'.tr() : null,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: _centers.isEmpty
                                      ? _Field(
                                          isDark: isDark,
                                          controller: _cityController,
                                          label: 'shopCity'.tr(),
                                          hint: 'shopCityHint'.tr(),
                                          icon: Icons.location_city_rounded,
                                          validator: (v) => (v == null || v.trim().isEmpty) ? 'shopCityEmpty'.tr() : null,
                                        )
                                      : DropdownButtonFormField<String>(
                                          initialValue: _centers.contains(_cityController.text) ? _cityController.text : null,
                                          decoration: _dropdownDecoration(isDark, 'shopCity'.tr(), Icons.location_city_rounded),
                                          items: [
                                            for (final c in _centers)
                                              DropdownMenuItem(value: c, child: Text(c, style: TextStyle(fontSize: 13.sp), overflow: TextOverflow.ellipsis)),
                                          ],
                                          onChanged: (v) => setState(() => _cityController.text = v ?? ''),
                                          validator: (v) {
                                            final t = (v ?? _cityController.text).trim();
                                            return t.isEmpty ? 'shopCityEmpty'.tr() : null;
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),
                      _SectionCard(
                        isDark: isDark,
                        icon: Icons.map_rounded,
                        title: 'موقع المحل',
                        gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                        child: Column(children: [
                          _Field(
                            isDark: isDark,
                            controller: _locationController,
                            label: 'extraLocation'.tr(),
                            hint: 'https://maps...',
                            icon: Icons.link_rounded,
                            keyboard: TextInputType.url,
                            validator: (v) => _validateUrl(v),
                          ),
                        ]),
                      ),
                      SizedBox(height: 22.h),
                      SizedBox(
                        width: double.infinity,
                        height: 52.h,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.30), blurRadius: 16, offset: const Offset(0, 7))],
                          ),
                          child: FilledButton(
                            onPressed: _loading ? null : () => _save(innerContext),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                            ),
                            child: _loading
                                ? SizedBox(width: 22.w, height: 22.w, child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                : Text('updateProfileSave'.tr(), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// رابط اختياري — لو مكتوب لازم يبقى صحيح.
  String? _validateUrl(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    if (!t.startsWith('http://') && !t.startsWith('https://')) {
      return 'extraUrlInvalid'.tr();
    }
    return null;
  }

  InputDecoration _dropdownDecoration(bool isDark, String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w600),
      prefixIcon: Container(
        margin: EdgeInsets.all(8.w),
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10.r)),
        child: Icon(icon, size: 16.sp, color: AppTheme.primaryColor),
      ),
      filled: true,
      fillColor: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC),
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.6)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: const BorderSide(color: Color(0xFFE11D48))),
    );
  }

  /// الحفظ بـ context تحت الـ Provider.
  Future<void> _save(BuildContext ctx) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final error = await ctx.read<ProfileCubit>().updateProfile(
          ownerName: _nameController.text,
          phone: _phoneController.text,
          shopName: _shopNameController.text,
          businessType: _businessType,
          shopPhone: _shopPhoneController.text,
          address: _addressController.text,
          state: _governorate ?? '',
          city: _cityController.text,
          locationUrl: _locationController.text,
          shopImageUrl: _shopImageUrl,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error == null) {
      AppToast.success(ctx, 'updateProfileSuccess'.tr());
      Navigator.pop(ctx);
    } else {
      AppToast.error(ctx, error);
    }
  }
}

/// كارت سكشن (أيقونة gradient + عنوان).
class _SectionCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final List<Color> gradient;
  final Widget child;
  const _SectionCard({required this.isDark, required this.icon, required this.title, required this.gradient, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(gradient: LinearGradient(colors: gradient), borderRadius: BorderRadius.circular(10.r)),
              child: Icon(icon, color: Colors.white, size: 18.sp),
            ),
            SizedBox(width: 10.w),
            Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          ]),
          SizedBox(height: 14.h),
          child,
        ],
      ),
    );
  }
}

/// حقل موحد.
class _Field extends StatelessWidget {
  final bool isDark;
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType? keyboard;
  final FormFieldValidator<String>? validator;
  const _Field({
    required this.isDark,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboard,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: validator,
      style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12.sp, color: const Color(0xFF94A3B8)),
        labelStyle: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w600),
        prefixIcon: Container(
          margin: EdgeInsets.all(8.w),
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10.r)),
          child: Icon(icon, size: 16.sp, color: AppTheme.primaryColor),
        ),
        filled: true,
        fillColor: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.6)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: const BorderSide(color: Color(0xFFE11D48))),
      ),
    );
  }
}

/// خانة قراءة فقط (الإيميل).
class _ReadOnlyBox extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String value;
  final String hint;
  const _ReadOnlyBox({required this.isDark, required this.icon, required this.label, required this.value, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Row(children: [
        Icon(icon, size: 18.sp, color: const Color(0xFF94A3B8)),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
              Text(value.isEmpty ? '—' : value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569))),
              Text(hint, style: TextStyle(fontSize: 10.5.sp, color: const Color(0xFF94A3B8))),
            ],
          ),
        ),
        Icon(Icons.lock_outline_rounded, size: 15.sp, color: const Color(0xFF94A3B8)),
      ]),
    );
  }
}
