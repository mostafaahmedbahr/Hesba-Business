import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/di/service_locator.dart';
import '../../../../../core/services/cloudinary_image_service.dart';
import '../../../../../core/utils/shop_image_upload.dart';
import '../../../../../core/utils/toast.dart';
import '../../../../../core/widgets/shop_image_picker.dart';
import 'register_section_title.dart';
import 'register_text_field.dart';

class RegisterExtraStep extends StatefulWidget {
  final TextEditingController locationUrlController;
  final TextEditingController shopImageUrlController;

  const RegisterExtraStep({
    super.key,
    required this.locationUrlController,
    required this.shopImageUrlController,
  });

  @override
  State<RegisterExtraStep> createState() => _RegisterExtraStepState();
}

class _RegisterExtraStepState extends State<RegisterExtraStep> {
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegisterSectionTitle(
          title: 'extraTitle'.tr(),
          subtitle: 'extraSubtitle'.tr(),
        ),
        SizedBox(height: 24.h),
        _buildInfoCard(),
        SizedBox(height: 18.h),
        _buildLocationField(),
        SizedBox(height: 14.h),
        _buildImageField(),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFE4ECF7)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.storefront_rounded,
            size: 42.sp,
            color: const Color(0xFF0B4D9C),
          ),
          SizedBox(height: 10.h),
          Text(
            'extraCardTitle'.tr(),
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'extraCardDesc'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField() {
    return RegisterTextField(
      controller: widget.locationUrlController,
      label: 'extraLocation'.tr(),
      hint: 'https://maps.app.goo.gl/...',
      icon: Icons.location_on_outlined,
      keyboardType: TextInputType.url,
      validator: _validateUrl,
    );
  }

  Widget _buildImageField() {
    return FormField<String>(
      initialValue: widget.shopImageUrlController.text,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (_) => _validateUrl(widget.shopImageUrlController.text),
      builder: (field) {
        return Column(
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
                  style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFFE11D48)),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Picks a shop photo, uploads it to Cloudinary, and keeps its secure URL.
  Future<void> _choose(FormFieldState<String> field) async {
    if (_uploading) return;
    final source = await pickShopImageSource(context);
    if (source == null || !mounted) return;
    await _upload(field, source);
  }

  /// Blocks step navigation while the upload is in flight.
  Future<void> _upload(FormFieldState<String> field, ImageSource source) async {
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
      imageUrl = await sl<CloudinaryImageService>().uploadShopImage(source: source);
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
