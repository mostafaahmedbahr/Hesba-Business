import 'package:flutter/material.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';

import 'plan_spec.dart';
import 'section.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hesba/core/utils/dynamic_text.dart';

/// ملخص التسعير: سعر/شهر لكل باقة + أفضل توفير + الفترة التجريبية + طرق الدفع.
class PricingSummary extends StatelessWidget {
  const PricingSummary({
    super.key,
    required this.plans,
    required this.savingOf,
    required this.trialDays,
    required this.methods,
  });

  final List<PlanSpec> plans;
  final double Function(PlanSpec) savingOf;
  final int trialDays;
  final int methods;

  @override
  Widget build(BuildContext context) {
    final perMonth = <({PlanSpec plan, double value})>[
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

    return SettingsSection(
      title: 'ملخص التسعير'.tr(),
      subtitle: 'معاينة سريعة للقيم الحالية قبل الحفظ'.tr(),
      icon: Icons.insights_rounded,
      color: AppTheme.violetDeep,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in perMonth) ...[
            PerMonthBar(
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
              SummaryPill(
                icon: Icons.savings_outlined,
                label: 'أفضل توفير'.tr(),
                value: bestSaving > 0 ? '${bestSaving.round()}%' : '—',
                color: AppTheme.successColor,
              ),
              SummaryPill(
                icon: Icons.hourglass_bottom_rounded,
                label: 'التجربة'.tr(),
                value: trialDays > 0 ? uiTr('$trialDays يوم') : 'بدون'.tr(),
                color: AdminColors.warning,
              ),
              SummaryPill(
                icon: Icons.account_balance_wallet_outlined,
                label: 'الدفع'.tr(),
                value: uiTr('$methods طرق'),
                color: AppTheme.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: AdminSpace.md),
          Text(
            'الأسعار بالجنيه المصري، وبتظهر في تطبيق العملاء بعد الحفظ مباشرة.'.tr(),
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

/// شريط أفقي: سعر الباقة / شهر بنسبة من أعلى قيمة.
class PerMonthBar extends StatelessWidget {
  const PerMonthBar({
    super.key,
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
              value > 0 ? uiTr('${AdminFmt.money(value.round())} / شهر') : '—',
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

/// شريحة معلومة صغيرة داخل الملخص (أفضل توفير / التجربة / الدفع).
class SummaryPill extends StatelessWidget {
  const SummaryPill({
    super.key,
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
