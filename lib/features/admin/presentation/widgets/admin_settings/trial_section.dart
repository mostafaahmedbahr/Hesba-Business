import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';

import 'price_decoration.dart';
import 'section.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hesba/core/utils/dynamic_text.dart';

/// سيكشن الفترة التجريبية: حقل الأيام + presets + تلميح.
class TrialSection extends StatelessWidget {
  const TrialSection({
    super.key,
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
      days == 3 || days == 7 ? uiTr('$days أيام') : uiTr('$days يوم');

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'الفترة التجريبية'.tr(),
      subtitle: 'مدة استخدام المنصة مجانًا للعميل الجديد'.tr(),
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
                  decoration: priceDecoration(
                    context,
                    AdminColors.warning,
                    suffixText: 'يوم'.tr(),
                    hintText: '7',
                  ),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    if (n == null || n < 0) return 'أدخل عدد أيام صحيح'.tr();
                    if (n > 365) return 'الحد الأقصى 365 يوم'.tr();
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
                        ? uiTr('العميل الجديد بيستخدم كل المميزات مجانًا لمدة $days يوم قبل أول دفعة.')
                        : 'لو خلّيت المدة صفر، العميل هيحتاج يدفع قبل ما يستخدم المنصة.'.tr(),
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
