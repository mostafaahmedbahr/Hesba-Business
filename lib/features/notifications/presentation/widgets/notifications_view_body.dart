import 'package:hesba/core/widgets/loading_widget.dart';
import 'package:hesba/features/notifications/presentation/widgets/reminder_card.dart';
import 'package:hesba/features/notifications/presentation/widgets/reminder_empty_state.dart';
import 'package:hesba/features/notifications/presentation/widgets/reminder_enable_banner.dart';
import 'package:hesba/features/notifications/presentation/widgets/reminder_header.dart';
import '../../../../common_imports.dart';
import '../view_model/notification_state.dart';
import '../view_model/notification_cubit.dart';

class NotificationsViewBody extends StatelessWidget {
  const NotificationsViewBody({super.key});

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
                child: LoadingWidget(
                  message: 'جاري تحميل تذكيراتك...',
                ),
              )
            else ...[
              if (!state.permissionGranted)
                SliverToBoxAdapter(
                  child: ReminderEnableBanner(
                    onEnable: () => context
                        .read<NotificationCubit>()
                        .enablePermissions(),
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
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 110.h),
                  sliver: SliverList.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, _) => SizedBox(height: 10.h),
                    itemBuilder: (context, i) {
                      final r = list[i];
                      return ReminderCard(
                        reminder: r,
                        onToggle: () => context
                            .read<NotificationCubit>()
                            .toggleReminderEnabled(r),
                        onTest: () => context.read<NotificationCubit>().testNow(context, r),
                        onEdit: () => context.read<NotificationCubit>().openForm(context, reminder: r),
                        onDelete: () => context.read<NotificationCubit>().confirmDelete(context, r),
                      );
                    },
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}
