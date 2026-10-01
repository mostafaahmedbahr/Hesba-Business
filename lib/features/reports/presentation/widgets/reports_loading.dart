import 'package:hesba/core/widgets/loading_widget.dart';

import '../../../../common_imports.dart';

/// شimmer التحميل (شبكة + كروت).
class ReportsLoadingGrid extends StatelessWidget {
  const ReportsLoadingGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      Row(children: [Expanded(child: _box(90.h, isDark)), SizedBox(width: 10.w), Expanded(child: _box(90.h, isDark))]),
      SizedBox(height: 10.h),
      Row(children: [Expanded(child: _box(90.h, isDark)), SizedBox(width: 10.w), Expanded(child: _box(90.h, isDark))]),
      SizedBox(height: 14.h),
      _box(120.h, isDark),
      SizedBox(height: 14.h),
      _box(180.h, isDark),
    ]);
  }

  /// مربع لامع واحد.
  Widget _box(double h, bool isDark) => Container(
        height: h,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18.r),
        ),
      );
}

/// لودر ملء الشاشة (قبل أول داتا).
class ReportsFullLoading extends StatelessWidget {
  const ReportsFullLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoadingWidget(message: 'جاري تجهيز التقارير...');
  }
}

/// مفيش محل مربوط.
class ReportsNoShop extends StatelessWidget {
  final String? message;
  const ReportsNoShop({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Text(
          message ?? 'لم يتم العثور على المتجر',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }
}
