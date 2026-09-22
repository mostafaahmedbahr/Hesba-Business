import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/toast.dart';
import '../../data/repos/category_repo.dart';
import '../cubit/category_cubit.dart';
import '../cubit/category_state.dart';

class CategoryManagementView extends StatefulWidget {
  const CategoryManagementView({super.key});
  @override
  State<CategoryManagementView> createState() => _CategoryManagementViewState();
}

class _CategoryManagementViewState extends State<CategoryManagementView> {
  final _controller = TextEditingController();
  String? _shopId;
  String? _businessType;
  bool _loadingShop = true;

  @override
  void initState() {
    super.initState();
    _loadShop();
  }

  Future<void> _loadShop() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { if (mounted) setState(() => _loadingShop = false); return; }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      _shopId = doc.data()?['shopId'] as String?;
      _businessType = doc.data()?['businessType'] as String?;
      // fallback to shops doc businessType
      if (_businessType == null && _shopId != null) {
        final shopDoc = await FirebaseFirestore.instance.collection('shops').doc(_shopId).get();
        _businessType = shopDoc.data()?['businessType'] as String?;
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingShop = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> _defaults() {
    if (_businessType != null && AppConstants.productCategoriesByBusinessType.containsKey(_businessType)) {
      return AppConstants.productCategoriesByBusinessType[_businessType]!;
    }
    return AppConstants.defaultProductCategories;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loadingShop) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('إدارة الأقسام'), centerTitle: true),
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }
    if (_shopId == null || _shopId!.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('إدارة الأقسام'), centerTitle: true),
        body: Center(child: Text('لم يتم العثور على المتجر', style: TextStyle(color: isDark ? Colors.white : Colors.black))),
      );
    }

    return BlocProvider(
      create: (_) => CategoryCubit(repo: sl<CategoryRepo>())..init(shopId: _shopId!, businessType: _businessType),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text('إدارة الأقسام', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900)),
          leading: IconButton(icon: Icon(Icons.arrow_back_rounded, size: 22.sp), onPressed: () => Navigator.pop(context)),
          bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB))),
        ),
        body: BlocConsumer<CategoryCubit, CategoryState>(
          listener: (context, state) {
            if (state.errorMessage != null) AppToast.error(context, state.errorMessage!);
            if (state.successMessage != null) AppToast.success(context, state.successMessage!);
            if (state.errorMessage != null || state.successMessage != null) {
              Future.delayed(const Duration(milliseconds: 800), () { if (context.mounted) context.read<CategoryCubit>().clearMessages(); });
            }
          },
          builder: (context, state) {
            final customs = state.customCategories;
            final defaults = _defaults();
            return ListView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
              children: [
                // هيدر المتجر
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1A4FD6), Color(0xFF4A7BFF)]),
                    borderRadius: BorderRadius.circular(18.r),
                    boxShadow: [BoxShadow(color: const Color(0xFF1A4FD6).withValues(alpha: 0.24), blurRadius: 16, offset: const Offset(0, 8))],
                  ),
                  child: Row(children: [
                    Container(width: 44.w, height: 44.w, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12.r)), child: Icon(Icons.category_rounded, color: Colors.white, size: 22.sp)),
                    SizedBox(width: 12.w),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_businessType ?? 'المتجر', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: Colors.white)),
                      SizedBox(height: 2.h),
                      Text('${defaults.length} افتراضي • ${customs.length} مخصص', style: TextStyle(fontSize: 11.sp, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600)),
                    ])),
                    Container(padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r)), child: Text('${customs.length + defaults.length} قسم', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: AppTheme.primaryColor))),
                  ]),
                ),
                SizedBox(height: 16.h),

                // إضافة قسم جديد
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(18.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 32.w, height: 32.w, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF34D399)]), borderRadius: BorderRadius.circular(10.r)), child: Icon(Icons.add_rounded, color: Colors.white, size: 18.sp)),
                      SizedBox(width: 10.w),
                      Text('إضافة قسم جديد', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    ]),
                    SizedBox(height: 12.h),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _add(context),
                          decoration: InputDecoration(
                            hintText: 'مثال: قسم جديد',
                            hintStyle: TextStyle(fontSize: 12.sp, color: const Color(0xFF94A3B8)),
                            prefixIcon: Container(margin: EdgeInsets.all(8.w), width: 36.w, height: 36.w, decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10.r)), child: Icon(Icons.category_outlined, size: 16.sp, color: AppTheme.primaryColor)),
                            filled: true,
                            fillColor: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.6)),
                            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                          ),
                          style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      SizedBox(
                        height: 48.h,
                        child: FilledButton(
                          onPressed: state.status == CategoryStatus.loading ? null : () => _add(context),
                          style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)), padding: EdgeInsets.symmetric(horizontal: 18.w)),
                          child: state.status == CategoryStatus.loading
                              ? SizedBox(width: 18.w, height: 18.w, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Row(children: [Icon(Icons.add_rounded, size: 16.sp), SizedBox(width: 6.w), Text('إضافة', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800))]),
                        ),
                      ),
                    ]),
                    SizedBox(height: 8.h),
                    Text('سيظهر القسم الجديد فوراً عند إضافة منتج للجميع في نفس المتجر، مع منع التكرار تلقائياً', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8))),
                  ]),
                ),
                SizedBox(height: 16.h),

                // الأقسام المخصصة
                _SectionCard(
                  title: 'الأقسام المخصصة',
                  count: '${customs.length}',
                  gradient: const [Color(0xFF059669), Color(0xFF34D399)],
                  child: customs.isEmpty
                      ? Container(
                          padding: EdgeInsets.symmetric(vertical: 20.h),
                          decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
                          child: Column(children: [
                            Icon(Icons.inbox_rounded, size: 28.sp, color: const Color(0xFFCBD5E1)),
                            SizedBox(height: 8.h),
                            Text('لا توجد أقسام مخصصة بعد', style: TextStyle(fontSize: 12.sp, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                            SizedBox(height: 4.h),
                            Text('أضف قسماً جديداً ليظهر في قائمة المنتج', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8))),
                          ]),
                        )
                      : Column(
                          children: customs.map((cat) => Container(
                                margin: EdgeInsets.only(bottom: 8.h),
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                                decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
                                child: Row(children: [
                                  Container(width: 36.w, height: 36.w, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF34D399)]), borderRadius: BorderRadius.circular(10.r)), child: Icon(Icons.label_rounded, color: Colors.white, size: 16.sp)),
                                  SizedBox(width: 10.w),
                                  Expanded(child: Text(cat, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)))),
                                  InkWell(
                                    onTap: () => _confirmDelete(context, cat),
                                    borderRadius: BorderRadius.circular(10.r),
                                    child: Container(width: 36.w, height: 36.w, decoration: BoxDecoration(color: const Color(0xFFE11D48).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10.r), border: Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.14))), child: Icon(Icons.delete_outline_rounded, size: 16.sp, color: const Color(0xFFE11D48))),
                                  ),
                                ]),
                              )).toList(),
                        ),
                ),
                SizedBox(height: 16.h),

                // الأقسام الافتراضية (قراءة فقط)
                _SectionCard(
                  title: 'الأقسام الافتراضية',
                  count: '${defaults.length}',
                  gradient: const [Color(0xFF64748B), Color(0xFF94A3B8)],
                  child: Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: defaults.map((cat) => Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                          decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.category_rounded, size: 12.sp, color: const Color(0xFF64748B)),
                            SizedBox(width: 6.w),
                            Text(cat, style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569))),
                          ]),
                        )).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final text = _controller.text;
    if (text.trim().isEmpty) { AppToast.error(context, 'اكتب اسم القسم'); return; }
    HapticFeedback.lightImpact();
    final ok = await context.read<CategoryCubit>().addCategory(text);
    if (ok && mounted) { _controller.clear(); HapticFeedback.mediumImpact(); }
  }

  Future<void> _confirmDelete(BuildContext context, String cat) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(22.r)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 56.w, height: 56.w, decoration: BoxDecoration(color: const Color(0xFFFEF2F2), shape: BoxShape.circle), child: Icon(Icons.delete_rounded, size: 26.sp, color: const Color(0xFFE11D48))),
            SizedBox(height: 12.h),
            Text('حذف القسم؟', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 8.h),
            Text('هل أنت متأكد من حذف "$cat"؟ لن يظهر بعد ذلك في قائمة الأقسام.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5.sp, color: const Color(0xFF64748B))),
            SizedBox(height: 18.h),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)), padding: EdgeInsets.symmetric(vertical: 12.h)), child: Text('إلغاء'))),
              SizedBox(width: 10.w),
              Expanded(child: FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE11D48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)), padding: EdgeInsets.symmetric(vertical: 12.h)), child: Text('حذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)))),
            ]),
          ]),
        ),
      ),
    );
    if (ok == true && mounted) {
      HapticFeedback.heavyImpact();
      await context.read<CategoryCubit>().removeCategory(cat);
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String count;
  final List<Color> gradient;
  final Widget child;
  const _SectionCard({required this.title, required this.count, required this.gradient, required this.child});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(18.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 32.w, height: 32.w, decoration: BoxDecoration(gradient: LinearGradient(colors: gradient), borderRadius: BorderRadius.circular(10.r)), child: Icon(Icons.category_rounded, color: Colors.white, size: 16.sp)),
          SizedBox(width: 10.w),
          Text(title, style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const Spacer(),
          Container(padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h), decoration: BoxDecoration(color: gradient.first.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: gradient.first.withValues(alpha: 0.16))), child: Text(count, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: gradient.first))),
        ]),
        SizedBox(height: 14.h),
        child,
      ]),
    );
  }
}
