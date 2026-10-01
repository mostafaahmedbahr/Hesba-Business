import 'package:easy_localization/easy_localization.dart';

import '../../../../common_imports.dart';
import '../../data/models/activity_model.dart';

/// كارت عملية واحدة (بيع/منتج/مصروف/مرتجع).
class ActivityCard extends StatelessWidget {
  final ActivityModel activity;
  const ActivityCard({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grad = _gradFor(activity.type);
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: activity.isRead
            ? (isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC))
            : (isDark ? const Color(0xFF1E2A44) : const Color(0xFFEFF6FF)),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: activity.isRead
              ? (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))
              : AppTheme.primaryColor.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: grad),
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: Icon(_iconFor(activity.type), color: Colors.white, size: 19.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      activity.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                  if (!activity.isRead)
                    Container(width: 8.w, height: 8.w, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE11D48))),
                ]),
                SizedBox(height: 2.h),
                Text(
                  activity.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.sp, height: 1.4, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B)),
                ),
                SizedBox(height: 6.h),
                Row(children: [
                  Icon(Icons.access_time_rounded, size: 11.sp, color: const Color(0xFF94A3B8)),
                  SizedBox(width: 4.w),
                  Text(_timeAgo(activity.createdAt), style: TextStyle(fontSize: 10.5.sp, color: const Color(0xFF94A3B8))),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// أيقونة حسب النوع.
IconData _iconFor(ActivityType t) {
  switch (t) {
    case ActivityType.sale:
      return Icons.point_of_sale_rounded;
    case ActivityType.saleUpdate:
      return Icons.edit_rounded;
    case ActivityType.saleDelete:
      return Icons.delete_rounded;
    case ActivityType.productAdd:
      return Icons.add_shopping_cart_rounded;
    case ActivityType.productUpdate:
      return Icons.edit_rounded;
    case ActivityType.productDelete:
      return Icons.delete_rounded;
    case ActivityType.returnAdd:
      return Icons.assignment_return_rounded;
    case ActivityType.expenseAdd:
      return Icons.savings_rounded;
    case ActivityType.expenseUpdate:
      return Icons.edit_rounded;
    case ActivityType.expenseDelete:
      return Icons.delete_rounded;
    case ActivityType.generic:
      return Icons.notifications_rounded;
  }
}

/// لون حسب النوع.
List<Color> _gradFor(ActivityType t) {
  switch (t) {
    case ActivityType.sale:
      return const [Color(0xFF1A4FD6), Color(0xFF4A7BFF)];
    case ActivityType.productAdd:
      return const [Color(0xFFF59E0B), Color(0xFFFBBF24)];
    case ActivityType.productDelete:
      return const [Color(0xFFE11D48), Color(0xFFFB7185)];
    case ActivityType.returnAdd:
      return const [Color(0xFFF59E0B), Color(0xFFFF8F3D)];
    case ActivityType.expenseAdd:
      return const [Color(0xFFE11D48), Color(0xFFFB7185)];
    case ActivityType.expenseUpdate:
      return const [Color(0xFF06B6D4), Color(0xFF22D3EE)];
    default:
      return const [Color(0xFF1A4FD6), Color(0xFF7C4DFF)];
  }
}

/// وقت مختصر (منذ د/س/يوم).
String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
  if (diff.inDays == 1) return 'أمس';
  if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
  return DateFormat('d MMM', 'ar').format(dt);
}
