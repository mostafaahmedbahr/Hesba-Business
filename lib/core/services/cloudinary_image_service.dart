import 'dart:async';
import 'dart:convert';

import 'package:cloudinary_flutter/cloudinary_object.dart';
import 'package:cloudinary_url_gen/transformation/delivery/delivery.dart';
import 'package:cloudinary_url_gen/transformation/delivery/delivery_actions.dart';
import 'package:cloudinary_url_gen/transformation/effect/effect.dart';
import 'package:cloudinary_url_gen/transformation/gravity/gravity.dart';
import 'package:cloudinary_url_gen/transformation/resize/resize.dart';
import 'package:cloudinary_url_gen/transformation/transformation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../constants/app_constants.dart';
import '../extensions/log_util.dart';

/// Upload errors with a machine-readable [code] for localized UI messages.
class CloudinaryUploadException implements Exception {
  const CloudinaryUploadException(this.code, [this.details]);

  final String code;
  final String? details;

  @override
  String toString() => 'CloudinaryUploadException($code): $details';
}

/// Picks a shop image and uploads it to Cloudinary.
///
/// Returns the upload's secure URL, or null when the user cancels picking.
/// Only this HTTPS URL is persisted; image bytes never go to Firestore.
class CloudinaryImageService {
  CloudinaryImageService({
    ImagePicker? picker,
    http.Client? client,
    CloudinaryObject? cloudinary,
  }) : _picker = picker ?? ImagePicker(),
       _client = client ?? http.Client(),
       _cloudinary =
           cloudinary ??
           CloudinaryObject.fromCloudName(
             cloudName: AppConstants.cloudinaryCloudName,
           );

  static const String missingConfiguration = 'missing-configuration';
  static const String fileTooLarge = 'file-too-large';
  static const String invalidResponse = 'invalid-response';
  static const String uploadFailed = 'upload-failed';
  static const String presetNotFound = 'preset-not-found';
  static const String uploadRejected = 'upload-rejected';
  static const String invalidFileType = 'invalid-file-type';
  static const int maxImageBytes = 10 * 1024 * 1024;

  /// Extensions the app accepts (anything else is rejected before upload).
  static const _allowedExtensions = {
    'jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'heif',
  };
  static final RegExp _assetVersion = RegExp(r'^v\d+$');

  final ImagePicker _picker;
  final http.Client _client;
  final CloudinaryObject _cloudinary;

/// Eager transformation applied by Cloudinary while uploading: 250x250 crop
/// with auto gravity, the sepia effect, then automatic format and quality.
Transformation get shopImageTransformation =>
      Transformation()
        ..resize(
          Resize.fill()
            ..gravity(Gravity.autoGravity())
            ..width(AppConstants.cloudinaryShopImageSize)
            ..height(AppConstants.cloudinaryShopImageSize),
        )
        ..effect(Effect.sepia())
        ..delivery(Delivery.format(Format.auto))
        ..delivery(Delivery.quality(Quality.auto()));

