import 'package:flutter/material.dart';
import 'package:hesba/core/theme/app_theme.dart';

/// A single, muted badge for statuses across the whole admin dashboard.
class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({super.key, required this.label, required this.color});

  factory AdminStatusBadge.status(String status) {
    final color = switch (status) {
      'active' => Colors.green,
      'trial' => Colors.blue,
      'pending' => AppTheme.secondaryColor,
      'expired' => Colors.redAccent,
      'rejected' => Colors.grey,
      _ => Colors.grey,
    };
    return AdminStatusBadge(label: status, color: color);
  }

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }
}

/// Empty state with an icon and a friendly (non-technical) message.
Widget adminEmpty(IconData icon, String message) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 48, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text(message, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
      ],
    ),
  );
}

/// Error state with a short message and a retry button (no stack traces).
Widget adminError(String message, VoidCallback onRetry) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 44, color: Colors.redAccent),
          const SizedBox(height: 12),
          const Text('حدث خطأ أثناء تحميل البيانات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    ),
  );
}

/// A lightweight skeleton row for lists (no package dependency).
Widget adminSkeleton(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 12, width: 160, color: Colors.grey[200]),
              const SizedBox(height: 8),
              Container(height: 10, width: 100, color: Colors.grey[200]),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget adminSkeletonList(BuildContext context, {int count = 6}) {
  return ListView.builder(
    itemCount: count,
    itemBuilder: (_, _) => adminSkeleton(context),
  );
}
