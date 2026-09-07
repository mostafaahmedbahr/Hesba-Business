import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/toast.dart';
import '../../data/repos/contact_repo.dart';
import '../../../profile/presentation/widgets/app_scaffold.dart';
import '../widgets/contact_header.dart';
import '../widgets/contact_tile.dart';
import '../widgets/feedback_form.dart';

class ContactUsView extends StatefulWidget {
  const ContactUsView({super.key});

  @override
  State<ContactUsView> createState() => _ContactUsViewState();
}

class _ContactUsViewState extends State<ContactUsView> {
  static const _email = 'hesbabusiness1@gmail.com';
  static const _whatsapp = '201093312802';
  static const _phone = '01110690299';

  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      title: 'تواصل معنا',
      body: ListView(
        padding: EdgeInsets.all(20.w),
        children: [
          const ContactHeader(),
          SizedBox(height: 24.h),
          _sectionTitle(theme, 'طرق التواصل'),
          SizedBox(height: 10.h),
          ContactTile(
            icon: Icons.email_rounded,
            color: const Color(0xFF1A4FD6),
            label: 'البريد الإلكتروني',
            value: _email,
            onTap: _openEmail,
          ),
          SizedBox(height: 10.h),
          ContactTile(
            icon: Icons.chat_rounded,
            color: const Color(0xFF25D366),
            label: 'واتساب',
            value: '01093312802',
            onTap: _openWhatsApp,
          ),
          SizedBox(height: 10.h),
          ContactTile(
            icon: Icons.phone_rounded,
            color: const Color(0xFFFF9800),
            label: 'الاتصال المباشر',
            value: _phone,
            onTap: _openDialer,
          ),
          SizedBox(height: 28.h),
          _sectionTitle(theme, 'أرسل رسالتك'),
          SizedBox(height: 10.h),
          FeedbackForm(
            submitting: _submitting,
            onSubmit: _submit,
          ),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.w800,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Future<void> _openEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _email,
      queryParameters: {'subject': 'دعم حسبة'},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      AppToast.error(context, 'لا يوجد تطبيق بريد إلكتروني');
    }
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/$_whatsapp');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      AppToast.error(context, 'واتساب غير مثبت على الجهاز');
    }
  }

  Future<void> _openDialer() async {
    final uri = Uri(scheme: 'tel', path: _phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      AppToast.error(context, 'لا يمكن فتح قائمة الاتصال');
    }
  }

  Future<void> _submit({
    required String type,
    required String title,
    required String description,
  }) async {
    setState(() => _submitting = true);

    try {
      await sl<ContactRepo>().submitFeedback(
        type: type,
        title: title,
        description: description,
      );
      if (!mounted) return;
      AppToast.success(context, 'تم إرسال رسالتك بنجاح');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'حدث خطأ، حاول مرة أخرى');
    }

    if (mounted) setState(() => _submitting = false);
  }
}
