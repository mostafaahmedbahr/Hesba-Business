import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';

import 'plan_spec.dart';
import 'price_decoration.dart';
import 'section.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hesba/core/utils/dynamic_text.dart';

/// كارت إدخال سعر باقة (+ نسبة التوفير مقابل السعر الأساسي).
class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.spec,
    required this.saving,
    required this.isBest,
    required this.enabled,
  });

  final PlanSpec spec;
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
                SettingsSectionTag(label: 'الأكثر توفيرًا'.tr(), color: spec.color),
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
            decoration: priceDecoration(context, spec.color, suffixText: 'ج.م'.tr()),
            validator: (v) {
              final n = int.tryParse((v ?? '').trim());
              if (n == null || n <= 0) return 'اكتب سعرًا صحيحًا'.tr();
              return null;
            },
          ),
          const SizedBox(height: AdminSpace.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  spec.months == 1
                      ? 'سعر الاشتراك الأساسي'.tr()
                      : uiTr('≈ ${AdminFmt.money(_perMonth.round())} / شهر'),
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
                SettingsSectionTag(
                  label: uiTr('توفير ${saving.round()}%'),
                  color: AppTheme.successColor,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
