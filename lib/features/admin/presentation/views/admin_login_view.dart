import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_auth_cubit.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_login_cubit.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';

class AdminLoginView extends StatelessWidget {
  const AdminLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminLoginCubit(repo: sl<AdminRepo>()),
      child: const _AdminLoginBody(),
    );
  }
}

class _AdminLoginBody extends StatefulWidget {
  const _AdminLoginBody();

  @override
  State<_AdminLoginBody> createState() => _AdminLoginBodyState();
}

class _AdminLoginBodyState extends State<_AdminLoginBody> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();
    context.read<AdminLoginCubit>().login(_email.text.trim(), _password.text);
  }

  void _handleState(BuildContext context, AdminLoginState state) {
    if (state is AdminLoginSuccess) {
      context.read<AdminAuthCubit>().checkSession();
    } else if (state is AdminLoginDenied) {
      _showError(context, 'هذا الحساب لا يملك صلاحية الإدارة');
    } else if (state is AdminLoginFailure) {
      _showError(context, state.message);
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.errorColor,
          margin: const EdgeInsets.all(AdminSpace.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminRadius.input),
          ),
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: AdminSpace.sm),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF3F6FC),
      body: Stack(
        children: [
          const Positioned.fill(child: _LoginBackdrop()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: BlocConsumer<AdminLoginCubit, AdminLoginState>(
                    listener: _handleState,
                    builder: (context, state) {
                      final loading = state is AdminLoginLoading;
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 760;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _LoginCard(
                                wide: wide,
                                form: _buildForm(context, loading),
                              ),
                              const SizedBox(height: AdminSpace.lg),
                              const _LoginFooter(),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool loading) {
    final secondary = AdminColors.textSecondary(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primarySoft,
              borderRadius: BorderRadius.circular(AdminRadius.chip),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_outlined, size: 13, color: AppTheme.primaryColor),
                SizedBox(width: 6),
                Text(
                  'ADMIN ACCESS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AdminSpace.md),
        Text(
          'تسجيل دخول المسؤول',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'أدخل بيانات حساب المسؤول للمتابعة إلى لوحة التحكم.',
          style: TextStyle(fontSize: 13, color: secondary, height: 1.5),
        ),
        const SizedBox(height: AdminSpace.xxl),
        Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LoginField(
                controller: _email,
                label: 'البريد الإلكتروني',
                hint: 'admin@hesba.app',
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'البريد الإلكتروني مطلوب';
                  }
                  if (!value.contains('@')) {
                    return 'أدخل بريدًا إلكترونيًا صحيحًا';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _LoginField(
                controller: _password,
                label: 'كلمة المرور',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) {
                  if (!loading) _submit();
                },
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'كلمة المرور مطلوبة' : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: AdminSpace.xl),
        _LoginButton(loading: loading, onPressed: _submit),
        const SizedBox(height: AdminSpace.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 14, color: AdminColors.textMuted(context)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'جلسة آمنة — بياناتك محمية ومشفّرة',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AdminColors.textMuted(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Card shell ───────────────────────────────────────────────

class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.wide, required this.form});

  final bool wide;
  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surface(context),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AdminColors.border(context)),
        boxShadow: AppTheme.softShadow(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: wide
          ? LayoutBuilder(
              builder: (context, constraints) {
                // Brand column takes 10/21 of the width; the gradient is painted
                // behind the whole column so its height always matches the card —
                // no IntrinsicHeight, so content can never overflow.
                final brandWidth = constraints.maxWidth * 10 / 21;
                return Stack(
                  children: [
                    PositionedDirectional(
                      top: 0,
                      bottom: 0,
                      start: 0,
                      width: brandWidth,
                      child: const _BrandBackdrop(),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          flex: 10,
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: _BrandContent(),
                          ),
                        ),
                        Expanded(
                          flex: 11,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 44),
                            child: form,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _BrandPanel(compact: true),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
                  child: form,
                ),
              ],
            ),
    );
  }
}

// ── Brand side ───────────────────────────────────────────────

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          ..._brandRings(),
          Padding(
            padding: EdgeInsets.all(compact ? 24 : 40),
            child: _BrandContent(compact: compact),
          ),
        ],
      ),
    );
  }
}

/// Gradient background alone — used behind the wide layout's brand column.
class _BrandBackdrop extends StatelessWidget {
  const _BrandBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
      clipBehavior: Clip.hardEdge,
      child: Stack(children: _brandRings()),
    );
  }
}

