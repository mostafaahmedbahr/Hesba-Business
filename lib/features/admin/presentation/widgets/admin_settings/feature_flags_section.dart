import 'package:flutter/material.dart';

import '../../../../../core/services/app_logger.dart';
import '../../../../../core/services/feature_flags_service.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/toast.dart';
import '../../views/admin_ds.dart';
import 'section.dart';

/// مفاتيح التحكم عن بُعد اللي بتتحكم في شكل تطبيق العميل.
/// القيمة بتتكتب في Firestore: feature_flags/home
class FeatureFlagsSection extends StatefulWidget {
  const FeatureFlagsSection({super.key});

  @override
  State<FeatureFlagsSection> createState() => _FeatureFlagsSectionState();
}

class _FeatureFlagsSectionState extends State<FeatureFlagsSection> {
  bool _loaded = false;
  bool _saving = false;
  bool _showSubscription = FeatureFlagsService.showSubscriptionSection;
  bool _showBackup = FeatureFlagsService.showBackup;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await FeatureFlagsService.refresh();
    if (!mounted) return;
    setState(() {
      _showSubscription = FeatureFlagsService.showSubscriptionSection;
      _showBackup = FeatureFlagsService.showBackup;
      _loaded = true;
    });
  }

  Future<void> _toggle(bool value) async {
    setState(() => _saving = true);
    try {
      await FeatureFlagsService.setShowSubscriptionSection(value);
      if (!mounted) return;
      setState(() => _showSubscription = value);
      AppToast.success(
        context,
        value
            ? 'قسم الاشتراك هيظهر في الرئيسية'
            : 'قسم الاشتراك هيختفي من الرئيسية',
      );
    } catch (e, logSt) {
      AppLogger.nonFatal(
        'features/admin/presentation/widgets/admin_settings/feature_flags_section.dart',
        e,
        logSt,
        severity: LoggingSeverity.warning,
      );
      if (mounted) {
        AppToast.error(context, 'فشل حفظ المفتاح — تأكد من صلاحيات الأدمن');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleBackup(bool value) async {
    setState(() => _saving = true);
    try {
      await FeatureFlagsService.setShowBackup(value);
      if (!mounted) return;
      setState(() => _showBackup = value);
      AppToast.success(
        context,
        value
            ? 'زرار النسخ الاحتياطي هيظهر للعملاء'
            : 'زرار النسخ الاحتياطي هيختفي من العملاء',
      );
    } catch (e, logSt) {
      AppLogger.nonFatal(
        'features/admin/presentation/widgets/admin_settings/feature_flags_section.dart',
        e,
        logSt,
        severity: LoggingSeverity.warning,
      );
      if (mounted) {
        AppToast.error(context, 'فشل حفظ المفتاح — تأكد من صلاحيات الأدمن');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'مفاتيح العرض',
      subtitle: 'تحكّم في ظهور أقسام تطبيق العملاء فوراً من غير تحديث التطبيق',
      icon: Icons.tune_rounded,
      color: AppTheme.violetDeep,
      trailing: SettingsSectionTag(
        label: !_loaded ? '...' : (_showSubscription ? 'مفعل' : 'موقف'),
        color: _showSubscription ? AppTheme.successColor : AppTheme.danger,
      ),
      child: Material(
        color: AdminColors.surfaceAlt(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminRadius.card),
          side: BorderSide(color: AdminColors.border(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: Column(
            children: [
              SwitchListTile(
                value: _showSubscription,
                onChanged: _saving ? null : _toggle,
                activeThumbColor: AppTheme.primaryColor,
                secondary: Icon(
                  _showSubscription
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: AppTheme.primaryColor,
                ),
                title: const Text(
                  'قسم الاشتراك في الرئيسية',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  _showSubscription
                      ? 'ظاهر حالياً للعملاء'
                      : 'مخفي حالياً من العملاء',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AdminColors.textSecondary(context),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                value: _showBackup,
                onChanged: _saving ? null : _toggleBackup,
                activeThumbColor: AppTheme.primaryColor,
                secondary: Icon(
                  _showBackup ? Icons.backup : Icons.visibility_off_rounded,
                  color: AppTheme.primaryColor,
                ),
                title: const Text(
                  'زرار النسخ الاحتياطي',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  _showBackup
                      ? 'ظاهر حالياً في قائمة العميل'
                      : 'مخفي حالياً من قائمة العميل',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AdminColors.textSecondary(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
