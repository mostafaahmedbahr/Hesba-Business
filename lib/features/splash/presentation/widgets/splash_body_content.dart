import 'package:hesba/features/splash/presentation/widgets/splash_brand.dart';
import 'package:hesba/features/splash/presentation/widgets/splash_footer.dart';
import 'package:hesba/features/splash/presentation/widgets/splash_loader.dart';
import 'package:hesba/features/splash/presentation/widgets/splash_logo.dart';
import '../../../../common_imports.dart';
import 'feature_chips.dart';

class SplashBodyContent extends StatelessWidget {
  const SplashBodyContent({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return  SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 18.h),
        child: Column(
          children: [
            const Spacer(flex: 2),
            const SplashLogo()
                .animate()
                .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                .scale(
                begin: const Offset(.7, .7),
                end: const Offset(1, 1),
                duration: 850.ms,
                curve: Curves.easeOutBack)
                .slideY(begin: .12, end: 0, duration: 850.ms),
            SizedBox(height: 26.h),
            const SplashBrand()
                .animate()
                .fadeIn(delay: 250.ms, duration: 650.ms)
                .slideY(begin: .22, end: 0, delay: 250.ms, duration: 650.ms, curve: Curves.easeOutCubic),
            SizedBox(height: 30.h),
            // Feature chips row — modern value props
            FeatureChips(isDark: isDark)
                .animate()
                .fadeIn(delay: 500.ms, duration: 550.ms)
                .slideY(begin: .15, end: 0, delay: 500.ms, duration: 550.ms),
            SizedBox(height: 26.h),
            const SplashLoader()
                .animate()
                .fadeIn(delay: 650.ms, duration: 500.ms),
            const Spacer(flex: 3),
            const SplashFooter()
                .animate()
                .fadeIn(delay: 900.ms, duration: 500.ms),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}
