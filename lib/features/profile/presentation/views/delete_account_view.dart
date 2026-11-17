import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/user_role_service.dart';
import '../../../../core/utils/error_message.dart';
import '../../data/repos/account_repo.dart';
import '../widgets/app_scaffold.dart';
import 'package:hesba/core/services/app_logger.dart';

/// طلب حذف الحساب — متطلب Google Play للتطبيقات التي تتيح إنشاء حساب.
///
/// القواعد تمنع حذف السجلات المالية من جهة العميل أصلًا، لذلك لا تحذف هذه
/// الشاشة أي بيانات بنفسها: هي تلتقط **طلبًا موثقًا** (بعد إعادة المصادقة
/// بكلمة المرور) في `account_deletion_requests`، ثم يسجّل المستخدم خروجه،
/// ويتولى فريق حسبة تنفيذ الحذف النهائي لبيانات الحساب والمحل — كما تنص
/// سياسة الخصوصية.
class DeleteAccountView extends StatefulWidget {
  const DeleteAccountView({super.key});

  @override
  State<DeleteAccountView> createState() => _DeleteAccountViewState();
}

class _DeleteAccountViewState extends State<DeleteAccountView> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = sl<UserRoleService>().isStaff;
    return AppScaffold(
      title: 'حذف الحساب',
      body: isStaff
          ? const _StaffRestricted()
          : Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: EdgeInsets.all(20.w),
                children: [
                  const _WarningCard(),
                  SizedBox(height: 22.h),
                  Text(
                    'كلمة المرور الحالية',
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    enabled: !_loading,
                    decoration: InputDecoration(
                      hintText: 'أدخل كلمة المرور للتأكيد',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'كلمة المرور مطلوبة' : null,
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    'سبب الحذف (اختياري)',
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _reasonController,
                    enabled: !_loading,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'ساعدنا بمعرفة السبب (اختياري)',
                      prefixIcon: const Icon(Icons.edit_note_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 26.h),
                  _DeleteButton(loading: _loading, onPressed: _submit),
                  SizedBox(height: 16.h),
                  Text(
                    'أو تواصل مباشرة: hesbabusiness1@gmail.com',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد طلب الحذف'),
        content: const Text(
          'سيتم تسجيل خروجك وإرسال طلب حذف حسابك وبيانات محلك إلى فريق حسبة. '
          'الحذف نهائي ولا يمكن التراجع عنه بعد تنفيذه. هل تريد المتابعة؟',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف الحساب'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = sl<AccountRepo>();
      await repo.requestAccountDeletion(
        currentPassword: _passwordController.text,
        reason: _reasonController.text.trim(),
      );
      await repo.logout();
      sl<UserRoleService>().clear();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تم استلام طلب الحذف — سيتواصل معك فريق حسبة لإتمامه.'),
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } on FirebaseAuthException catch (e, logSt) {
      AppLogger.nonFatal('features/profile/presentation/views/delete_account_view.dart', e, logSt, severity: LoggingSeverity.warning);
      setState(() => _loading = false);
      final message = e.code == 'wrong-password' || e.code == 'invalid-credential'
          ? 'كلمة المرور غير صحيحة'
          : translateError(e.toString());
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e, logSt) {
      AppLogger.nonFatal('features/profile/presentation/views/delete_account_view.dart', e, logSt, severity: LoggingSeverity.warning);
      setState(() => _loading = false);
      messenger.showSnackBar(SnackBar(content: Text(translateError(e.toString()))));
    }
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard();

  @override
  Widget build(BuildContext context) {
    final items = const [
      'سيتم حذف حسابك وبيانات محلك المرتبطة: المنتجات، المبيعات، المرتجعات، المصروفات، الموردين، العملاء والذمم، سجلات الاشتراك والمدفوعات.',
      'قد تُحتفظ بعض السجلات المالية للمدة القانونية/الضرائبية وفق سياسة الخصوصية، دون أن تكون متاحة للاستخدام.',
      'حذف حسابك يلغي أيضًا اشتراكك الحالي ولا يمكن استرجاع أي بيانات بعد اكتمال الحذف.',
      'طلبات الحذف تُراجع وينفذها فريق حسبة يدويًا بعد التأكد من هويتك.',
    ];
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B).withValues(alpha: 0.08),
        border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 20),
              SizedBox(width: 8.w),
              Text(
                'قبل المتابعة',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFE53935),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          for (final item in items)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900)),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(fontSize: 12.sp, height: 1.5),
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

class _StaffRestricted extends StatelessWidget {
  const _StaffRestricted();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 48, color: Colors.grey),
            SizedBox(height: 16.h),
            Text(
              'حذف الحساب متاح لصاحب الحساب فقط',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'حسابات الموظفين تُدار من قِبل صاحب المحل — تواصل مع مالك المحل لإيقاف حسابك.',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade500, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE53935),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE53935).withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.delete_forever_rounded),
        label: Text(
          'إرسال طلب الحذف',
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
