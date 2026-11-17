import 'dart:async';
import 'package:hesba/features/profile/data/repos/account_repo.dart';
import 'package:hesba/core/services/user_role_service.dart';
import '../../../../common_imports.dart';
import '../widgets/splash_background.dart';
import '../widgets/splash_body_content.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  Timer? _timer;

  /// true لو تعذر تحميل دور المستخدم (فشل القراءة) — ممنوع التوجيه كمالك.
  bool _roleFailed = false;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _startSplash();
  }

  void _startSplash() {
    _timer = Timer(const Duration(seconds: 3), _navigateNext);
  }

  Future<void> _navigateNext() async {
    final isLoggedIn = sl<AccountRepo>().currentUserId() != null;
    if (!isLoggedIn) {
      sl<UserRoleService>().clear();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    await sl<UserRoleService>().reload();
    if (!mounted) return;
    final role = sl<UserRoleService>();
    if (!role.isLoaded && role.loadFailed) {
      // فشل قراءة مستند users/{uid}: لا نوجّه للواجهة الكاملة (قد يكون موظفًا).
      // نعرض شاشة إعادة محاولة بدل افتراض "مالك".
      setState(() => _roleFailed = true);
      return;
    }
    final isStaff = role.isStaff;
    logSuccess('[Splash] isLoggedIn: $isLoggedIn, isStaff: $isStaff');
    Navigator.pushReplacementNamed(
      context,
      isStaff ? AppRoutes.staffHome : AppRoutes.dashboard,
    );
  }

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() {
      _retrying = true;
      _roleFailed = false;
    });
    await _navigateNext();
    if (mounted) setState(() => _retrying = false);
  }

  Future<void> _logout() async {
    try {
      await sl<AccountRepo>().logout();
    } catch (_) {}
    sl<UserRoleService>().clear();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A1A45) : const Color(0xFFF6F7FB),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const SplashBackground(),
          if (_roleFailed)
            _RoleLoadErrorView(
              retrying: _retrying,
              onRetry: _retry,
              onLogout: _logout,
            )
          else
            const SplashBodyContent(),
        ],
      ),
    );
  }
}

/// شاشة "تعذر تحميل بيانات الحساب" — تظهر عند فشل قراءة الدور بدل
/// التوجيه الخاطئ لحساب موظف على أنه مالك.
class _RoleLoadErrorView extends StatelessWidget {
  const _RoleLoadErrorView({
    required this.retrying,
    required this.onRetry,
    required this.onLogout,
  });

  final bool retrying;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? Colors.white70 : const Color(0xFF475569);
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 56, color: isDark ? Colors.white : const Color(0xFF0A1A45)),
              const SizedBox(height: 16),
              Text(
                'تعذر تحميل بيانات حسابك',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0A1A45),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'تأكد من اتصالك بالإنترنت وحاول مرة أخرى. لو استمرت المشكلة سجّل الخروج وادخل تاني.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.6, color: secondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: retrying ? null : onRetry,
                  child: retrying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('إعادة المحاولة'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: onLogout,
                child: const Text('تسجيل الخروج'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
