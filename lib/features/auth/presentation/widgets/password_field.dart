import 'package:flutter/material.dart';
import 'package:hesba/core/widgets/custom_text_field.dart';
import 'package:hesba/core/utils/validators.dart';

class PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final String? Function(String?)? validator;

  const PasswordField({
    super.key,
    required this.controller,
    this.labelText = 'كلمة المرور',
    required this.obscureText,
    required this.onToggleVisibility,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      labelText: labelText,
      prefixIcon: Icons.lock_outlined,
      obscureText: obscureText,
      textDirection: TextDirection.ltr,
      validator: validator ?? Validators.password,
      suffixIcon: IconButton(
        icon: Icon(
          obscureText ? Icons.visibility_off : Icons.visibility,
        ),
        onPressed: onToggleVisibility,
      ),
    );
  }
}
