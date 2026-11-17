import 'package:flutter/material.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';

/// هيكل سيكشن موحّد في إعدادات الأسعار (أيقونة + عنوان + وصف + tag اختياري).
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
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

/// شارة صغيرة ملوّنة (عدد باقات / طرق دفع / توفير...).
class SettingsSectionTag extends StatelessWidget {
  const SettingsSectionTag({super.key, required this.label, required this.color});

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
