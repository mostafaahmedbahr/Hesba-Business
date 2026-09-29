import '../../../../common_imports.dart';
import '../../../profile/data/repos/account_repo.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/states/profile_state.dart';

class CustomDrawerHeader extends StatelessWidget {
  final bool isDark;
  const CustomDrawerHeader({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit(repo: sl<AccountRepo>())..loadProfile(),
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final profile = state.profile;
          final name = profile?.ownerName ?? '...';
          final email = profile?.email ?? '';
          return Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 16.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D2A86), Color(0xFF1A4FD6), Color(0xFF4A7BFF)],
              ),
              borderRadius: BorderRadiusDirectional.only(bottomEnd: Radius.circular(24.r)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52.w,
                  height: 52.w,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.28))),
                  child: Icon(Icons.person_rounded, color: Colors.white, size: 28.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: Colors.white)),
                      SizedBox(height: 2.h),
                      Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5.sp, color: Colors.white.withValues(alpha: 0.88), fontWeight: FontWeight.w600)),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r)),
                        child: Text('حسبة • Hesba', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}