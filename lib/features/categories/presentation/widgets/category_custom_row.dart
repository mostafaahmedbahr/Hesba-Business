import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common_imports.dart';
import '../cubit/category_cubit.dart';
import 'category_delete_dialog.dart';
import '../../../subscription/presentation/subscription_gate.dart';

/// صف قسم مخصص (سحب للحذف + زرار حذف).
class CategoryCustomRow extends StatelessWidget {
  final String name;

  const CategoryCustomRow({super.key, required this.name});

  /// يفتح التأكيد ثم يحذف.
  Future<void> _askDelete(BuildContext context) async {
    if (!await SubscriptionGate.ensureCanModify(context)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => CategoryDeleteDialog(name: name),
    );
    if (confirmed == true && context.mounted) {
      HapticFeedback.heavyImpact();
      await context.read<CategoryCubit>().removeCategory(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dismissible(
      key: ValueKey('custom_$name'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: const Color(0xFFE11D48),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(Icons.delete_rounded, color: Colors.white, size: 20.sp),
      ),
      confirmDismiss: (_) async {
        await _askDelete(context);
        return false;
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                gradient: AppTheme.successGradient,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.label_rounded, color: Colors.white, size: 16.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            InkWell(
              onTap: () => _askDelete(context),
              borderRadius: BorderRadius.circular(10.r),
              child: Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFE11D48).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: const Color(0xFFE11D48).withValues(alpha: 0.14),
                  ),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 16.sp,
                  color: const Color(0xFFE11D48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
