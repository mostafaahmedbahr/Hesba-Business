import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hesba/core/models/admin_settings.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/core/utils/toast.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';

import 'price_decoration.dart';

/// كارت طريقة دفع واحدة (أيقونة البراند + حقل الرقم + زر النسخ).
class PaymentMethodCard extends StatelessWidget {
  const PaymentMethodCard({
    super.key,
    required this.method,
    required this.controller,
    required this.enabled,
  });

  final AdminPaymentMethod method;
  final TextEditingController controller;
  final bool enabled;

  ({IconData icon, Color color}) get _brand {
    return switch (method.id) {
      'instapay' => (icon: Icons.sync_alt_rounded, color: AppTheme.deepBlue),
      'vodafone_cash' => (
          icon: Icons.smartphone_rounded,
          color: const Color(0xFFE60000),
        ),
      'etisalat_cash' => (
          icon: Icons.wifi_calling_3_rounded,
          color: const Color(0xFF00A651),
        ),
      _ => (
          icon: Icons.account_balance_wallet_outlined,
          color: AppTheme.primaryColor,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final brand = _brand;
    final header = Row(
      children: [
        AdminIconTile(icon: brand.icon, color: brand.color, size: 38, iconSize: 19),
        const SizedBox(width: AdminSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                method.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              Text(
                'رقم المحفظة / الحساب',
                style: TextStyle(
                  fontSize: 10,
                  color: AdminColors.textMuted(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final field = TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]'))],
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, letterSpacing: 0.4),
      decoration: priceDecoration(context, brand.color).copyWith(
        hintText: '01xxxxxxxxx',
        suffixIcon: controller.text.trim().isEmpty
            ? null
            : IconButton(
                tooltip: 'نسخ الرقم',
                icon: const Icon(Icons.copy_rounded, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: controller.text.trim()));
                  AppToast.success(context, 'تم نسخ الرقم');
                },
              ),
      ),
      validator: (v) {
        final value = (v ?? '').trim();
        if (value.isEmpty) return 'اكتب رقم المحفظة';
        if (value.replaceAll(RegExp(r'[^0-9]'), '').length < 8) {
          return 'الرقم قصير جدًا';
        }
        return null;
      },
    );

    return Container(
      padding: const EdgeInsets.all(AdminSpace.md),
      decoration: BoxDecoration(
        color: AdminColors.surfaceAlt(context),
        borderRadius: BorderRadius.circular(AdminRadius.card),
        border: Border.all(color: AdminColors.border(context)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [header, const SizedBox(height: AdminSpace.sm), field],
            );
          }
          return Row(
            children: [
              SizedBox(width: 200, child: header),
              const SizedBox(width: AdminSpace.md),
              Expanded(child: field),
            ],
          );
        },
      ),
    );
  }
}
