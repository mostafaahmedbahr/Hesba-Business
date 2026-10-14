import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/cloudinary_image_service.dart';
import '../theme/app_theme.dart';

/// Shows the shared gallery/camera chooser as a calm bottom sheet.
///
/// [titleKey] only changes the sheet's heading, so receipts can reuse the same
/// picker without asking for it again.
Future<ImageSource?> pickShopImageSource(
  BuildContext context, {
  String titleKey = 'shopImageSource',
}) {
  final supportsCamera =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7DEE9),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              titleKey.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _SourceCard(
                  icon: Icons.photo_library_outlined,
                  label: 'shopImageGallery'.tr(),
                  onTap: () =>
                      Navigator.pop(sheetContext, ImageSource.gallery),
                ),
                const SizedBox(width: 12),
                if (supportsCamera)
                  _SourceCard(
                    icon: Icons.photo_camera_outlined,
                    label: 'shopImageCamera'.tr(),
                    onTap: () =>
                        Navigator.pop(sheetContext, ImageSource.camera),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: Text(
                  'cancel'.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// One of the two big choices in the source sheet (gallery / camera).
class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE4ECF7)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 22, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Maps a Cloudinary upload failure to a localized user-facing message.
String shopImageUploadErrorMessage(CloudinaryUploadException error) {
  return switch (error.code) {
    CloudinaryImageService.missingConfiguration => 'shopImageMissingConfig'.tr(),
    CloudinaryImageService.fileTooLarge => 'shopImageTooLarge'.tr(),
    CloudinaryImageService.invalidResponse => 'shopImageInvalid'.tr(),
    CloudinaryImageService.presetNotFound => 'shopImagePresetNotFound'.tr(),
    CloudinaryImageService.uploadRejected => 'shopImageUploadRejected'.tr(),
    CloudinaryImageService.invalidFileType => 'shopImageInvalidType'.tr(),
    _ => 'shopImageFailed'.tr(),
  };
}
