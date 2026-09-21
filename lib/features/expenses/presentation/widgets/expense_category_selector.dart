import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class ExpenseCategorySelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const ExpenseCategorySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value.isEmpty ? null : value,
      decoration: const InputDecoration(
        labelText: 'التصنيف',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category_rounded),
      ),
      items: AppConstants.expenseCategories.map((cat) {
        return DropdownMenuItem(
          value: cat,
          child: Text(cat),
        );
      }).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