List<Widget> _brandRings() => [
      Positioned(
        top: -80,
        right: -70,
        child: _Ring(size: 220, color: Colors.white.withValues(alpha: 0.07)),
      ),
      Positioned(
        bottom: -90,
        left: -60,
        child: _Ring(size: 240, color: Colors.white.withValues(alpha: 0.06)),
      ),
      Positioned(
        top: 40,
        left: -110,
        child: _Ring(size: 180, color: AppTheme.secondaryColor.withValues(alpha: 0.16)),
      ),
    ];

class _BrandContent extends StatelessWidget {
  const _BrandContent({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => compact ? _buildCompact() : _buildFull();

  Widget _buildCompact() {
    return Row(
      children: [
        const _LogoBadge(size: 58),
        const SizedBox(width: AdminSpace.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Hesba',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'لوحة تحكم المنصة',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AdminRadius.chip),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 16),
        ),
      ],
    );
  }

  Widget _buildFull() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _LogoBadge(),
        SizedBox(height: 28),
        Text(
          'Hesba',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
            height: 1.05,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'لوحة تحكم المنصة',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 32),
        _FeatureLine(icon: Icons.storefront_outlined, text: 'إدارة المتاجر والمنتجات'),
        SizedBox(height: 16),
        _FeatureLine(icon: Icons.workspace_premium_outlined, text: 'متابعة الاشتراكات والطلبات'),
        SizedBox(height: 16),
        _FeatureLine(icon: Icons.insights_outlined, text: 'تقارير ومؤشرات لحظية'),
        SizedBox(height: 36),
        _SecureNote(),
      ],
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AdminRadius.tag),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: AdminSpace.md),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SecureNote extends StatelessWidget {
  const _SecureNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AdminRadius.tile),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: Colors.white, size: 18),
          const SizedBox(width: AdminSpace.sm),
          Expanded(
            child: Text(
              'وصول مقيّد لحسابات الإدارة فقط',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge({this.size = 84});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppTheme.secondaryColor.withValues(alpha: 0.35),
            blurRadius: 30,
            spreadRadius: -6,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/playstore.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.admin_panel_settings_rounded,
          size: size * 0.5,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}

// ── Form pieces ──────────────────────────────────────────────

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.validator,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enableSuggestions: !obscureText,
      autocorrect: !obscureText,
      style: TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: AdminColors.textPrimary(context),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF7F9FD),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        labelStyle: TextStyle(
          color: AdminColors.textSecondary(context),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: AdminColors.textMuted(context),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        border: _border(),
        enabledBorder: _border(),
        focusedBorder: _border(color: AppTheme.primaryColor, width: 1.6),
        errorBorder: _border(color: AppTheme.errorColor),
        focusedErrorBorder: _border(color: AppTheme.errorColor, width: 1.6),
      ),
    );
  }

  OutlineInputBorder _border({Color? color, double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AdminRadius.input),
      borderSide: BorderSide(color: color ?? Colors.grey.shade200, width: width),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: loading ? 0.75 : 1,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AdminRadius.button),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: loading ? 0.12 : 0.28),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AdminRadius.button),
          child: InkWell(
            borderRadius: BorderRadius.circular(AdminRadius.button),
            onTap: loading ? null : onPressed,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login_rounded, size: 18, color: Colors.white),
                        SizedBox(width: AdminSpace.sm),
                        Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Background ───────────────────────────────────────────────

class _LoginBackdrop extends StatelessWidget {
  const _LoginBackdrop();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -100,
            child: _Ring(size: 400, color: primary.withValues(alpha: isDark ? 0.35 : 0.16)),
          ),
          Positioned(
            bottom: -180,
            left: -120,
            child: _Ring(
              size: 420,
              color: AppTheme.secondaryColor.withValues(alpha: isDark ? 0.22 : 0.12),
            ),
          ),
          Positioned(
            top: 180,
            left: -150,
            child: _Ring(size: 300, color: primary.withValues(alpha: isDark ? 0.22 : 0.10)),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _LoginFooter extends StatelessWidget {
  const _LoginFooter();

  @override
  Widget build(BuildContext context) {
    return Text(
      '© 2026 Hesba — جميع الحقوق محفوظة',
      style: TextStyle(
        fontSize: 11.5,
        color: AdminColors.textMuted(context),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
