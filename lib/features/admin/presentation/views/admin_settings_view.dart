import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/core/utils/toast.dart';
import 'package:hesba/core/models/admin_settings.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_settings_cubit.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';

class AdminSettingsView extends StatelessWidget {
  const AdminSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminSettingsCubit(repo: sl<AdminRepo>())..load(),
      child: BlocConsumer<AdminSettingsCubit, AdminSettingsState>(
        listener: (context, state) {
          if (state is SettingsSaved) {
            AppToast.success(context, 'تم حفظ الإعدادات وتحديثها للعملاء');
          } else if (state is SettingsSaveFailed) {
            AppToast.error(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is SettingsLoading) {
            return adminSkeletonList(context, count: 4);
          }
          if (state is SettingsError) {
            return adminError(
              state.message,
              () => context.read<AdminSettingsCubit>().load(),
            );
          }
          final settings = switch (state) {
            SettingsLoaded(:final settings) => settings,
            SettingsSaved(:final settings) => settings,
            SettingsSaving(:final settings) => settings,
            SettingsSaveFailed(:final settings) => settings,
            _ => AdminSettings.defaults,
          };
          return _SettingsForm(
            settings: settings,
            saving: state is SettingsSaving,
          );
        },
      ),
    );
  }
}

// ── Form ─────────────────────────────────────────────────────

class _SettingsForm extends StatefulWidget {
  const _SettingsForm({required this.settings, required this.saving});

