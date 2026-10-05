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
  static const int maxImageBytes = 10 * 1024 * 1024;
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

  Future<String?> uploadShopImage({required ImageSource source}) async {
    if (!AppConstants.isCloudinaryConfigured) {
      throw CloudinaryUploadException(
        missingConfiguration,
        'CLOUDINARY_CLOUD_NAME="${AppConstants.cloudinaryCloudName}", '
            'CLOUDINARY_UPLOAD_PRESET="${AppConstants.cloudinaryUploadPreset}"',
      );
    }

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
      );
      if (picked == null) return null;

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty || bytes.lengthInBytes > maxImageBytes) {
        throw const CloudinaryUploadException(fileTooLarge);
      }

      final uri = Uri.https(
        'api.cloudinary.com',
        '/v1_1/${AppConstants.cloudinaryCloudName}/image/upload',
      );
      // Unsigned uploads reject the transformation parameter, so the crop and
      // effects come from the fixed transformation of the upload preset.
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = AppConstants.cloudinaryUploadPreset
        ..fields['folder'] = AppConstants.cloudinaryShopImageFolder
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
      _verifyTransformation(data, secureUrl);
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
