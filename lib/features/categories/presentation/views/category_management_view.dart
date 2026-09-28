import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common_imports.dart';
import '../../data/repos/category_repo.dart';
import '../cubit/category_cubit.dart';
import '../cubit/category_state.dart';
import '../widgets/category_add_card.dart';
import '../widgets/category_custom_section.dart';
import '../widgets/category_defaults_section.dart';
import '../widgets/category_header.dart';
import '../widgets/category_search_field.dart';

/// شاشة الأقسام (عرض بس — اللوجيك في Cubit).
class CategoryManagementView extends StatelessWidget {
  const CategoryManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CategoryCubit(repo: sl<CategoryRepo>())..bootstrap(),
      child: const _CategoryBody(),
    );
  }
}

/// هيكل الشاشة + الـ toasts.
class _CategoryBody extends StatelessWidget {
  const _CategoryBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocConsumer<CategoryCubit, CategoryState>(
        listener: (context, state) {
          if (state.errorMessage != null) AppToast.error(context, state.errorMessage!);
          if (state.successMessage != null) AppToast.success(context, state.successMessage!);
          if (state.errorMessage != null || state.successMessage != null) {
            Future.delayed(const Duration(milliseconds: 800), () {
              if (context.mounted) context.read<CategoryCubit>().clearMessages();
            });
          }
        },
        builder: (context, state) {
          if (state.status == CategoryStatus.initial) return const _LoadingView();
          if (!state.hasShop && state.status == CategoryStatus.failure) {
            return _NoShopView(message: state.errorMessage);
          }
          return _ContentView(state: state);
        },
      ),
    );
  }
}

/// لودر ملء الشاشة.
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('إدارة الأقسام'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36.w,
              height: 36.w,
              child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.primaryColor),
            ),
            SizedBox(height: 12.h),
            Text(
              'جاري تحميل الأقسام...',
              style: TextStyle(fontSize: 12.sp, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// شاشة "مفيش محل".
class _NoShopView extends StatelessWidget {
  final String? message;
  const _NoShopView({this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('إدارة الأقسام'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84.w,
              height: 84.w,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.store_outlined, size: 38.sp, color: AppTheme.primaryColor),
            ),
            SizedBox(height: 14.h),
            Text(
              message ?? 'لم يتم العثور على المتجر',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// المحتوى: هيدر + بحث + إضافة + سكشنين.
class _ContentView extends StatelessWidget {
  final CategoryState state;
  const _ContentView({required this.state});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        CategoryHeader(
          total: state.totalCount,
          defaults: state.defaultCategories.length,
          customs: state.customCategories.length,
          businessType: state.businessType,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
            child: Column(
              children: [
                CategorySearchField(
                  onChanged: (v) => context.read<CategoryCubit>().setSearch(v),
                ),
                SizedBox(height: 12.h),
                const CategoryAddCard(),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
            child: CategoryCustomSection(state: state),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 110.h),
            child: CategoryDefaultsSection(state: state),
          ),
        ),
      ],
    );
  }
}
