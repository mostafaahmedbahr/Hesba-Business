import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/core/utils/toast.dart';
import 'package:hesba/features/admin/data/models/admin_settings.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_settings_cubit.dart';

class AdminSettingsView extends StatelessWidget {
  const AdminSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminSettingsCubit(repo: sl<AdminRepo>())..load(),
      child: BlocConsumer<AdminSettingsCubit, AdminSettingsState>(
        listener: (context, state) {
          if (state is SettingsSaved) {
            AppToast.success(context, 'تم الحفظ');
          } else if (state is SettingsError) {
            AppToast.error(context, state.message);
          }
        },
        builder: (context, state) {
        if (state is SettingsLoading) return const Center(child: CircularProgressIndicator());
        if (state is SettingsError) return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
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
            number: _numbers[i].text.trim(),
          ),
      ],
    );
    context.read<AdminSettingsCubit>().save(settings);
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.withValues(alpha: 0.08),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          isDense: true,
        );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card(
          context,
          title: 'أسعار الباقات',
          icon: Icons.sell_outlined,
          children: [
            _field(_monthly, 'شهري (ج)', deco('الباقة الشهرية')),
            _field(_three, '3 شهور (ج)', deco('3 شهور')),
            _field(_six, '6 شهور (ج)', deco('6 شهور')),
            _field(_yearly, 'سنوي (ج)', deco('السنوي')),
          ],
        ),
        const SizedBox(height: 16),
        _card(
          context,
          title: 'الفترة التجريبية',
          icon: Icons.access_time,
          children: [_field(_trial, 'عدد الأيام', deco('الأيام'))],
        ),
        const SizedBox(height: 16),
        _card(
          context,
          title: 'طرق الدفع',
          icon: Icons.account_balance_wallet_outlined,
          children: [
            for (var i = 0; i < widget.settings.paymentMethods.length; i++)
              _field(_numbers[i], widget.settings.paymentMethods[i].label, deco('الرقم')),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: widget.saving ? null : _save,
          child: widget.saving
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, {required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: AppTheme.primarySoft, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String suffixHint, InputDecoration deco) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: deco.copyWith(suffixText: suffixHint, hintText: suffixHint),
      ),
    );
  }
}