  final AdminSettings settings;
  final bool saving;

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  late final TextEditingController _monthly;
  late final TextEditingController _three;
  late final TextEditingController _six;
  late final TextEditingController _yearly;
  late final TextEditingController _trial;
  late final List<TextEditingController> _numbers;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _monthly = TextEditingController(text: '${s.monthlyPrice}');
    _three = TextEditingController(text: '${s.threeMonthsPrice}');
    _six = TextEditingController(text: '${s.sixMonthsPrice}');
    _yearly = TextEditingController(text: '${s.yearlyPrice}');
    _trial = TextEditingController(text: '${s.trialDays}');
    _numbers = [
      for (final m in s.paymentMethods) TextEditingController(text: m.number),
    ];
    for (final c in _controllers) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.removeListener(_onChanged);
      c.dispose();
    }
    super.dispose();
  }

  List<TextEditingController> get _controllers =>
      [_monthly, _three, _six, _yearly, _trial, ..._numbers];

  void _onChanged() {
    if (mounted) setState(() {});
  }

  int? _valueOf(TextEditingController c) => int.tryParse(c.text.trim());

  bool get _isDirty {
    final s = widget.settings;
    if (_valueOf(_monthly) != s.monthlyPrice) return true;
    if (_valueOf(_three) != s.threeMonthsPrice) return true;
    if (_valueOf(_six) != s.sixMonthsPrice) return true;
    if (_valueOf(_yearly) != s.yearlyPrice) return true;
    if (_valueOf(_trial) != s.trialDays) return true;
    for (var i = 0; i < s.paymentMethods.length; i++) {
      final current = i < _numbers.length ? _numbers[i].text.trim() : '';
      if (current != s.paymentMethods[i].number) return true;
    }
    return false;
  }

  void _save(BuildContext formContext) {
    FocusScope.of(context).unfocus();
    if (!(Form.maybeOf(formContext)?.validate() ?? false)) return;

    final s = widget.settings;
    final updated = s.copyWith(
      monthlyPrice: _valueOf(_monthly) ?? s.monthlyPrice,
      threeMonthsPrice: _valueOf(_three) ?? s.threeMonthsPrice,
      sixMonthsPrice: _valueOf(_six) ?? s.sixMonthsPrice,
      yearlyPrice: _valueOf(_yearly) ?? s.yearlyPrice,
      trialDays: _valueOf(_trial) ?? s.trialDays,
      paymentMethods: [
        for (var i = 0; i < s.paymentMethods.length; i++)
          AdminPaymentMethod(
            id: s.paymentMethods[i].id,
            label: s.paymentMethods[i].label,
            number: i < _numbers.length
                ? _numbers[i].text.trim()
                : s.paymentMethods[i].number,
          ),
      ],
    );
    context.read<AdminSettingsCubit>().save(updated);
  }

  void _discardChanges() {
    FocusScope.of(context).unfocus();
    final s = widget.settings;
    setState(() {
      _monthly.text = '${s.monthlyPrice}';
      _three.text = '${s.threeMonthsPrice}';
      _six.text = '${s.sixMonthsPrice}';
      _yearly.text = '${s.yearlyPrice}';
      _trial.text = '${s.trialDays}';
      for (var i = 0; i < _numbers.length && i < s.paymentMethods.length; i++) {
        _numbers[i].text = s.paymentMethods[i].number;
      }
    });
  }

  Future<void> _restoreDefaults() async {
    FocusScope.of(context).unfocus();
    final ok = await showAdminConfirm(
      context,
      title: 'استعادة الإعدادات الافتراضية',
      message:
          'هيتم استبدال الأسعار والفترة التجريبية وأرقام الدفع بالقيم الافتراضية. '
          'التغييرات مش هتتحفظ غير لما تضغط "حفظ الإعدادات".',
      confirmLabel: 'استعادة',
      danger: true,
    );
    if (!ok || !mounted) return;

    final d = AdminSettings.defaults;
    setState(() {
      _monthly.text = '${d.monthlyPrice}';
      _three.text = '${d.threeMonthsPrice}';
      _six.text = '${d.sixMonthsPrice}';
      _yearly.text = '${d.yearlyPrice}';
      _trial.text = '${d.trialDays}';
      for (var i = 0; i < _numbers.length; i++) {
        final ids = widget.settings.paymentMethods;
        if (i >= ids.length) break;
        final id = ids[i].id;
        final match = d.paymentMethods.where((m) => m.id == id);
        if (match.isNotEmpty) _numbers[i].text = match.first.number;
      }
    });
  }

  void _setTrialDays(int days) {
    FocusScope.of(context).unfocus();
    final value = '$days';
    _trial.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final monthly = _valueOf(_monthly) ?? 0;
    final plans = <_PlanSpec>[
      _PlanSpec(
        id: 'monthly',
        title: 'الباقة الشهرية',
        subtitle: 'الأساس — دفع كل شهر',
        controller: _monthly,
        months: 1,
        icon: Icons.calendar_view_month_rounded,
        color: AppTheme.primaryColor,
      ),
      _PlanSpec(
        id: 'threeMonths',
        title: 'باقة 3 شهور',
        subtitle: 'مناسبة للمحلات الموسمية',
        controller: _three,
        months: 3,
        icon: Icons.date_range_rounded,
        color: AppTheme.blueBright,
      ),
      _PlanSpec(
        id: 'sixMonths',
        title: 'باقة 6 شهور',
        subtitle: 'توفير أكبر لمدة أطول',
        controller: _six,
        months: 6,
        icon: Icons.calendar_month_rounded,
        color: AppTheme.violetDeep,
      ),
      _PlanSpec(
        id: 'yearly',
        title: 'الباقة السنوية',
        subtitle: 'أفضل قيمة على المدى الطويل',
        controller: _yearly,
        months: 12,
        icon: Icons.workspace_premium_rounded,
        color: AppTheme.secondaryDark,
      ),
    ];

    double savingOf(_PlanSpec p) {
      if (p.months == 1) return 0;
      final total = _valueOf(p.controller) ?? 0;
      final fullPrice = monthly * p.months;
      if (total <= 0 || fullPrice <= 0) return 0;
      final pct = (1 - total / fullPrice) * 100;
      return pct > 0 ? pct : 0;
    }

    final paidPlans = plans.where((p) => p.months > 1).toList();
    final bestPlan = paidPlans.reduce(
      (a, b) => savingOf(b) > savingOf(a) ? b : a,
    );

    final pricing = _SettingsSection(
      title: 'أسعار الباقات',
      subtitle: 'الأسعار اللي بتظهر للعميل عند تجديد الاشتراك — بالجنيه المصري',
      icon: Icons.sell_outlined,
      color: AppTheme.primaryColor,
      trailing: _SectionTag(
        label: '${plans.length} باقات',
        color: AppTheme.primaryColor,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoColumns = constraints.maxWidth >= 600;
          const spacing = AdminSpace.md;
          final width = twoColumns
              ? (constraints.maxWidth - spacing) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final plan in plans)
                SizedBox(
                  width: width,
                  child: _PlanCard(
                    spec: plan,
                    saving: savingOf(plan),
                    isBest:
                        bestPlan.months > 1 && plan.id == bestPlan.id && savingOf(plan) > 0,
                    enabled: !widget.saving,
                  ),
                ),
            ],
          );
        },
      ),
    );

    final trial = _TrialSection(
      controller: _trial,
      days: _valueOf(_trial) ?? 0,
      enabled: !widget.saving,
      onPreset: _setTrialDays,
    );

    final payments = _SettingsSection(
      title: 'طرق الدفع',
      subtitle: 'الأرقام اللي بيحوّل عليها العميل عند تجديد الاشتراك',
      icon: Icons.account_balance_wallet_outlined,
      color: AppTheme.successColor,
      trailing: _SectionTag(
        label: '${widget.settings.paymentMethods.length} طرق',
        color: AppTheme.successColor,
      ),
      child: Column(
        children: [
          for (var i = 0; i < widget.settings.paymentMethods.length; i++) ...[
            if (i > 0) const SizedBox(height: AdminSpace.sm),
            _PaymentMethodCard(
              method: widget.settings.paymentMethods[i],
              controller: _numbers[i],
              enabled: !widget.saving,
            ),
          ],
        ],
      ),
    );

    final summary = _PricingSummary(
      plans: plans,
      savingOf: savingOf,
      trialDays: _valueOf(_trial) ?? 0,
      methods: widget.settings.paymentMethods.length,
    );

    return Form(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AdminSpace.md,
                AdminSpace.md,
                AdminSpace.md,
                AdminSpace.lg,
              ),
              children: [
                _SettingsHero(
                  monthlyPrice: monthly,
                  trialDays: _valueOf(_trial) ?? 0,
                  methods: widget.settings.paymentMethods.length,
                  dirty: _isDirty,
                  saving: widget.saving,
                ),
                const SizedBox(height: AdminSpace.lg),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 1000;
                    if (!wide) {
                      return Column(
                        children: [
                          pricing,
                          const SizedBox(height: AdminSpace.md),
                          trial,
                          const SizedBox(height: AdminSpace.md),
                          payments,
                          const SizedBox(height: AdminSpace.md),
                          summary,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              pricing,
                              const SizedBox(height: AdminSpace.md),
                              payments,
                            ],
                          ),
                        ),
                        const SizedBox(width: AdminSpace.md),
                        SizedBox(
                          width: 340,
                          child: Column(
                            children: [
                              trial,
                              const SizedBox(height: AdminSpace.md),
                              summary,
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AdminSpace.lg),
                _RestoreDefaultsButton(
                  enabled: !widget.saving,
                  onTap: _restoreDefaults,
                ),
              ],
            ),
          ),
          // Builder gives us a context inside the Form, so we can validate the
          // real fields without a GlobalKey (which can go stale on hot reload).
          Builder(
            builder: (formContext) => _SaveBar(
              dirty: _isDirty,
              saving: widget.saving,
              onSave: () => _save(formContext),
              onDiscard: _discardChanges,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero ─────────────────────────────────────────────────────

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({
    required this.monthlyPrice,
    required this.trialDays,
    required this.methods,
    required this.dirty,
    required this.saving,
  });

  final int monthlyPrice;
  final int trialDays;
  final int methods;
  final bool dirty;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AdminSpace.lg),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AdminRadius.header),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AdminRadius.tile),
                ),
                child: const Icon(Icons.tune_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: AdminSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إعدادات المنصة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'أسعار الباقات، الفترة التجريبية، وأرقام الدفع — كلها في مكان واحد وبتظهر للعملاء فور الحفظ.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminSpace.lg),
          Wrap(
            spacing: AdminSpace.sm,
            runSpacing: AdminSpace.sm,
            children: [
              _HeroStatus(dirty: dirty, saving: saving),
              _HeroChip(
                icon: Icons.payments_outlined,
                label: monthlyPrice > 0
                    ? '${AdminFmt.money(monthlyPrice)} / شهر'
                    : 'حدد سعر الشهر',
              ),
              _HeroChip(
                icon: Icons.hourglass_bottom_rounded,
                label: trialDays > 0 ? '$trialDays يوم تجربة' : 'بدون فترة تجريبية',
              ),
              _HeroChip(
                icon: Icons.account_balance_wallet_outlined,
                label: '$methods طرق دفع',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatus extends StatelessWidget {
  const _HeroStatus({required this.dirty, required this.saving});

  final bool dirty;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final color = saving
        ? Colors.white
        : dirty
            ? const Color(0xFFFFD54F)
            : const Color(0xFF6EE7B7);
    final icon = saving
        ? Icons.sync_rounded
        : dirty
            ? Icons.edit_note_rounded
            : Icons.check_circle_outline_rounded;
    final label = saving
        ? 'جاري الحفظ'
        : dirty
            ? 'غير محفوظ'
            : 'محفوظ';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AdminRadius.chip),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AdminRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section shell ────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminIconTile(icon: icon, color: color, size: 40),
              const SizedBox(width: AdminSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        color: AdminColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AdminSpace.sm),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: AdminSpace.lg),
          child,
        ],
      ),
    );
  }
}

