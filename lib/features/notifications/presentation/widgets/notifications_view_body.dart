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

/// جسم الشاشة (تاب تذكيراتي | تاب سجل العمليات).
class NotificationsViewBody extends StatefulWidget {
  const NotificationsViewBody({super.key});

  @override
  State<NotificationsViewBody> createState() => _NotificationsViewBodyState();
}

class _NotificationsViewBodyState extends State<NotificationsViewBody> {
  /// 0 تذكيرات | 1 عمليات.
  int _tab = 0;

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

  void _setTab(int i) {
    if (i == _tab) return;
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        final list = state.personalReminders;
        return CustomScrollView(
          slivers: [
            ReminderHeader(count: list.length),
            // مبدل التابين (Material ثابتة عشان الـ ripple).
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkSurfaceAlt
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkBorder
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        _TabBtn(icon: Icons.add_alert_rounded, label: 'تذكيراتي', selected: _tab == 0, onTap: () => _setTab(0)),
                        _TabBtn(icon: Icons.receipt_long_rounded, label: 'سجل العمليات', selected: _tab == 1, onTap: () => _setTab(1)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_tab == 0) ...[
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
                // زرار إضافة ثابت (بدل الـ FAB).
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                    child: _AddReminderBtn(
                      onTap: () => context.read<NotificationCubit>().openForm(context),
                    ),
                  ),
                ),
                if (list.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ReminderEmptyState(
                      onAdd: () => context.read<NotificationCubit>().openForm(context),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 110.h),
                    sliver: SliverList.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) => SizedBox(height: 10.h),
                      itemBuilder: (context, i) {
                        final r = list[i];
                        return ReminderCard(
                          reminder: r,
                          onToggle: () => context.read<NotificationCubit>().toggleReminderEnabled(r),
                          onTest: () => context.read<NotificationCubit>().testNow(context, r),
                          onEdit: () => context.read<NotificationCubit>().openForm(context, reminder: r),
                          onDelete: () => context.read<NotificationCubit>().confirmDelete(context, r),
                        );
                      },
                    ),
                  ),
              ],
            ] else
              const SliverToBoxAdapter(child: _ActivitySection()),
          ],
        );
      },
    );
  }
}

/// زرار تاب واحد.
class _TabBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabBtn({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.symmetric(vertical: 9.h),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: selected
                ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.30), blurRadius: 8, offset: const Offset(0, 3))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15.sp, color: selected ? Colors.white : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B))),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? Colors.white : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// زرار "تذكير جديد" بعرض الشاشة.
class _AddReminderBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddReminderBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 13.h),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.30), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 19.sp, color: Colors.white),
            SizedBox(width: 7.w),
            Text('تذكير جديد', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
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
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 110.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(
                    'كل عملية بتعملها بتتسجل هنا (${list.length})',
                    style: TextStyle(fontSize: 12.sp, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B)),
                  ),
                ),
                if (list.isNotEmpty && state.unreadCount > 0)
                  TextButton(
                    onPressed: () => context.read<ActivityCubit>().markAllRead(),
                    child: Text('تعليم كمقروء', style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
                  ),
              ]),
              SizedBox(height: 10.h),
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
