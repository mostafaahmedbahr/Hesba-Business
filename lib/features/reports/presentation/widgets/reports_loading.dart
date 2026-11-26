import 'package:hesba/core/widgets/loading_widget.dart';

import '../../../../common_imports.dart';
import 'package:easy_localization/easy_localization.dart';

/// شimmer التحميل (شبكة + كروت).
class ReportsLoadingGrid extends StatelessWidget {
  const ReportsLoadingGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoadingWidget();
  }
}

/// لودر ملء الشاشة (قبل أول داتا).
class ReportsFullLoading extends StatelessWidget {
  const ReportsFullLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return LoadingWidget(message: 'جاري تجهيز التقارير...'.tr());
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
          message ?? 'لم يتم العثور على المتجر'.tr(),
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppTheme.ink,
          ),
        ),
      ),
    );
  }
}
