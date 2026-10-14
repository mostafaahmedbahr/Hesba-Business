import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';

import '../cubit/shop_location_cubit.dart';
import '../cubit/shop_location_state.dart';
import '../models/shop_location.dart';

/// Interactive map used as an alternative to the GPS button: the shop is
/// pinned by moving the map under the fixed center pin.
///
/// Returns the pinned [ShopLocation] (coordinates only — the address is
/// resolved afterwards by [ShopLocationCubit]) or `null` when cancelled.
class ShopLocationPickerSheet extends StatefulWidget {
  const ShopLocationPickerSheet({super.key, this.initialLocation});

  final ShopLocation? initialLocation;

  /// Shows the picker above [cubit]'s scope.
  ///
  /// The cubit is re-provided on purpose: the dialog route is a sibling of the
  /// page route, so the providers installed on the screen are not ancestors of
  /// the dialog and [context.read] inside it would throw.
  static Future<ShopLocation?> show(
    BuildContext context, {
    required ShopLocationCubit cubit,
    ShopLocation? initialLocation,
  }) {
    return showDialog<ShopLocation>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: ShopLocationPickerSheet(initialLocation: initialLocation),
      ),
    );
  }

  @override
  State<ShopLocationPickerSheet> createState() =>
      _ShopLocationPickerSheetState();
}

class _ShopLocationPickerSheetState extends State<ShopLocationPickerSheet> {
  static const LatLng _fallbackCenter = LatLng(30.0444, 31.2357); // القاهرة
  static const double _pinZoom = 17;

  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng get _initialCenter {
    final location = widget.initialLocation;
    if (location != null && location.hasCoordinates) {
      return LatLng(location.latitude!, location.longitude!);
    }
    return _fallbackCenter;
  }

  void _useCurrentPosition(ShopLocationState state) {
    final location = state.location;
    if (location == null || !location.hasCoordinates || !mounted) return;
    _mapController.move(
      LatLng(location.latitude!, location.longitude!),
      _pinZoom,
    );
  }

  void _confirm() {
    final center = _mapController.camera.center;
    Navigator.pop(
      context,
      ShopLocation(latitude: center.latitude, longitude: center.longitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = (MediaQuery.of(context).size.height - 48).clamp(360.0, 720.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 760.w),
        child: SizedBox(
          height: height,
          child: Column(
            children: [
              _Header(isDark: isDark),
              Expanded(
                child: BlocListener<ShopLocationCubit, ShopLocationState>(
                  listenWhen: (previous, current) =>
                      current.status == ShopLocationStatus.success &&
                      previous.status == ShopLocationStatus.locating,
                  listener: (_, state) => _useCurrentPosition(state),
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(20.r),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // The map itself always behaves as LTR.
                        Directionality(
                          textDirection: ui.TextDirection.ltr,
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _initialCenter,
                              initialZoom: _pinZoom,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.all &
                                    ~InteractiveFlag.rotate,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.zerobugs.hesba',
                              ),
                              const SimpleAttributionWidget(
                                source: Text('OpenStreetMap'),
                                alignment: Alignment.bottomLeft,
                              ),
                            ],
                          ),
                        ),
                        Center(
                          child: Transform.translate(
                            offset: const Offset(0, -22),
                            child: const Icon(
                              Icons.location_pin,
                              size: 44,
                              color: Color(0xFFE11D48),
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16.w,
                          right: 16.w,
                          top: 12.h,
                          child: const _MapHint(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: FilledButton.icon(
                    onPressed: _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0B4D9C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 19),
                    label: Text(
                      'locationMapConfirm'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w800),
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
}

class _Header extends StatelessWidget {
  const _Header({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 8.w, 12.h),
      child: Row(
        children: [
          const Icon(Icons.map_outlined, size: 20, color: Color(0xFF0B4D9C)),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'locationMapTitle'.tr(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () =>
                context.read<ShopLocationCubit>().detectCurrentLocation(),
            icon: const Icon(Icons.my_location, size: 16),
            label: Text(
              'locationMyPosition'.tr(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'dialogCancel'.tr(),
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _MapHint extends StatelessWidget {
  const _MapHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'locationMapHint'.tr(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
