import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RegisterPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;

  final String? Function(String?)? validator;

  const RegisterPasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(14.r),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}