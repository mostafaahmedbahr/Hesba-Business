import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/user_role_service.dart';
import '../../../../core/utils/error_message.dart';
import '../../data/repos/account_repo.dart';
import '../states/profile_state.dart';
import 'package:hesba/core/services/app_logger.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final AccountRepo _repo;

  // ignore: prefer_initializing_formals
  ProfileCubit({required this._repo})
      : super(const ProfileState());

  /// قراءة واحدة عند فتح الشاشة / بعد تعديل البروفايل.
  Future<void> loadProfile() async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final profile = await _repo.getProfile();
      if (!isClosed) {
        emit(ProfileState(status: ProfileStatus.success, profile: profile));
      }
    } catch (e, logSt) {
      AppLogger.nonFatal('features/profile/presentation/cubit/profile_cubit.dart', e, logSt, severity: LoggingSeverity.warning);
      if (!isClosed) {
        emit(state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: friendlyError(e),
        ));
      }
    }
  }

  Future<String?> updateProfile({
    required String ownerName,
    required String phone,
    required String shopName,
    required String businessType,
    required String shopPhone,
    required String address,
    required String state,
    required String city,
    required String locationUrl,
    required String shopImageUrl,
    double? latitude,
    double? longitude,
    String locationAddress = '',
  }) async {
    try {
      await _repo.updateProfile(
        ownerName: ownerName,
        phone: phone,
        shopName: shopName,
        businessType: businessType,
        shopPhone: shopPhone,
        address: address,
        state: state,
        city: city,
        locationUrl: locationUrl,
        shopImageUrl: shopImageUrl,
        latitude: latitude,
        longitude: longitude,
        locationAddress: locationAddress,
      );
      // الاسم/رقم المحل اتغيّروا → حدّث كاش الدور عشان ShopResolver وشراء
      // المخزون ما يستخدموش الاسم القديم.
      await sl<UserRoleService>().reload();
      await loadProfile();
      return null;
    } catch (e, logSt) {
      AppLogger.nonFatal('features/profile/presentation/cubit/profile_cubit.dart', e, logSt, severity: LoggingSeverity.warning);
      return _mapError(e);
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _repo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return null;
    } catch (e, logSt) {
      AppLogger.nonFatal('features/profile/presentation/cubit/profile_cubit.dart', e, logSt, severity: LoggingSeverity.warning);
      return _mapError(e);
    }
  }

  Future<bool> logout() async {
    try {
      await _repo.logout();
      sl<UserRoleService>().clear();
      return true;
    } catch (e, logSt) {
      AppLogger.nonFatal('features/profile/presentation/cubit/profile_cubit.dart', e, logSt, severity: LoggingSeverity.warning);
      return false;
    }
  }

  String _mapError(dynamic error) {
    final msg = error.toString();
    if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
      return 'كلمة المرور الحالية غير صحيحة';
    }
    if (msg.contains('weak-password')) return 'كلمة المرور الجديدة ضعيفة جداً';
    if (msg.contains('requires-recent-login')) {
      return 'يرجى تسجيل الدخول مجدداً ثم المحاولة';
    }
    if (msg.contains('too-many-requests')) return 'محاولات كثيرة، حاول مرة أخرى لاحقاً';
    if (msg.contains('user-not-found') || msg.contains('invalid-email')) {
      return 'تعذر التحقق من الحساب، سجل الدخول مجدداً';
    }
    if (msg.contains('network-request-failed')) return 'تحقق من اتصال الإنترنت';
    return 'تعذر تغيير كلمة المرور، حاول مرة أخرى';
  }
}
