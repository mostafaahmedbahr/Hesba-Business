import 'package:flutter/material.dart';

class AddExpenseButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;

  const AddExpenseButton({
    super.key,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const Text('إضافة المصروف'),
      ),
    );
  }
}
