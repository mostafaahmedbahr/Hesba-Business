import '../../../../common_imports.dart';

/// زرار حفظ البيع (gradient + ظل).
class AddSaleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;

  const AddSaleButton({
    super.key,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: FilledButton(
          onPressed: loading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          ),
          child: loading
              ? SizedBox(
                  height: 22.w,
                  width: 22.w,
                  child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 20.sp, color: Colors.white),
                    SizedBox(width: 8.w),
                    Text('حفظ البيع', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: Colors.white)),
                  ],
                ),
        ),
      ),
    );
  }
}
