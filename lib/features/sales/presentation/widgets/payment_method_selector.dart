import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

class PaymentMethodSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const PaymentMethodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  String get _normalized {
    // normalize old 'wallet' value to mobile_wallet
    if (value == 'wallet') return AppConstants.paymentMobileWallet;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: _normalized,
      decoration: const InputDecoration(
        labelText: 'طريقة الدفع',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.payment_rounded),
      ),
      items: AppConstants.paymentMethods.map((m) {
        final v = m['value'] as String;
        final label = m['label'] as String;
        IconData icon;
        switch (v) {
          case AppConstants.paymentCash:
            icon = Icons.money_rounded;
            break;
          case AppConstants.paymentCard:
            icon = Icons.credit_card_rounded;
            break;
          default:
            icon = Icons.account_balance_wallet_rounded;
        }
        return DropdownMenuItem(
          value: v,
          child: Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        );
      }).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
