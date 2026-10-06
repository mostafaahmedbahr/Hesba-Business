import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common_imports.dart';
import '../cubit/category_cubit.dart';
import '../cubit/category_state.dart';
import '../../../subscription/presentation/subscription_gate.dart';

/// كارت الإضافة (خانة + زرار).
class CategoryAddCard extends StatefulWidget {
  const CategoryAddCard({super.key});

  @override
  State<CategoryAddCard> createState() => _CategoryAddCardState();
}

/// كنترولر الإضافة + إرسال للـ Cubit.
class _CategoryAddCardState extends State<CategoryAddCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// يبعت الاسم للـ Cubit ويمسح الخانة لو نجح.
  Future<void> _submit() async {
    if (!await SubscriptionGate.ensureCanModify(context)) return;
    HapticFeedback.lightImpact();
    final ok = await context.read<CategoryCubit>().addCategory(_controller.text);
    if (ok && mounted) {
      _controller.clear();
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = context.select<CategoryCubit, bool>(
      (c) => c.state.status == CategoryStatus.loading && c.state.hasShop,
    );
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  gradient: AppTheme.successGradient,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.add_rounded, color: Colors.white, size: 18.sp),
              ),
              SizedBox(width: 10.w),
              Text(
                'قسم جديد',
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Text(
                'يظهر فوراً في المنتج',
                style: TextStyle(fontSize: 10.5.sp, color: const Color(0xFF94A3B8)),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'مثال: إكسسوارات',
                    hintStyle: TextStyle(fontSize: 12.sp, color: const Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide(
                        color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.6),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              SizedBox(
                height: 48.h,
                child: FilledButton(
                  onPressed: isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'إضافة',
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
