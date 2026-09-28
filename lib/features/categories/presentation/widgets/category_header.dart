import '../../../../common_imports.dart';

/// هيدر متدرج (نوع المحل + العدد).
class CategoryHeader extends StatelessWidget {
  final int total;
  final int defaults;
  final int customs;
  final String? businessType;

  const CategoryHeader({
    super.key,
    required this.total,
    required this.defaults,
    required this.customs,
    this.businessType,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 196.h,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      stretch: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'إدارة الأقسام',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D2A86), Color(0xFF1A4FD6), Color(0xFF4A7BFF)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -40.h,
                left: -30.w,
                child: Container(
                  width: 140.w,
                  height: 140.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                bottom: -30.h,
                right: -20.w,
                child: Container(
                  width: 180.w,
                  height: 180.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 44.h, 16.w, 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42.w,
                            height: 42.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Icon(
                              Icons.category_rounded,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  businessType ?? 'المتجر',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'نظّم أقسام منتجاتك بسهولة',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              '$total قسم',
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Expanded(
                            child: CategoryStatPill(
                              icon: Icons.folder_copy_rounded,
                              label: 'المخصصة',
                              value: '$customs',
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: CategoryStatPill(
                              icon: Icons.layers_rounded,
                              label: 'الافتراضية',
                              value: '$defaults',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// رقم صغير جوه الهيدر (أيقونة + عنوان + عدد).
class CategoryStatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const CategoryStatPill({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 15.sp, color: Colors.white),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5.sp,
                    color: Colors.white.withValues(alpha: 0.86),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
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