  /// Opens the native picker and returns the resized/compressed file.
  ///
  /// Callers pick *first* and only then show the uploading state, so no
  /// spinner ever appears while the gallery/camera UI is still open.
  Future<XFile?> pickShopImage({required ImageSource source}) {
    return _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 82,
    );
  }

  /// Uploads an already-picked [file], or picks one from [source] first.
  Future<String?> uploadShopImage({ImageSource? source, XFile? file}) {
    return _upload(
      source: source,
      file: file,
      folder: AppConstants.cloudinaryShopImageFolder,
      preset: AppConstants.cloudinaryUploadPreset,
      verify: true,
    );
  }

  /// Uploads a payment receipt image.
  ///
  /// Same service and preset as the shop photo, but into its own folder and
  /// without the shop's eager transformation so the screenshot stays readable.
  Future<String?> uploadPaymentReceipt({ImageSource? source, XFile? file}) {
    return _upload(
      source: source,
      file: file,
      folder: AppConstants.cloudinaryPaymentProofFolder,
      preset: AppConstants.cloudinaryReceiptUploadPreset,
      verify: false,
    );
  }

  Future<String?> _upload({
    ImageSource? source,
    XFile? file,
    required String folder,
    required String preset,
    required bool verify,
  }) async {
    if (!AppConstants.isCloudinaryConfigured) {
      throw CloudinaryUploadException(
        missingConfiguration,
        'CLOUDINARY_CLOUD_NAME="${AppConstants.cloudinaryCloudName}", '
            'CLOUDINARY_UPLOAD_PRESET="${AppConstants.cloudinaryUploadPreset}"',
      );
    }

    try {
      final picked =
          file ?? (source == null ? null : await pickShopImage(source: source));
      if (picked == null) return null;

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty || bytes.lengthInBytes > maxImageBytes) {
        throw const CloudinaryUploadException(fileTooLarge);
      }
      if (!_isSupportedImage(picked.name, bytes)) {
        throw const CloudinaryUploadException(invalidFileType);
      }

      final uri = Uri.https(
        'api.cloudinary.com',
        '/v1_1/${AppConstants.cloudinaryCloudName}/image/upload',
      );
      // Unsigned uploads reject the transformation parameter, so any crop and
      // effects come from the fixed transformation of the upload preset.
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = preset
        ..fields['folder'] = folder
        ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: picked.name),
        );

      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _uploadError(response);
      }

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        throw const CloudinaryUploadException(invalidResponse);
      }

      final secureUrl = (data['secure_url'] as String?)?.trim();
      final parsed = secureUrl == null ? null : Uri.tryParse(secureUrl);
      if (secureUrl == null ||
          secureUrl.isEmpty ||
          parsed == null ||
          !parsed.isScheme('https')) {
        throw const CloudinaryUploadException(invalidResponse);
      }
      if (verify) {
        _verifyTransformation(data, secureUrl);
      }
      return secureUrl;
    } on CloudinaryUploadException {
      rethrow;
    } on TimeoutException catch (e) {
      throw CloudinaryUploadException(uploadFailed, e.toString());
    } catch (e) {
      throw CloudinaryUploadException(uploadFailed, e.toString());
    }
  }

  /// Turns a Cloudinary error response into a typed upload error so the UI can
  /// explain what is wrong with the account setup.
CloudinaryUploadException _uploadError(http.Response response) {
    final body = response.body;
    logWarning('Cloudinary upload failed (${response.statusCode}): $body');
    if (body.contains('upload_preset') || body.contains('preset')) {
      return CloudinaryUploadException(presetNotFound, body);
    }
    if (response.statusCode == 400 || response.statusCode == 403) {
      return CloudinaryUploadException(uploadRejected, body);
    }
    return CloudinaryUploadException(uploadFailed, body);
  }

/// Confirms with the Cloudinary SDK that the stored URL is the eager
  /// transformation we asked for, and logs a warning if it was overridden.
  void _verifyTransformation(Map<String, dynamic> data, String secureUrl) {
    final publicId = (data['public_id'] as String?)?.trim();
    if (publicId == null || publicId.isEmpty) return;

    final expected = _cloudinary
        .image(publicId)
        .transformation(shopImageTransformation)
        .toString();
    if (_normalizeDeliveryUrl(expected) != _normalizeDeliveryUrl(secureUrl)) {
      logWarning(
        'Cloudinary returned "$secureUrl" instead of "$expected". Add the '
        'transformation "${shopImageTransformation.toString()}" to upload '
        'preset "${AppConstants.cloudinaryUploadPreset}" to apply it on upload.',
      );
    }
  }

  /// Extension allowlist + magic-byte sniffing, so a renamed binary can
  /// never be uploaded (and billed) as an image.
  bool _isSupportedImage(String name, List<int> bytes) {
    final dot = name.lastIndexOf('.');
    final ext = dot == -1 ? '' : name.substring(dot + 1).toLowerCase();
    if (ext.isNotEmpty && !_allowedExtensions.contains(ext)) return false;
    if (bytes.length < 12) return false;
    // JPEG: FF D8
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return true;
    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }
    // GIF: GIF87a / GIF89a
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return true;
    }
    // WEBP: RIFF....WEBP
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }
    // HEIC/HEIF: ....ftyp
    if (bytes[4] == 0x66 &&
        bytes[5] == 0x74 &&
        bytes[6] == 0x79 &&
        bytes[7] == 0x70) {
      return true;
    }
    return false;
  }

  /// Drops the SDK analytics query and the asset version segment so a built
  /// URL can be compared with the one returned by the upload API.
  String _normalizeDeliveryUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return url.trim();
    return uri
        .replace(
          pathSegments: uri.pathSegments
              .where((segment) => !_assetVersion.hasMatch(segment))
              .toList(),
          query: null,
        )
        .toString();
  }
}
