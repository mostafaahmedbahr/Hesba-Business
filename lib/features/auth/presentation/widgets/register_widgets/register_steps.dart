import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../cubit/register_cubit.dart';
import '../../states/register_state.dart';

class RegisterSteps extends StatelessWidget {
  const RegisterSteps({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterCubit, RegisterState>(
      builder: (context, state) {
        return Row(
          children: [
            _step(
              number: 1,
              title: 'حسابك',
              active: state.step >= 0,
            ),
            _line(state.step >= 1),
            _step(
              number: 2,
              title: 'المحل',
              active: state.step >= 1,
            ),
            _line(state.step >= 2),
            _step(
              number: 3,
              title: 'إضافي',
              active: state.step >= 2,
            ),
          ],
        );
      },
    );
  }

  Widget _step({
    required int number,
    required String title,
    required bool active,
  }) {
    return Column(
      children: [
        AnimatedContainer(
          duration:
          const Duration(milliseconds: 250),
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? const Color(0xFF0B4D9C)
                : const Color(0xFFF1F3F6),
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                color: active
                    ? Colors.white
                    : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          title,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _line(bool active) {
    return Expanded(
      child: AnimatedContainer(
        duration:
        const Duration(milliseconds: 250),
        height: 2,
        margin:
        EdgeInsets.symmetric(horizontal: 8.w),
        color: active
            ? const Color(0xFF0B4D9C)
            : const Color(0xFFE8EBEF),
      ),
    );
  }
}