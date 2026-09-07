import '../models/user_profile.dart';

/// Operations related to the current authenticated user's account.
abstract class AccountRepo {
  /// Returns the current signed-in user id, or null.
  String? currentUserId();

  /// Streams the current user's profile document from Firestore.
  Stream<UserProfile?> watchProfile();

  /// Fetches the profile document once.
  Future<UserProfile?> getProfile();

  /// Updates the editable owner fields on the user document.
  Future<void> updateProfile({
    required String ownerName,
    required String phone,
  });

  /// Changes the account password (requires recent re-authentication).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Signs out the current user.
  Future<void> logout();
}