class _SectionTag extends StatelessWidget {
  const _SectionTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AdminRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ── Pricing ──────────────────────────────────────────────────

class _PlanSpec {
  const _PlanSpec({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.months,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String subtitle;
  final TextEditingController controller;
  final int months;
  final IconData icon;
  final Color color;
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.spec,
    required this.saving,
    required this.isBest,
    required this.enabled,
  });

  final _PlanSpec spec;
  final double saving;
  final bool isBest;
  final bool enabled;

  int get _total => int.tryParse(spec.controller.text.trim()) ?? 0;

  double get _perMonth => spec.months <= 0 ? 0 : _total / spec.months;

  @override
  Widget build(BuildContext context) {
    final border = isBest
        ? spec.color.withValues(alpha: 0.45)
        : AdminColors.border(context);

    return Container(
      padding: const EdgeInsets.all(AdminSpace.md),
      decoration: BoxDecoration(
        color: AdminColors.surface(context),
        borderRadius: BorderRadius.circular(AdminRadius.card),
        border: Border.all(color: border, width: isBest ? 1.4 : 1),
        boxShadow: isBest ? AppTheme.cardShadow(context) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminIconTile(icon: spec.icon, color: spec.color, size: 36, iconSize: 18),
              const SizedBox(width: AdminSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      spec.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: AdminColors.textMuted(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isBest) ...[
                const SizedBox(width: 4),
                _SectionTag(label: 'الأكثر توفيرًا', color: spec.color),
              ],
            ],
          ),
          const SizedBox(height: AdminSpace.md),
          TextFormField(
            controller: spec.controller,
            enabled: enabled,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            decoration: _priceDecoration(context, spec.color, suffixText: 'ج.م'),
            validator: (v) {
              final n = int.tryParse((v ?? '').trim());
              if (n == null || n <= 0) return 'اكتب سعرًا صحيحًا';
              return null;
            },
          ),
          const SizedBox(height: AdminSpace.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  spec.months == 1
                      ? 'سعر الاشتراك الأساسي'
                      : '≈ ${AdminFmt.money(_perMonth.round())} / شهر',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.textSecondary(context),
                  ),
                ),
              ),
              if (spec.months > 1 && saving > 0)
                _SectionTag(
                  label: 'توفير ${saving.round()}%',
                  color: AppTheme.successColor,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

InputDecoration _priceDecoration(
  BuildContext context,
  Color accent, {
  String? suffixText,
  String? hintText,
}) {
  final radius = BorderRadius.circular(AdminRadius.input);
  final border = OutlineInputBorder(
    borderRadius: radius,
    borderSide: BorderSide(color: AdminColors.border(context)),
  );
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: AdminColors.surfaceAlt(context),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    hintText: hintText,
    suffixText: suffixText,
    suffixStyle: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AdminColors.textMuted(context),
    ),
    border: border,
    enabledBorder: border,
    disabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: accent, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AdminColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AdminColors.error, width: 1.6),
    ),
  );
}

