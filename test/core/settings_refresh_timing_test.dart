import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guard against re-introducing the sign-out permission-denied bug:
/// admin_settings / feature_flags reads require a signed-in owner/admin
/// (firestore.rules: signedIn() && (isAdmin() || isOwnerUser())), so they must
/// NEVER be refreshed from the splash/startup path.
void main() {
  test('splash does not refresh settings or flags before sign-in', () {
    final source = File(
      'lib/features/splash/presentation/views/splash_view.dart',
    ).readAsStringSync();

    expect(
      source.contains('AppSettingsService.refresh()'),
      isFalse,
      reason: 'AppSettingsService.refresh() must not run before sign-in',
    );
    expect(
      source.contains('FeatureFlagsService.refresh()'),
      isFalse,
      reason: 'FeatureFlagsService.refresh() must not run before sign-in',
    );
  });
}
