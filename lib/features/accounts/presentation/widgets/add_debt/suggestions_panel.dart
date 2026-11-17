import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../data/models/person_model.dart';
import 'person_type_chip.dart';

/// لوحة الاقتراحات أسفل حقلي الاسم/الرقم في «إضافة مديونية».
class AddDebtSuggestionsPanel extends StatelessWidget {
  final List<PersonModel> persons;
  final bool isDark;
  final ValueChanged<PersonModel> onSelect;

  const AddDebtSuggestionsPanel({
    super.key,
    required this.persons,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (persons.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.canvasLight,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.person_add_alt_1_rounded,
                size: 15.sp, color: AppTheme.primaryColor),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'شخص جديد — سيُحفظ اسمه ورقمه للاستخدام مستقبلًا',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slateGray,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceAlt : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft,
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 4.h),
            child: Row(
              children: [
                Icon(Icons.history_rounded,
                    size: 12.sp, color: AppTheme.mutedGray),
                SizedBox(width: 5.w),
                Text(
                  'مسجّلون من قبل — اختر بدلًا من الكتابة',
                  style: TextStyle(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.mutedGray,
                  ),
                ),
              ],
            ),
          ),
          ...persons.map(
            (p) => InkWell(
              onTap: () => onSelect(p),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16.r,
                      backgroundColor: AppTheme.primarySoft,
                      child: Text(
                        p.name.trim().isEmpty
                            ? '؟'
                            : p.name.trim().substring(0, 1),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppTheme.ink,
                            ),
                          ),
                          Text(
                            p.phone,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.slateGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AddDebtPersonTypeChip(type: p.type),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }
}
