import 'dart:math';

/// Generates a stable, collision-resistant idempotency key for one client-side
/// write attempt. Kept by the Cubit for the lifetime of that attempt so a retry
/// after a lost response reuses the SAME document id instead of writing twice.
///
/// No dependency on `uuid` — timestamp + random is sufficient for a single
/// device/shop, and the security rules still scope every write to the shop.
String newRequestId() {
  final random = Random();
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final noise = random.nextInt(1 << 30).toRadixString(36);
  return '${time}_$noise';
}
