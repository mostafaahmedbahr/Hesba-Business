import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hesba/core/theme/app_theme.dart';

import '../../cubit/register_cubit.dart';
import '../../states/register_state.dart';

/// مؤشر الخطوات الثلاث: الحالية ب-gradient، والمنتهية بعلامة صح،
/// والقادمة بلون هادئ — مع خطوط واصلة تتحرك مع التقدم.
class RegisterSteps extends StatelessWidget {
  const RegisterSteps({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterCubit, RegisterState>(
      builder: (context, state) {
        final current = state.step;
        final titles = [
          'registerStep1'.tr(),
          'registerStep2'.tr(),
          'registerStep3'.tr(),
        ];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < titles.length; i++) ...[
              Expanded(
                child: _StepItem(
                  number: i + 1,
                  title: titles[i],
                  status: i < current
                      ? _StepStatus.done
                      : (i == current ? _StepStatus.current : _StepStatus.upcoming),
                ),
              ),
              if (i < titles.length - 1)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 3,
                  width: 26.w,
                  margin: EdgeInsets.only(top: 17.h, bottom: 20.h),
                  decoration: BoxDecoration(
                    color: i < current
                        ? AppTheme.successColor
                        : const Color(0xFFE8ECF3),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

enum _StepStatus { done, current, upcoming }

class _StepItem extends StatelessWidget {
  final int number;
  final String title;
  final _StepStatus status;

  const _StepItem({
    required this.number,
    required this.title,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final done = status == _StepStatus.done;
    final current = status == _StepStatus.current;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: current
                ? AppTheme.primaryGradient
                : (done ? AppTheme.successGradient : null),
            color: (!current && !done) ? const Color(0xFFEFF2F7) : null,
            boxShadow: current
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.32),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
            border: (!current && !done)
                ? Border.all(color: const Color(0xFFE2E8F0))
                : null,
          ),
          child: Center(
            child: done
                ? Icon(Icons.check_rounded, size: 20.sp, color: Colors.white)
                : Text(
                    '$number',
                    style: TextStyle(
                      color: current ? Colors.white : Colors.grey.shade500,
                      fontWeight: FontWeight.w900,
                      fontSize: 14.sp,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 7.h),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5.sp,
            fontWeight: current ? FontWeight.w900 : FontWeight.w600,
            color: current
                ? AppTheme.primaryColor
                : (done ? AppTheme.successDark : Colors.grey.shade400),
          ),
        ),
      ],
    );
  }
}
