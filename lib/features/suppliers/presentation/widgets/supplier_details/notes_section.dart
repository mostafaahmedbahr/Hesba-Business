import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';
import '../supplier_field.dart';
import '../../states/supplier_details_state.dart';
import 'section_card.dart';

/// قسم الملاحظات: حقل نص + زر حفظ، مع مزامنة النص عند تغيّر المورد.
class SupplierNotesSection extends StatefulWidget {
  final SupplierDetailsState state;
  final bool isDark;
  final ValueChanged<String> onSave;
  const SupplierNotesSection({
    super.key,
    required this.state,
    required this.isDark,
    required this.onSave,
  });

  @override
  State<SupplierNotesSection> createState() => _SupplierNotesSectionState();
}

class _SupplierNotesSectionState extends State<SupplierNotesSection> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.state.supplier?.notes ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant SupplierNotesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.state.supplier?.notes ?? '';
    // نحدّث النص فقط لو المورد نفسه اتغيّر (تعديل ناجح من شاشة تانية).
    if (widget.state.supplier?.id != oldWidget.state.supplier?.id ||
        (!_focusNode.hasFocus && next != _controller.text)) {
      _controller.text = next;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final busy = widget.state.busy;
    return SupplierSectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notes_rounded,
                size: 17.sp,
                color: AppTheme.violetDeep,
              ),
              SizedBox(width: 7.w),
              Text(
                'supplierNotesLabel'.tr(),
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppTheme.ink,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            style: TextStyle(fontSize: 13.sp),
            decoration: supplierFieldDecoration(
              context,
              label: 'supplierNotesLabel'.tr(),
              hint: 'supplierNotesHint'.tr(),
              icon: Icons.notes_rounded,
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: FilledButton.icon(
              onPressed: busy ? null : () => widget.onSave(_controller.text),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.violetDeep,
                disabledBackgroundColor: AppTheme.violetDeep.withValues(
                  alpha: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              icon: busy
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 17),
              label: Text(
                'supplierNotesSave'.tr(),
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
