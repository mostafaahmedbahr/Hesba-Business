import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/core/utils/toast.dart';
import 'package:hesba/features/admin/data/models/admin_settings.dart';
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
            AppToast.success(context, 'تم حفظ الإعدادات');
          } else if (state is SettingsError) {
            AppToast.error(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is SettingsLoading) return adminSkeletonList(context, count: 4);
          if (state is SettingsError) {
            return adminError(state.message, () => context.read<AdminSettingsCubit>().load());
          }
          final settings = state is SettingsLoaded
              ? state.settings
              : state is SettingsSaved
                  ? state.settings
                  : AdminSettings.defaults;
          return _SettingsForm(settings: settings, saving: state is SettingsSaving);
        },
      ),
    );
  }
}

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
    _monthly = TextEditingController(text: widget.settings.monthlyPrice.toString());
    _three = TextEditingController(text: widget.settings.threeMonthsPrice.toString());
    _six = TextEditingController(text: widget.settings.sixMonthsPrice.toString());
    _yearly = TextEditingController(text: widget.settings.yearlyPrice.toString());
    _trial = TextEditingController(text: widget.settings.trialDays.toString());
    _numbers = [for (final m in widget.settings.paymentMethods) TextEditingController(text: m.number)];
  }

  @override
  void dispose() {
    _monthly.dispose();
    _three.dispose();
    _six.dispose();
    _yearly.dispose();
    _trial.dispose();
    for (final c in _numbers) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final settings = widget.settings.copyWith(
      monthlyPrice: int.tryParse(_monthly.text) ?? widget.settings.monthlyPrice,
      threeMonthsPrice: int.tryParse(_three.text) ?? widget.settings.threeMonthsPrice,
      sixMonthsPrice: int.tryParse(_six.text) ?? widget.settings.sixMonthsPrice,
      yearlyPrice: int.tryParse(_yearly.text) ?? widget.settings.yearlyPrice,
      trialDays: int.tryParse(_trial.text) ?? widget.settings.trialDays,
      paymentMethods: [
        for (var i = 0; i < widget.settings.paymentMethods.length; i++)
          AdminPaymentMethod(
            id: widget.settings.paymentMethods[i].id,
            label: widget.settings.paymentMethods[i].label,
            number: i < _numbers.length ? _numbers[i].text.trim() : widget.settings.paymentMethods[i].number,
          ),
      ],
    );
    context.read<AdminSettingsCubit>().save(settings);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AdminSpace.md, 0, AdminSpace.md, AdminSpace.xxl),
      children: [
        const AdminPageHeader(title: 'الإعدادات', description: 'أسعار الباقات والفترة التجريبية وطرق الدفع'),
        AdminSection(
          title: 'أسعار الباقات (بالجنيه)',
          icon: Icons.sell_outlined,
          child: Column(
            children: [
              _field(_monthly, 'الباقة الشهرية'),
              _field(_three, 'باقة 3 شهور'),
              _field(_six, 'باقة 6 شهور'),
              _field(_yearly, 'الباقة السنوية', last: true),
            ],
          ),
        ),
        const SizedBox(height: AdminSpace.md),
        AdminSection(
          title: 'الفترة التجريبية',
          icon: Icons.access_time_outlined,
          child: _field(_trial, 'عدد أيام التجربة المجانية', last: true),
        ),
        const SizedBox(height: AdminSpace.md),
        AdminSection(
          title: 'طرق الدفع',
          icon: Icons.account_balance_wallet_outlined,
          child: Column(
            children: [
              for (var i = 0; i < widget.settings.paymentMethods.length; i++)
                _field(_numbers[i], widget.settings.paymentMethods[i].label,
                    last: i == widget.settings.paymentMethods.length - 1,
                    keyboard: TextInputType.phone),
            ],
          ),
        ),
        const SizedBox(height: AdminSpace.xxl),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.button)),
            ),
            onPressed: widget.saving ? null : _save,
            icon: widget.saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined, size: 20),
            label: Text(widget.saving ? 'جاري الحفظ...' : 'حفظ الإعدادات'),
          ),
        ),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label,
      {bool last = false, TextInputType keyboard = TextInputType.number}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : AdminSpace.sm),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
