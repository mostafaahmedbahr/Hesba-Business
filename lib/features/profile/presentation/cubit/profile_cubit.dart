import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repos/account_repo.dart';
import '../states/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final AccountRepo _repo;

  ProfileCubit({required AccountRepo repo})
      : _repo = repo,
        super(const ProfileState());

  void loadProfile() {
    emit(state.copyWith(status: ProfileStatus.loading));
    _repo.watchProfile().listen((profile) {
      if (!isClosed) {
        emit(ProfileState(status: ProfileStatus.success, profile: profile));
      }
    }, onError: (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: e.toString(),
        ));
      }
    });
  }

  Future<String?> updateProfile({
    required String ownerName,
    required String phone,
  }) async {
    try {
      await _repo.updateProfile(ownerName: ownerName, phone: phone);
      return null;
    } catch (e) {
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
    } catch (e) {
      return _mapError(e);
    }
  }

  Future<bool> logout() async {
    try {
      await _repo.logout();
      return true;
    } catch (e) {
      print('[ProfileCubit] logout failed: $e');
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
    if (msg.contains('network-request-failed')) return 'تحقق من اتصال الإنترنت';
    return msg;
  }
}
