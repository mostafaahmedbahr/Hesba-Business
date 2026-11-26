import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/app_logger.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';

/// شاشة تشخيص داخلية: تعرض آخر الأحداث المسجلة في [AppLogger]
/// (الأحدث أولًا) مع الرسالة والمكدس والسياق.
///
/// كل شيء في الذاكرة فقط — لا يُحفظ على القرص ولا يُرسل لأي جهة.
class DiagnosticsView extends StatefulWidget {
  const DiagnosticsView({super.key});

  @override
  State<DiagnosticsView> createState() => _DiagnosticsViewState();
}

class _DiagnosticsViewState extends State<DiagnosticsView> {
  @override
  Widget build(BuildContext context) {
    final entries = AppLogger.entries.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('سجل التشخيص'.tr()),
        actions: [
          IconButton(
            tooltip: 'نسخ السجل'.tr(),
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: entries.isEmpty
                ? null
                : () {
                    final text = entries.map(_formatEntry).join('\n');
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم نسخ السجل'.tr())),
                    );
                  },
          ),
          IconButton(
            tooltip: 'مسح السجل'.tr(),
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: entries.isEmpty
                ? null
                : () => setState(AppLogger.clear),
          ),
        ],
      ),
      body: entries.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(Icons.fact_check_outlined, size: 42),
                  ),
                  Text('مفيش أخطاء مسجلة — كل شيء تمام 🎉'.tr()),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _EntryTile(entry: entries[i]),
            ),
    );
  }

  String _formatEntry(LogEntry e) {
    final time = e.timestamp.toIso8601String();
    final buffer = StringBuffer(
      '[$time] ${e.severity.name.toUpperCase()} ${e.message}'
      '${e.context == null ? '' : ' [${e.context}]'}',
    );
    if (e.error != null) buffer.write(' → ${e.error}');
    if (e.stackTrace != null) buffer.write('\n${e.stackTrace}');
    return buffer.toString();
  }
}

class _EntryTile extends StatelessWidget {
  final LogEntry entry;

  const _EntryTile({required this.entry});

  ({Color color, IconData icon}) get _style => switch (entry.severity) {
        LoggingSeverity.debug => (
            color: AppTheme.mutedGray,
            icon: Icons.bug_report_outlined,
          ),
        LoggingSeverity.info => (
            color: AppTheme.primaryColor,
            icon: Icons.info_outline,
          ),
        LoggingSeverity.warning => (
            color: AppTheme.amberDeep,
            icon: Icons.warning_amber_rounded,
          ),
        LoggingSeverity.error => (
            color: AppTheme.danger,
            icon: Icons.error_outline,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final time = TimeOfDay.fromDateTime(entry.timestamp).format(context);

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      leading: Icon(style.icon, color: style.color, size: 20),
      title: Text(
        entry.message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${entry.severity.name.toUpperCase()}'
        '${entry.context == null ? '' : '  •  ${entry.context}'}'
        '  •  $time',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10, color: AppTheme.mutedGray),
      ),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SelectableText(
            '${entry.error ?? ''}'
            '${entry.stackTrace == null ? '' : '\n${entry.stackTrace}'}'
            .trim(),
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
