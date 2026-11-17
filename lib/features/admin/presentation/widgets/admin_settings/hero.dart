import 'package:flutter/material.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';

/// هيدر إعدادات المنصة: العنوان + وصف + شارات الحالة (حفظ/أسعار/تجريب/دفع).
class SettingsHero extends StatelessWidget {
  const SettingsHero({
    super.key,
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
              HeroStatus(dirty: dirty, saving: saving),
              HeroChip(
                icon: Icons.payments_outlined,
                label: monthlyPrice > 0
                    ? '${AdminFmt.money(monthlyPrice)} / شهر'
                    : 'حدد سعر الشهر',
              ),
              HeroChip(
                icon: Icons.hourglass_bottom_rounded,
                label: trialDays > 0 ? '$trialDays يوم تجربة' : 'بدون فترة تجريبية',
              ),
              HeroChip(
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

/// شريحة حالة الحفظ في الهيدر (جاري الحفظ / غير محفوظ / محفوظ).
class HeroStatus extends StatelessWidget {
  const HeroStatus({super.key, required this.dirty, required this.saving});

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

/// شريحة معلومة في الهيدر (سعر / تجربة / طرق دفع).
class HeroChip extends StatelessWidget {
  const HeroChip({super.key, required this.icon, required this.label});

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
