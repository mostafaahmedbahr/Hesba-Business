import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/service_locator.dart';
import '../../data/repos/account_repo.dart';
import '../cubit/profile_cubit.dart';
import '../states/profile_state.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('البروفايل')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return BlocProvider(
      create: (_) => ProfileCubit(repo: sl<AccountRepo>())..loadProfile(),
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state.status == ProfileStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = state.profile;
          if (profile == null) {
            return const Center(child: Text('لا توجد بيانات'));
          }
          return ListView(
            padding: EdgeInsets.all(20.w),
            children: [
              _buildHeader(context, profile.ownerName, profile.email),
              SizedBox(height: 20.h),
              _ProfileTile(
                icon: Icons.person_rounded,
                label: 'الاسم',
                value: profile.ownerName,
              ),
              _ProfileTile(
                icon: Icons.email_rounded,
                label: 'البريد الإلكتروني',
                value: profile.email,
              ),
              _ProfileTile(
                icon: Icons.storefront_rounded,
                label: 'اسم المحل',
                value: profile.shopName,
              ),
              _ProfileTile(
                icon: Icons.category_rounded,
                label: 'نوع النشاط',
                value: profile.businessType,
              ),
              _ProfileTile(
                icon: Icons.phone_rounded,
                label: 'رقم الهاتف',
                value: profile.phone,
              ),
              _ProfileTile(
                icon: Icons.phone_iphone_rounded,
                label: 'هاتف المحل',
                value: profile.shopPhone,
              ),
              _ProfileTile(
                icon: Icons.location_on_rounded,
                label: 'العنوان',
                value: '${profile.address}، ${profile.city}، ${profile.state}',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String email) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 90.w,
            height: 90.w,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_rounded,
              size: 48.sp,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            name,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            email,
            style: TextStyle(
              fontSize: 13.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
