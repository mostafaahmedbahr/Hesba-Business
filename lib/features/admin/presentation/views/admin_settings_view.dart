import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';

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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('الأسعار', style: Theme.of(context).textTheme.titleMedium),
        TextFormField(controller: _monthly, decoration: const InputDecoration(labelText: 'شهري')),
        TextFormField(controller: _three, decoration: const InputDecoration(labelText: '3 شهور')),
        TextFormField(controller: _six, decoration: const InputDecoration(labelText: '6 شهور')),
        TextFormField(controller: _yearly, decoration: const InputDecoration(labelText: 'سنوي')),
        const SizedBox(height: 16),
        Text('الفترة المجانية', style: Theme.of(context).textTheme.titleMedium),
        TextFormField(controller: _trial, decoration: const InputDecoration(labelText: 'عدد الأيام')),
        const SizedBox(height: 16),
        Text('طرق الدفع', style: Theme.of(context).textTheme.titleMedium),
        for (var i = 0; i < widget.settings.paymentMethods.length; i++)
          TextFormField(controller: _numbers[i], decoration: InputDecoration(labelText: widget.settings.paymentMethods[i].label)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: widget.saving ? null : _save,
          child: widget.saving ? const CircularProgressIndicator() : const Text('حفظ'),
        ),
      ],
    );
  }
}
