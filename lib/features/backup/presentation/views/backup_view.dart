import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/backup_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/error_message.dart';
import '../../../../core/utils/toast.dart';
import '../../../main/presentation/widgets/main_app_bar.dart';

/// شاشة تشغيلية بسيطة: إنشاء نسخة احتياطية محلية + مشاركتها/رفعها.
/// الاستعادة تتم بسكربت Admin SDK على الكمبيوتر — راجع
/// `tool/restore_backup/README.md`.
class BackupView extends StatefulWidget {
  const BackupView({super.key});

  @override
  State<BackupView> createState() => _BackupViewState();
}

class _BackupViewState extends State<BackupView> {
  final BackupService _service = sl<BackupService>();

  bool _busy = false;
  String? _error;
  BackupResult? _last;
  List<BackupFile> _files = const <BackupFile>[];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      final files = await _service.listBackups();
      if (!mounted) return;
      setState(() => _files = files);
    } catch (_) {
      // فشل قراءة المجلد مش سبب لمنع إنشاء نسخة جديدة.
    }
  }

  Future<void> _export() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _service.exportCurrentShop();
      if (!mounted) return;
      setState(() {
        _last = result;
        _busy = false;
      });
      await _loadFiles();
      if (!mounted) return;
      AppToast.success(context, 'تم إنشاء النسخة الاحتياطية بنجاح');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = friendlyError(e);
      });
    }
  }

  Future<void> _share(String path) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          subject: 'نسخة احتياطية لتطبيق حسبة',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: MainAppBar(title: 'النسخ الاحتياطي'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              color: scheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.backup, color: AppTheme.primaryColor, size: 30.sp),
                    SizedBox(height: 10.h),
                    Text(
                      'نسخة كاملة من بيانات المحل',
                      style: TextStyle(
                          fontSize: 16.sp, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'تتضمن المنتجات والمبيعات والمرتجعات والمصروفات والمخزون '
                      'والحسابات والذمم والموردين والمستخدمين والاشتراك. '
                      'التواريخ والمعرّفات الأصلية محفوظة، فيمكن استخدامها '
                      'لإعادة الرفع على Firebase بدون تكرار أو تغيير تواريخ.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        height: 1.6,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 52.h,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _export,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                icon: _busy
                    ? SizedBox(
                        width: 18.sp,
                        height: 18.sp,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.download),
                label: Text(
                  _busy ? 'جارٍ تجهيز النسخة...' : 'إنشاء نسخة احتياطية',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.sp),
                ),
              ),
            ),
            if (_error != null) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: scheme.onErrorContainer, fontSize: 12.sp),
                ),
              ),
            ],
            if (_last != null) ...[
              SizedBox(height: 16.h),
              _SummaryCard(result: _last!, onShare: () => _share(_last!.filePath)),
            ],
            SizedBox(height: 24.h),
            Text(
              'النسخ المحفوظة على هذا الجهاز',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8.h),
            if (_files.isEmpty)
              Text(
                'لا توجد نسخ بعد.',
                style: TextStyle(fontSize: 12.sp, color: scheme.onSurfaceVariant),
              )
            else
              Card(
                elevation: 0,
                color: scheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Column(
                  children: [
                    for (final file in _files)
                      ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(
                          file.name,
                          style: TextStyle(fontSize: 11.sp),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${_formatSize(file.sizeBytes)}  •  ${file.modified}',
                          style: TextStyle(fontSize: 10.sp),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.ios_share),
                          onPressed: () => _share(file.path),
                        ),
                      ),
                  ],
                ),
              ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                'تنبيه: النسخة الموجودة على الجهاز فقط لا تحميك من ضياعه. '
                'استخدم زر المشاركة لرفعها على Google Drive أو واتساب أو أي '
                'مكان آمن. استعادة البيانات على Firebase تتم من سكربت Admin '
                'SDK على الكمبيوتر وليس من داخل التطبيق.',
                style: TextStyle(
                  fontSize: 11.sp,
                  height: 1.6,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.result, required this.onShare});

  final BackupResult result;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle,
                    color: AppTheme.successColor, size: 20.sp),
                SizedBox(width: 8.w),
                Text('تم التصدير',
                    style: TextStyle(
                        fontSize: 14.sp, fontWeight: FontWeight.w800)),
              ],
            ),
            SizedBox(height: 12.h),
            Text('عدد المستندات: ${result.docCount}',
                style: TextStyle(fontSize: 12.sp)),
            Text('الحجم: ${_size(result.sizeBytes)}',
                style: TextStyle(fontSize: 12.sp)),
            if (result.fromCache)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  'تنبيه: جزء من البيانات جاء من كاش الجهاز (لا يوجد اتصال '
                  'بالخادم لحظة التصدير). أعد التصدير وأنت متصل قبل الاعتماد '
                  'على النسخة.',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.orange.shade800,
                    height: 1.5,
                  ),
                ),
              ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 4.h,
              children: [
                for (final entry in result.counts.entries)
                  Chip(
                    label: Text('${entry.key}: ${entry.value}',
                        style: TextStyle(fontSize: 9.sp)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            OutlinedButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share),
              label: const Text('مشاركة / حفظ النسخة'),
            ),
          ],
        ),
      ),
    );
  }

  String _size(int bytes) =>
      bytes < 1024 * 1024
          ? '${(bytes / 1024).toStringAsFixed(1)} KB'
          : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
