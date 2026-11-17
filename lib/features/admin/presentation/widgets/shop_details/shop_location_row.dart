import 'package:flutter/material.dart';
import 'package:hesba/core/models/shop_location.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/core/widgets/dialogs.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hesba/core/services/app_logger.dart';

/// عنوان الموقع + زر فتحه على خرائط جوجل.
///
/// الترتيب: رابط محفوظ صالح ← رابط مبني من الإحداثيات ← بحث بالعنوان النصي
/// ← "لم يتم تحديد موقع المحل" (ما بنعرضش رابط معطوب أبدًا).
class ShopLocationRow extends StatelessWidget {
  const ShopLocationRow({super.key, required this.shop});

  final Map<String, dynamic> shop;

  @override
  Widget build(BuildContext context) {
    final address = _address;
    final latitude = (shop['latitude'] as num?)?.toDouble();
    final longitude = (shop['longitude'] as num?)?.toDouble();

    final url = ShopLocation.resolveMapUrl(
      locationUrl: shop['locationUrl'] as String?,
      latitude: latitude,
      longitude: longitude,
      address: address,
    );

    final String value;
    if (url == null) {
      value = 'لم يتم تحديد موقع المحل';
    } else if (address.isNotEmpty) {
      value = address;
    } else if (latitude != null && longitude != null) {
      value = '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
    } else {
      value = url;
    }

    return Column(
      children: [
        Row(
          children: [
            AdminIconTile(icon: Icons.map_outlined, color: AppTheme.primaryColor, size: 34, iconSize: 18),
            const SizedBox(width: AdminSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الموقع',
                      style: TextStyle(
                          fontSize: 11,
                          color: AdminColors.textSecondary(context),
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 1),
                  Text(value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
        if (url != null) ...[
          const SizedBox(height: AdminSpace.sm),
          SizedBox(
            height: 34,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openMaps(context, url),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 14, color: Colors.white),
              label: const Text(
                'عرض الموقع على Google Maps',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// العنوان: المكتوب يدويًا، وإلا العنوان الناتج من الإحداثيات.
  String get _address {
    final typed = (shop['address'] as String? ?? '').trim();
    if (typed.isNotEmpty) return typed;
    return (shop['locationAddress'] as String? ?? '').trim();
  }

  /// Opens a shop location link on the admin device.
  ///
  /// `url` originates from a shop document the owner can write, so it is
  /// never launched blindly: only https links on known map hosts go through.
  static bool _isSafeMapUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.isScheme('https') || !uri.hasAuthority) {
      return false;
    }
    final host = uri.host.toLowerCase();
    return host == 'google.com' ||
        host.endsWith('.google.com') ||
        host == 'maps.app.goo.gl' ||
        host == 'openstreetmap.org' ||
        host.endsWith('.openstreetmap.org');
  }

  Future<void> _openMaps(BuildContext context, String url) async {
    var opened = false;
    try {
      final uri = Uri.tryParse(url.trim());
      if (uri != null && _isSafeMapUrl(url) && await canLaunchUrl(uri)) {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (logErr, logSt) {
      AppLogger.nonFatal('features/admin/presentation/widgets/shop_details/shop_location_row.dart', logErr, logSt, severity: LoggingSeverity.warning);
      opened = false;
    }
    if (!context.mounted) return;
    if (!opened) {
      AppDialogs.showSnackBar(context, 'تعذر فتح الموقع على خرائط جوجل', isError: true);
    }
  }
}