// ── Trial period ─────────────────────────────────────────────

class _TrialSection extends StatelessWidget {
  const _TrialSection({
    required this.controller,
    required this.days,
    required this.enabled,
    required this.onPreset,
  });

  final TextEditingController controller;
  final int days;
  final bool enabled;
  final ValueChanged<int> onPreset;

  static const _presets = [3, 7, 14, 30];

  static String _labelOf(int days) =>
      days == 3 || days == 7 ? '$days أيام' : '$days يوم';

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'الفترة التجريبية',
      subtitle: 'مدة استخدام المنصة مجانًا للعميل الجديد',
      icon: Icons.hourglass_bottom_rounded,
      color: AdminColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final inline = constraints.maxWidth >= 420;
              final field = SizedBox(
                width: inline ? 150 : double.infinity,
                child: TextFormField(
                  controller: controller,
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  decoration: _priceDecoration(
                    context,
                    AdminColors.warning,
                    suffixText: 'يوم',
                    hintText: '7',
                  ),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    if (n == null || n < 0) return 'أدخل عدد أيام صحيح';
                    if (n > 365) return 'الحد الأقصى 365 يوم';
                    return null;
                  },
                ),
              );
              final presets = Wrap(
                spacing: AdminSpace.sm,
                runSpacing: AdminSpace.sm,
                children: [
                  for (final d in _presets)
                    ChoiceChip(
                      label: Text(_labelOf(d)),
                      selected: days == d,
                      onSelected: enabled ? (_) => onPreset(d) : null,
                      selectedColor: AppTheme.amberDark,
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: days == d ? Colors.white : null,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AdminRadius.chip),
                      ),
                    ),
                ],
              );

              return inline
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        field,
                        const SizedBox(width: AdminSpace.md),
                        Expanded(child: presets),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        field,
                        const SizedBox(height: AdminSpace.sm),
                        presets,
                      ],
                    );
            },
          ),
          const SizedBox(height: AdminSpace.md),
          Container(
            padding: const EdgeInsets.all(AdminSpace.md),
            decoration: BoxDecoration(
              color: AdminColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AdminRadius.tile),
              border: Border.all(color: AdminColors.warning.withValues(alpha: 0.18)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, size: 17, color: AdminColors.warning),
                const SizedBox(width: AdminSpace.sm),
                Expanded(
                  child: Text(
                    days > 0
                        ? 'العميل الجديد بيستخدم كل المميزات مجانًا لمدة $days يوم قبل أول دفعة.'
                        : 'لو خلّيت المدة صفر، العميل هيحتاج يدفع قبل ما يستخدم المنصة.',
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment methods ──────────────────────────────────────────

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.controller,
    required this.enabled,
  });

  final AdminPaymentMethod method;
  final TextEditingController controller;
  final bool enabled;

  ({IconData icon, Color color}) get _brand {
    return switch (method.id) {
      'instapay' => (icon: Icons.sync_alt_rounded, color: AppTheme.deepBlue),
      'vodafone_cash' => (
          icon: Icons.smartphone_rounded,
          color: const Color(0xFFE60000),
        ),
      'etisalat_cash' => (
          icon: Icons.wifi_calling_3_rounded,
          color: const Color(0xFF00A651),
        ),
      _ => (
          icon: Icons.account_balance_wallet_outlined,
          color: AppTheme.primaryColor,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final brand = _brand;
    final header = Row(
      children: [
        AdminIconTile(icon: brand.icon, color: brand.color, size: 38, iconSize: 19),
        const SizedBox(width: AdminSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                method.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              Text(
                'رقم المحفظة / الحساب',
                style: TextStyle(
                  fontSize: 10,
                  color: AdminColors.textMuted(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final field = TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]'))],
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, letterSpacing: 0.4),
      decoration: _priceDecoration(context, brand.color).copyWith(
        hintText: '01xxxxxxxxx',
        suffixIcon: controller.text.trim().isEmpty
            ? null
            : IconButton(
                tooltip: 'نسخ الرقم',
                icon: const Icon(Icons.copy_rounded, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: controller.text.trim()));
                  AppToast.success(context, 'تم نسخ الرقم');
                },
              ),
      ),
      validator: (v) {
        final value = (v ?? '').trim();
        if (value.isEmpty) return 'اكتب رقم المحفظة';
        if (value.replaceAll(RegExp(r'[^0-9]'), '').length < 8) {
          return 'الرقم قصير جدًا';
        }
        return null;
      },
    );

    return Container(
      padding: const EdgeInsets.all(AdminSpace.md),
      decoration: BoxDecoration(
        color: AdminColors.surfaceAlt(context),
        borderRadius: BorderRadius.circular(AdminRadius.card),
        border: Border.all(color: AdminColors.border(context)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [header, const SizedBox(height: AdminSpace.sm), field],
            );
          }
          return Row(
            children: [
              SizedBox(width: 200, child: header),
              const SizedBox(width: AdminSpace.md),
              Expanded(child: field),
            ],
          );
        },
      ),
    );
  }
}

// ── Summary ──────────────────────────────────────────────────

class _PricingSummary extends StatelessWidget {
  const _PricingSummary({
    required this.plans,
    required this.savingOf,
    required this.trialDays,
    required this.methods,
  });

  final List<_PlanSpec> plans;
  final double Function(_PlanSpec) savingOf;
  final int trialDays;
  final int methods;

  @override
  Widget build(BuildContext context) {
    final perMonth = <({_PlanSpec plan, double value})>[
      for (final p in plans)
        (
          plan: p,
          value: p.months <= 0
              ? 0
              : (int.tryParse(p.controller.text.trim()) ?? 0) / p.months,
        ),
    ];
    final maxPerMonth = perMonth.fold<double>(
      0,
      (m, e) => e.value > m ? e.value : m,
    );
    final bestSaving = plans
        .map(savingOf)
        .fold<double>(0, (m, v) => v > m ? v : m);

    return _SettingsSection(
      title: 'ملخص التسعير',
      subtitle: 'معاينة سريعة للقيم الحالية قبل الحفظ',
      icon: Icons.insights_rounded,
      color: AppTheme.violetDeep,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in perMonth) ...[
            _PerMonthBar(
              label: entry.plan.title,
              value: entry.value,
              ratio: maxPerMonth <= 0 ? 0 : entry.value / maxPerMonth,
              color: entry.plan.color,
            ),
            if (entry != perMonth.last) const SizedBox(height: AdminSpace.sm),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AdminSpace.md),
            child: Divider(height: 1),
          ),
          Wrap(
            spacing: AdminSpace.sm,
            runSpacing: AdminSpace.sm,
            children: [
              _SummaryPill(
                icon: Icons.savings_outlined,
                label: 'أفضل توفير',
                value: bestSaving > 0 ? '${bestSaving.round()}%' : '—',
                color: AppTheme.successColor,
              ),
              _SummaryPill(
                icon: Icons.hourglass_bottom_rounded,
                label: 'التجربة',
                value: trialDays > 0 ? '$trialDays يوم' : 'بدون',
                color: AdminColors.warning,
              ),
              _SummaryPill(
                icon: Icons.account_balance_wallet_outlined,
                label: 'الدفع',
                value: '$methods طرق',
                color: AppTheme.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: AdminSpace.md),
          Text(
            'الأسعار بالجنيه المصري، وبتظهر في تطبيق العملاء بعد الحفظ مباشرة.',
            style: TextStyle(
              fontSize: 10.5,
              height: 1.6,
              color: AdminColors.textMuted(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerMonthBar extends StatelessWidget {
  const _PerMonthBar({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
  });

  final String label;
  final double value;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: AdminSpace.sm),
            Text(
              value > 0 ? '${AdminFmt.money(value.round())} / شهر' : '—',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AdminColors.textSecondary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        LayoutBuilder(
          builder: (context, constraints) {
            final clamped = ratio.clamp(0.0, 1.0);
            final rawWidth = constraints.maxWidth * clamped;
            final fillWidth = rawWidth <= 0
                ? 0.0
                : (rawWidth < 4 ? 4.0 : rawWidth);
            return SizedBox(
              height: 7,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(color: AdminColors.surfaceAlt(context)),
                    ),
                    if (fillWidth > 0)
                      PositionedDirectional(
                        start: 0,
                        top: 0,
                        bottom: 0,
                        width: fillWidth,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.withValues(alpha: 0.55),
                                color,
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AdminRadius.tile),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AdminColors.textMuted(context),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: color,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Footer actions ───────────────────────────────────────────

class _RestoreDefaultsButton extends StatelessWidget {
  const _RestoreDefaultsButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: enabled ? onTap : null,
        icon: const Icon(Icons.restart_alt_rounded, size: 18),
        label: const Text(
          'استعادة الإعدادات الافتراضية',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.dirty,
    required this.saving,
    required this.onSave,
    required this.onDiscard,
  });

  final bool dirty;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final statusColor = saving
        ? AppTheme.primaryColor
        : dirty
            ? AdminColors.warning
            : AdminColors.success;
    final statusIcon = saving
        ? Icons.sync_rounded
        : dirty
            ? Icons.edit_note_rounded
            : Icons.check_circle_outline_rounded;
    final statusLabel = saving
        ? 'جاري حفظ التغييرات...'
        : dirty
            ? 'لديك تغييرات غير محفوظة'
            : 'كل الإعدادات محفوظة';

    final status = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(statusIcon, size: 17, color: statusColor),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            statusLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ),
      ],
    );

    final saveButton = ElevatedButton.icon(
      onPressed: saving || !dirty ? null : onSave,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminRadius.button),
        ),
      ),
      icon: saving
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.save_outlined, size: 19),
      label: Text(saving ? 'جاري الحفظ...' : 'حفظ الإعدادات'),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AdminColors.surface(context),
        border: Border(top: BorderSide(color: AdminColors.border(context))),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.symmetric(
          horizontal: AdminSpace.md,
          vertical: AdminSpace.sm,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final inline = constraints.maxWidth >= 600;
            if (inline) {
              return Row(
                children: [
                  Expanded(child: status),
                  TextButton(
                    onPressed: dirty && !saving ? onDiscard : null,
                    child: const Text('تجاهل التغييرات'),
                  ),
                  const SizedBox(width: AdminSpace.xs),
                  saveButton,
                ],
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: status),
                    if (dirty && !saving)
                      TextButton.icon(
                        onPressed: onDiscard,
                        icon: const Icon(Icons.undo_rounded, size: 16),
                        label: const Text(
                          'تجاهل',
                          style: TextStyle(fontSize: 11.5),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AdminSpace.xs),
                SizedBox(width: double.infinity, child: saveButton),
              ],
            );
          },
        ),
      ),
    );
  }
}
