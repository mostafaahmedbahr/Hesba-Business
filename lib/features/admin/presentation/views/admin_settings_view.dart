import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/core/utils/toast.dart';
import 'package:hesba/core/widgets/loading_widget.dart';
import 'package:hesba/core/models/admin_settings.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_settings_cubit.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';
import 'package:hesba/features/admin/presentation/views/diagnostics_view.dart';
import 'package:hesba/features/admin/presentation/widgets/admin_settings/feature_flags_section.dart';
import 'package:hesba/features/admin/presentation/widgets/admin_settings/hero.dart';
import 'package:hesba/features/admin/presentation/widgets/admin_settings/payment_method_card.dart';
import 'package:hesba/features/admin/presentation/widgets/admin_settings/plan_card.dart';
import 'package:hesba/features/admin/presentation/widgets/admin_settings/plan_spec.dart';
import 'package:hesba/features/admin/presentation/widgets/admin_settings/pricing_summary.dart';
import 'package:hesba/features/admin/presentation/widgets/admin_settings/restore_defaults_button.dart';
import 'package:hesba/features/admin/presentation/widgets/admin_settings/save_bar.dart';
import 'package:hesba/features/admin/presentation/widgets/admin_settings/section.dart';
import 'package:hesba/features/admin/presentation/widgets/admin_settings/trial_section.dart';

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
            return const LoadingWidget();
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
    final plans = <PlanSpec>[
      PlanSpec(
        id: 'monthly',
        title: 'الباقة الشهرية',
        subtitle: 'الأساس — دفع كل شهر',
        controller: _monthly,
        months: 1,
        icon: Icons.calendar_view_month_rounded,
        color: AppTheme.primaryColor,
      ),
      PlanSpec(
        id: 'threeMonths',
        title: 'باقة 3 شهور',
        subtitle: 'مناسبة للمحلات الموسمية',
        controller: _three,
        months: 3,
        icon: Icons.date_range_rounded,
        color: AppTheme.blueBright,
      ),
      PlanSpec(
        id: 'sixMonths',
        title: 'باقة 6 شهور',
        subtitle: 'توفير أكبر لمدة أطول',
        controller: _six,
        months: 6,
        icon: Icons.calendar_month_rounded,
        color: AppTheme.violetDeep,
      ),
      PlanSpec(
        id: 'yearly',
        title: 'الباقة السنوية',
        subtitle: 'أفضل قيمة على المدى الطويل',
        controller: _yearly,
        months: 12,
        icon: Icons.workspace_premium_rounded,
        color: AppTheme.secondaryDark,
      ),
    ];

    double savingOf(PlanSpec p) {
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

    final pricing = SettingsSection(
      title: 'أسعار الباقات',
      subtitle: 'الأسعار اللي بتظهر للعميل عند تجديد الاشتراك — بالجنيه المصري',
      icon: Icons.sell_outlined,
      color: AppTheme.primaryColor,
      trailing: SettingsSectionTag(
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
                  child: PlanCard(
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

    final trial = TrialSection(
      controller: _trial,
      days: _valueOf(_trial) ?? 0,
      enabled: !widget.saving,
      onPreset: _setTrialDays,
    );

    final payments = SettingsSection(
      title: 'طرق الدفع',
      subtitle: 'الأرقام اللي بيحوّل عليها العميل عند تجديد الاشتراك',
      icon: Icons.account_balance_wallet_outlined,
      color: AppTheme.successColor,
      trailing: SettingsSectionTag(
        label: '${widget.settings.paymentMethods.length} طرق',
        color: AppTheme.successColor,
      ),
      child: Column(
        children: [
          for (var i = 0; i < widget.settings.paymentMethods.length; i++) ...[
            if (i > 0) const SizedBox(height: AdminSpace.sm),
            PaymentMethodCard(
              method: widget.settings.paymentMethods[i],
              controller: _numbers[i],
              enabled: !widget.saving,
            ),
          ],
        ],
      ),
    );

    final flags = const FeatureFlagsSection();

    final summary = PricingSummary(
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
                SettingsHero(
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
                          flags,
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
                              flags,
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
                RestoreDefaultsButton(
                  enabled: !widget.saving,
                  onTap: _restoreDefaults,
                ),
                const SizedBox(height: AdminSpace.sm),
                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DiagnosticsView(),
                      ),
                    ),
                    icon: const Icon(Icons.bug_report_outlined, size: 18),
                    label: const Text(
                      'سجل التشخيص (الأخطاء الأخيرة)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Builder gives us a context inside the Form, so we can validate the
          // real fields without a GlobalKey (which can go stale on hot reload).
          Builder(
            builder: (formContext) => AdminSettingsSaveBar(
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
