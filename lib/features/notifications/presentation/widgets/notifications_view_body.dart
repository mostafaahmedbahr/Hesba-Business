import 'package:hesba/core/widgets/loading_widget.dart';
import 'package:hesba/features/notifications/presentation/widgets/activity_card.dart';
import 'package:hesba/features/notifications/presentation/widgets/reminder_card.dart';
import 'package:hesba/features/notifications/presentation/widgets/reminder_empty_state.dart';
import 'package:hesba/features/notifications/presentation/widgets/reminder_enable_banner.dart';
import 'package:hesba/features/notifications/presentation/widgets/reminder_header.dart';
import '../../../../common_imports.dart';
import '../../data/models/local_reminder.dart';
import '../view_model/activity_cubit.dart';
import '../view_model/activity_state.dart';
import '../view_model/notification_state.dart';
import '../view_model/notification_cubit.dart';

/// جسم الشاشة (تذكيراتي ثم سجل العمليات — بدون تبديل).
class NotificationsViewBody extends StatefulWidget {
  const NotificationsViewBody({super.key});

  @override
  State<NotificationsViewBody> createState() => _NotificationsViewBodyState();
}

class _NotificationsViewBodyState extends State<NotificationsViewBody> {
  @override
  void initState() {
    super.initState();
    // هنا جوه الـ providers — يصفر العداد عند الدخول.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationCubit>().markSeenAfterOpen();
    });
  }

  @override
  void dispose() {
    // ضمان إضافي عند الخروج.
    try {
      context.read<ActivityCubit>().markAllRead();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        final list = state.personalReminders;
        return CustomScrollView(
          slivers: [
            ReminderHeader(count: list.length),
            // لودر أول فتح (بدل اللاج والشاشة الفاضية).
            if (state.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: LoadingWidget(message: 'جاري تحميل تذكيراتك...'),
              )
            else ...[
              if (!state.permissionGranted)
                SliverToBoxAdapter(
                  child: ReminderEnableBanner(
                    onEnable: () => context.read<NotificationCubit>().enablePermissions(),
                  ),
                ),
              // قسم التذكيرات.
              SliverToBoxAdapter(child: _RemindersSection(list: list)),
              // قسم سجل العمليات.
              const SliverToBoxAdapter(child: _ActivitySection()),
            ],
          ],
        );
      },
    );
  }
}

/// قسم التذكيرات (فاضي أو كروت).
class _RemindersSection extends StatelessWidget {
  final List<LocalReminder> list;
  const _RemindersSection({required this.list});

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return ReminderEmptyState(
        onAdd: () => context.read<NotificationCubit>().openForm(context),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
      child: Column(
        children: List.generate(list.length, (i) {
          final r = list[i];
          return Padding(
            padding: EdgeInsets.only(bottom: i == list.length - 1 ? 0 : 10.h),
            child: ReminderCard(
              reminder: r,
              onToggle: () => context.read<NotificationCubit>().toggleReminderEnabled(r),
              onTest: () => context.read<NotificationCubit>().testNow(context, r),
              onEdit: () => context.read<NotificationCubit>().openForm(context, reminder: r),
              onDelete: () => context.read<NotificationCubit>().confirmDelete(context, r),
            ),
          );
        }),
      ),
    );
  }
}

/// قسم سجل العمليات (من الـ ActivityCubit العام).
class _ActivitySection extends StatelessWidget {
  const _ActivitySection();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocBuilder<ActivityCubit, ActivityState>(
      builder: (context, state) {
        final list = state.activities;
        return Padding(
          padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 110.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.receipt_long_rounded, color: Colors.white, size: 17.sp),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('سجل العمليات', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                      Text('كل عملية بتعملها بتتسجل هنا', style: TextStyle(fontSize: 11.sp, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B))),
                    ],
                  ),
                ),
                if (list.isNotEmpty && state.unreadCount > 0)
                  TextButton(
                    onPressed: () => context.read<ActivityCubit>().markAllRead(),
                    child: Text('تعليم كمقروء', style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
                  ),
              ]),
              SizedBox(height: 12.h),
              if (list.isEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
                  ),
                  child: Column(children: [
                    Icon(Icons.inbox_rounded, size: 34.sp, color: const Color(0xFF94A3B8)),
                    SizedBox(height: 10.h),
                    Text('لا توجد عمليات بعد', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    SizedBox(height: 4.h),
                    Text('أي بيع أو منتج أو مصروف أو مرتجع هيظهر هنا', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5.sp, color: const Color(0xFF94A3B8))),
                  ]),
                )
              else
                Column(
                  children: List.generate(list.length, (i) => Padding(
                        padding: EdgeInsets.only(bottom: i == list.length - 1 ? 0 : 10.h),
                        child: ActivityCard(activity: list[i]),
                      )),
                ),
            ],
          ),
        );
      },
    );
  }
}
