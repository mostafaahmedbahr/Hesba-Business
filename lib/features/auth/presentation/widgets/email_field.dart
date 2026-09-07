import 'package:flutter/material.dart';
import 'package:hesba/core/widgets/custom_text_field.dart';
import 'package:hesba/core/utils/validators.dart';

class EmailField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const EmailField({
    super.key,
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      labelText: 'البريد الإلكتروني',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      textDirection: TextDirection.ltr,
      validator: validator ?? Validators.email,
    );
  }
}
