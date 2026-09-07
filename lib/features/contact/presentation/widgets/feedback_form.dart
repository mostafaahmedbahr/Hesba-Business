import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FeedbackForm extends StatefulWidget {
  final bool submitting;
  final Future<void> Function({
    required String type,
    required String title,
    required String description,
  }) onSubmit;

  const FeedbackForm({
    super.key,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedType = 'شكوى';

  static const _types = ['شكوى', 'اقتراح', 'ملاحظة', 'استفسار', 'أخرى'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 16.r,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type
            _label(theme, 'نوع الرسالة'),
            SizedBox(height: 8.h),
            DropdownButtonFormField<String>(
              value: _selectedType,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              borderRadius: BorderRadius.circular(14.r),
              dropdownColor: theme.colorScheme.surface,
              elevation: 4,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.label_outlined),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
                border: _border(theme),
                enabledBorder: _border(theme),
                focusedBorder: _border(theme, focused: true),
              ),
              items: _types
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedType = v ?? 'شكوى'),
            ),
            SizedBox(height: 16.h),

            // Title
            _label(theme, 'العنوان'),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _titleController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'اكتب عنوان الرسالة' : null,
              decoration: InputDecoration(
                hintText: 'مثال: مشكلة في الفاتورة',
                prefixIcon: const Icon(Icons.title_rounded),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
                border: _border(theme),
                enabledBorder: _border(theme),
                focusedBorder: _border(theme, focused: true),
                errorBorder: _border(theme, error: true),
              ),
            ),
            SizedBox(height: 16.h),

            // Description
            _label(theme, 'الوصف'),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _descController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'اكتب وصف الرسالة' : null,
              decoration: InputDecoration(
                hintText: 'اشرح المشكلة أو الرأي بالتفصيل...',
                alignLabelWithHint: true,
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
                border: _border(theme),
                enabledBorder: _border(theme),
                focusedBorder: _border(theme, focused: true),
                errorBorder: _border(theme, error: true),
              ),
            ),
            SizedBox(height: 20.h),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: widget.submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: widget.submitting
                    ? SizedBox(
                        width: 22.w,
                        height: 22.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'إرسال الرسالة',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(ThemeData theme, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  OutlineInputBorder _border(ThemeData theme, {bool focused = false, bool error = false}) {
    final color = error
        ? const Color(0xFFFF6B6B)
        : focused
            ? theme.colorScheme.primary
            : theme.colorScheme.outline;
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: BorderSide(color: color, width: focused ? 2 : 1),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      type: _selectedType,
      title: _titleController.text,
      description: _descController.text,
    );
  }
}
