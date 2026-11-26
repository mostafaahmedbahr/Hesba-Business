import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hesba/core/models/admin_settings.dart';
import 'package:hesba/core/utils/toast.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';
import 'package:hesba/features/subscription/presentation/widgets/payment_brand_logo.dart';

import 'price_decoration.dart';
import 'package:easy_localization/easy_localization.dart';

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

  Color get _brandColor => PaymentBrandLogo.colorOf(method.id);

  @override
  Widget build(BuildContext context) {
    final brandColor = _brandColor;
    final header = Row(
      children: [
        PaymentBrandLogo(id: method.id, size: 38),
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
                'رقم المحفظة / الحساب'.tr(),
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
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.left,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]'))],
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, letterSpacing: 0.4),
      decoration: priceDecoration(context, brandColor).copyWith(
        hintText: '01xxxxxxxxx',
        suffixIcon: controller.text.trim().isEmpty
            ? null
            : IconButton(
                tooltip: 'نسخ الرقم'.tr(),
                icon: const Icon(Icons.copy_rounded, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: controller.text.trim()));
                  AppToast.success(context, 'تم نسخ الرقم'.tr());
                },
              ),
      ),
      validator: (v) {
        final value = (v ?? '').trim();
        if (value.isEmpty) return 'اكتب رقم المحفظة'.tr();
        if (value.replaceAll(RegExp(r'[^0-9]'), '').length < 8) {
          return 'الرقم قصير جدًا'.tr();
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
