import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../cubit/shop_location_cubit.dart';
import '../cubit/shop_location_state.dart';
import '../models/shop_location.dart';
import '../theme/app_theme.dart';
import '../utils/toast.dart';
import 'shop_location_picker_sheet.dart';

/// "تحديد موقع المحل" control shared by registration and profile editing.
///
/// Replaces the old manual Google Maps link field: one tap on the GPS button
/// picks the coordinates, with a map pin and a typed address as alternatives.
/// Requires a [ShopLocationCubit] above it in the tree.
class ShopLocationField extends StatelessWidget {
  const ShopLocationField({super.key, this.isDark = false, this.accentColor});

  final bool isDark;

  /// Button/section accent — registration uses its own blue.
  final Color? accentColor;

  Color get _accent => accentColor ?? AppTheme.primaryColor;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShopLocationCubit, ShopLocationState>(
      listenWhen: (previous, current) =>
          current.messageKey != null &&
          (current.messageKey != previous.messageKey ||
              current.status != previous.status),
      listener: (context, state) => _showMessage(context, state),
      builder: (context, state) => _card(context, state),
    );
  }

  // ── Layout ────────────────────────────────────────────────

  Widget _card(BuildContext context, ShopLocationState state) {
    final cubit = context.read<ShopLocationCubit>();
    final location = state.location;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFE4ECF7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 19, color: _accent),
              SizedBox(width: 8.w),
              Text(
                'locationSectionTitle'.tr(),
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (state.isBusy)
            _busy(state)
          else if (state.hasLocation && location != null)
            _picked(context, cubit, state, location)
          else
            _empty(context, cubit, state),
          if (_notice(state) != null) ...[
            SizedBox(height: 10.h),
            _notice(state)!,
          ],
        ],
      ),
    );
  }

  Widget _busy(ShopLocationState state) {
    final label = state.status == ShopLocationStatus.locating
        ? 'locationPicking'.tr()
        : 'locationGeocoding'.tr();
    return Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _empty(
    BuildContext context,
    ShopLocationCubit cubit,
    ShopLocationState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: FilledButton.icon(
            onPressed: () => cubit.detectCurrentLocation(),
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            icon: const Icon(Icons.my_location, size: 18),
            label: Text(
              'locationPick'.tr(),
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _alternativeButton(
              icon: Icons.map_outlined,
              label: 'locationMapPick'.tr(),
              onPressed: () => _openMap(context, cubit, state),
            ),
            _alternativeButton(
              icon: Icons.edit_location_alt_outlined,
              label: 'locationManualAddress'.tr(),
              onPressed: () => _askAddress(context, cubit, state),
            ),
          ],
        ),
      ],
    );
  }

  Widget _picked(
    BuildContext context,
    ShopLocationCubit cubit,
    ShopLocationState state,
    ShopLocation location,
  ) {
    final hasAddress = location.address.trim().isNotEmpty;
    final coordinates = location.hasCoordinates
        ? '${location.latitude!.toStringAsFixed(5)}, ${location.longitude!.toStringAsFixed(5)}'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppTheme.successColor.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 17,
                    color: AppTheme.successColor,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      hasAddress ? location.address : 'locationPicked'.tr(),
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (coordinates != null) ...[
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(
                      Icons.gps_fixed_outlined,
                      size: 14,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      coordinates,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _alternativeButton(
              icon: Icons.my_location,
              label: 'locationRetry'.tr(),
              onPressed: () => cubit.detectCurrentLocation(),
            ),
            _alternativeButton(
              icon: Icons.map_outlined,
              label: 'locationMapPick'.tr(),
              onPressed: () => _openMap(context, cubit, state),
            ),
            _alternativeButton(
              icon: Icons.edit_location_alt_outlined,
              label: 'locationManualAddress'.tr(),
              onPressed: () => _askAddress(context, cubit, state),
            ),
          ],
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: cubit.clear,
            icon: const Icon(Icons.delete_outline, size: 16),
            label: Text(
              'locationRemove'.tr(),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _alternativeButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final borderColor =
        isDark ? AppTheme.darkBorder : const Color(0xFFD7E1EF);
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: borderColor),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      icon: Icon(icon, size: 15, color: _accent),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.5.sp,
          fontWeight: FontWeight.w700,
          color: _accent,
        ),
      ),
    );
  }

  /// Inline error/warning text (the toast alone disappears too fast).
  Widget? _notice(ShopLocationState state) {
    if (state.messageKey == null) return null;
    if (state.status == ShopLocationStatus.failure) {
      return _noticeRow(
        Icons.error_outline,
        AppTheme.errorColor,
        state.messageKey!.tr(),
      );
    }
    if (state.messageSeverity == ShopLocationMessageSeverity.warning) {
      return _noticeRow(
        Icons.warning_amber_outlined,
        Colors.orange,
        state.messageKey!.tr(),
      );
    }
    return null;
  }

  Widget _noticeRow(IconData icon, Color color, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ── Actions ───────────────────────────────────────────────

  Future<void> _openMap(
    BuildContext context,
    ShopLocationCubit cubit,
    ShopLocationState state,
  ) async {
    final picked = await ShopLocationPickerSheet.show(
      context,
      cubit: cubit,
      initialLocation: state.location,
    );
    if (picked == null || !picked.hasCoordinates) return;
    await cubit.setFromCoordinates(picked.latitude!, picked.longitude!);
  }

  Future<void> _askAddress(
    BuildContext context,
    ShopLocationCubit cubit,
    ShopLocationState state,
  ) async {
    final address = await showDialog<String>(
      context: context,
      builder: (_) => _AddressDialog(
        initialAddress: state.location?.address ?? '',
        accentColor: _accent,
      ),
    );
    if (address == null) return;
    await cubit.setFromAddress(address);
  }

  void _showMessage(BuildContext context, ShopLocationState state) {
    final key = state.messageKey;
    if (key == null) return;
    if (state.messageSeverity == ShopLocationMessageSeverity.error) {
      AppToast.error(context, key.tr());
    } else if (state.messageSeverity == ShopLocationMessageSeverity.warning) {
      AppToast.warning(context, key.tr());
    } else {
      AppToast.success(context, key.tr());
    }
  }
}

/// Dialog for typing the shop address manually.
///
/// The controller lives in the State so it is released when the route is
/// finally torn down (not while the exit animation is still building the
/// `TextField`), and every close path settles focus/the keyboard before the
/// route is popped — popping with a focused `autofocus` field in flight is
/// what triggered "Tried to build dirty widget in the wrong build scope".
class _AddressDialog extends StatefulWidget {
  const _AddressDialog({
    required this.initialAddress,
    required this.accentColor,
  });

  final String initialAddress;
  final Color accentColor;

  @override
  State<_AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<_AddressDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAddress);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Unfocus (closes the keyboard) and wait for the frame to settle before
  /// popping, so no widget of this route is marked dirty after removal.
  Future<void> _dismiss([String? value]) async {
    final navigator = Navigator.of(context);
    FocusManager.instance.primaryFocus?.unfocus();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    navigator.pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'locationDialogTitle'.tr(),
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 2,
        textInputAction: TextInputAction.done,
        onSubmitted: _dismiss,
        decoration: InputDecoration(
          hintText: 'locationDialogHint'.tr(),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _dismiss(),
          child: Text('dialogCancel'.tr()),
        ),
        FilledButton(
          onPressed: () => _dismiss(_controller.text),
          style: FilledButton.styleFrom(backgroundColor: widget.accentColor),
          child: Text('locationAddressConfirm'.tr()),
        ),
      ],
    );
  }
}
