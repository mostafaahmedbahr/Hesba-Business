import '../models/user_profile.dart';

/// Operations related to the current authenticated user's account.
abstract class AccountRepo {
  /// Returns the current signed-in user id, or null.
  String? currentUserId();

  /// Streams the current user's profile document from Firestore.
  Stream<UserProfile?> watchProfile();

  /// Fetches the profile document once.
  Future<UserProfile?> getProfile();

  /// Updates all editable registration fields.
  ///
  /// Owner fields go to `users/{uid}`, shop fields go to both
  /// `users/{uid}` (profile view) and `shops/{shopId}` (shop features).
  /// Email/password are NOT editable here (separate secure flows).
  Future<void> updateProfile({
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
  });

  /// Changes the account password (requires recent re-authentication).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Signs out the current user.
  Future<void> logout();
}
