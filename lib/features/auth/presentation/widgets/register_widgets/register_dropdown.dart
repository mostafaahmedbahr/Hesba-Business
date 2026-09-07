import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RegisterDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final List<String> items;
  final String? Function(String?)? validator;

  const RegisterDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.items,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final currentValue = controller.text;
    final hasValue = currentValue.isNotEmpty && items.contains(currentValue);

    return DropdownButtonFormField<String>(
      initialValue: hasValue ? currentValue : null,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      borderRadius: BorderRadius.circular(14.r),
      dropdownColor: Colors.white,
      elevation: 4,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 16.h,
        ),
        border: _border(),
        enabledBorder: _border(),
        focusedBorder: _border(color: const Color(0xFF0B4D9C)),
        errorBorder: _border(color: Colors.redAccent),
        focusedErrorBorder: _border(color: Colors.redAccent),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: items.isEmpty
          ? null
          : (value) {
              controller.text = value ?? '';
            },
    );
  }

  OutlineInputBorder _border({Color? color}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: BorderSide(color: color ?? Colors.grey.shade200),
    );
  }
}
