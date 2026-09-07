import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/app_scaffold.dart';

class ContactUsView extends StatelessWidget {
  const ContactUsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      title: 'تواصل معنا',
      body: ListView(
        padding: EdgeInsets.all(20.w),
        children: [
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.support_agent_rounded,
                  size: 48.sp,
                  color: Colors.white,
                ),
                SizedBox(height: 12.h),
                Text(
                  'فريق دعم حسبة',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'نحن هنا لمساعدتك في أي وقت',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          _ContactTile(
            icon: Icons.email_rounded,
            color: const Color(0xFF1A4FD6),
            label: 'البريد الإلكتروني',
            value: 'support@hesba.app',
            showCopy: true,
          ),
          SizedBox(height: 12.h),
          _ContactTile(
            icon: Icons.phone_rounded,
            color: const Color(0xFF4CAF50),
            label: 'رقم الهاتف',
            value: '+20 100 000 0000',
            showCopy: true,
          ),
          SizedBox(height: 12.h),
          _ContactTile(
            icon: Icons.chat_rounded,
            color: const Color(0xFF25D366),
            label: 'واتساب',
            value: '+20 100 000 0000',
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool showCopy;

  const _ContactTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.showCopy = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: ListTile(
        leading: Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: color, size: 22.sp),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        trailing: showCopy
            ? IconButton(
                onPressed: () {
                  // Copy to clipboard
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ البيانات')),
                  );
                },
                icon: Icon(
                  Icons.copy_rounded,
                  size: 18.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            : null,
      ),
    );
  }
}
