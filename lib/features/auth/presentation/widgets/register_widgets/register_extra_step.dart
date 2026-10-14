import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/di/service_locator.dart';
import '../../../../../core/services/cloudinary_image_service.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/shop_image_upload.dart';
import '../../../../../core/utils/toast.dart';
import '../../../../../core/widgets/shop_image_picker.dart';
import '../../../../../core/widgets/shop_location_field.dart';

class RegisterExtraStep extends StatefulWidget {
  final TextEditingController shopImageUrlController;

  const RegisterExtraStep({
    super.key,
    required this.shopImageUrlController,
  });

  @override
  State<RegisterExtraStep> createState() => _RegisterExtraStepState();
}

class _RegisterExtraStepState extends State<RegisterExtraStep> {
  bool _uploading = false;

  static const _accent = Color(0xFF0B4D9C);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        SizedBox(height: 18.h),
        _buildImageField(),
        SizedBox(height: 12.h),
        _buildLocationField(),
        SizedBox(height: 14.h),
        _buildEditLaterHint(),
      ],
    );
  }

  // ── Header ────────────────────────────────────────────────

  /// Quiet section header: soft icon chip, title and one calm line.
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _softIconChip(Icons.storefront_outlined),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'shopImageSection'.tr(),
                style: TextStyle(
                  fontSize: 16.sp,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                'extraHeroDesc'.tr(),
                style: TextStyle(
                  fontSize: 11.5.sp,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Cards ─────────────────────────────────────────────────

  Widget _buildImageField() {
    return FormField<String>(
      initialValue: widget.shopImageUrlController.text,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (_) => _validateUrl(widget.shopImageUrlController.text),
      builder: (field) {
        return _StepCard(
          icon: Icons.photo_camera_outlined,
          title: 'extraImageTitle'.tr(),
          subtitle: 'extraImageSubtitle'.tr(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShopImagePicker(
                imageUrl: widget.shopImageUrlController.text,
                uploading: _uploading,
                changeLabel: 'shopImageChange'.tr(),
                uploadingLabel: 'shopImageUploading'.tr(),
                onTap: () => _choose(field),
              ),
              if (field.hasError)
                Padding(
                  padding: EdgeInsets.only(top: 8.h, right: 4.w),
                  child: Text(
                    field.errorText!,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE11D48),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationField() {
    return _StepCard(
      icon: Icons.location_on_outlined,
      title: 'locationSectionTitle'.tr(),
      subtitle: 'locationSectionSubtitle'.tr(),
      child: const ShopLocationField(embedded: true, accentColor: _accent),
    );
  }

  /// Quiet one-liner instead of a highlighted banner.
  Widget _buildEditLaterHint() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.tips_and_updates_outlined,
          size: 14,
          color: Colors.grey.shade400,
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            'extraEditLaterHint'.tr(),
            style: TextStyle(
              fontSize: 11.sp,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      ],
    );
  }

  /// Opens the source sheet, then the native picker. No spinner until a file
  /// is actually on its way to Cloudinary.
  Future<void> _choose(FormFieldState<String> field) async {
    if (_uploading) return;
    final source = await pickShopImageSource(context);
    if (source == null || !mounted) return;
    final file =
        await sl<CloudinaryImageService>().pickShopImage(source: source);
    if (file == null || !mounted) return;
    await _upload(field, file);
  }

  /// Blocks step navigation while the upload is in flight.
  Future<void> _upload(FormFieldState<String> field, XFile file) async {
    setState(() => _uploading = true);
    final navigator = Navigator.of(context);
    final dialog = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                const CircularProgressIndicator(),
                SizedBox(width: 16.w),
                Expanded(child: Text('shopImageUploading'.tr())),
              ],
            ),
          ),
        ),
      ),
    );

    String? imageUrl;
    CloudinaryUploadException? failure;
    try {
      imageUrl = await sl<CloudinaryImageService>().uploadShopImage(file: file);
    } on CloudinaryUploadException catch (error) {
      failure = error;
    } finally {
      navigator.pop();
      if (mounted) setState(() => _uploading = false);
    }
    await dialog;

    if (!mounted || !field.mounted) return;
    if (failure != null) {
      AppToast.error(context, shopImageUploadErrorMessage(failure));
      return;
    }
    if (imageUrl == null) return;

    widget.shopImageUrlController.text = imageUrl;
    field.didChange(imageUrl);
    AppToast.success(context, 'shopImageUploaded'.tr());
  }

  static String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'extraFieldEmpty'.tr();
    }
    final url = value.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'extraUrlInvalid'.tr();
    }
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.hasAuthority) {
        return 'extraUrlBad'.tr();
      }
      return null;
    } catch (_) {
      return 'extraUrlBad'.tr();
    }
  }
}

/// Soft tinted square behind a section icon — no gradients, calm palette.
Widget _softIconChip(IconData icon) {
  return Container(
    width: 40.w,
    height: 40.w,
    decoration: BoxDecoration(
      color: AppTheme.primarySoft,
      borderRadius: BorderRadius.circular(13.r),
    ),
    child: Icon(icon, size: 20, color: AppTheme.primaryColor),
  );
}

/// White card with a hairline border and a barely-there shadow: both
/// sections of this step look like one quiet unit.
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFEDF1F7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2B4A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _softIconChip(icon),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }
}
