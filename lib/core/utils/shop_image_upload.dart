import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/cloudinary_image_service.dart';

/// Shows the shared gallery/camera chooser for a shop photo.
Future<ImageSource?> pickShopImageSource(BuildContext context) {
  final supportsCamera =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  return showModalBottomSheet<ImageSource>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('shopImageSource'.tr(), style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text('shopImageGallery'.tr()),
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
          ),
          if (supportsCamera)
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('shopImageCamera'.tr()),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
          ListTile(
            leading: const Icon(Icons.close_rounded),
            title: Text('cancel'.tr()),
            onTap: () => Navigator.pop(sheetContext),
          ),
        ],
      ),
    ),
  );
}

/// Maps a Cloudinary upload failure to a localized user-facing message.
String shopImageUploadErrorMessage(CloudinaryUploadException error) {
  return switch (error.code) {
    CloudinaryImageService.missingConfiguration => 'shopImageMissingConfig'.tr(),
    CloudinaryImageService.fileTooLarge => 'shopImageTooLarge'.tr(),
    CloudinaryImageService.invalidResponse => 'shopImageInvalid'.tr(),
    CloudinaryImageService.presetNotFound => 'shopImagePresetNotFound'.tr(),
    CloudinaryImageService.uploadRejected => 'shopImageUploadRejected'.tr(),
    _ => 'shopImageFailed'.tr(),
  };
}
