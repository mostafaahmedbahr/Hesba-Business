import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hesba/core/theme/app_theme.dart';

import 'admin_ui.dart';

class ActivityView extends StatelessWidget {
  const ActivityView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('activity_logs')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return adminSkeletonList(context);
        }
        if (snapshot.hasError) {
          return adminError(snapshot.error.toString(), () {
            // The stream re-emits on next snapshot; no re-fetch needed.
          });
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return adminEmpty(Icons.history, 'لا يوجد نشاط بعد');
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data();
            final action = d['action'] as String? ?? '';
            final desc = d['description'] as String? ?? '';
            final createdAt = d['createdAt'];
            DateTime? date;
            if (createdAt is Timestamp) date = createdAt.toDate();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _colorFor(action).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_iconFor(action), color: _colorFor(action), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _labelFor(action),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(desc, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          if (d['userId'] != null || docs[i].id.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${d['userId'] != null ? 'المستخدم: ${d["userId"]}  •  ' : ''}#${docs[i].id.length > 8 ? docs[i].id.substring(0, 8) : docs[i].id}',
                              style: TextStyle(color: Colors.grey[400], fontSize: 10),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            date == null ? '' : _format(date),
                            style: TextStyle(color: Colors.grey[400], fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _iconFor(String action) {
    if (action.contains('approved')) return Icons.verified;
    if (action.contains('rejected')) return Icons.cancel_outlined;
    if (action.contains('sale')) return Icons.point_of_sale;
    if (action.contains('expense')) return Icons.money_off;
    if (action.contains('product')) return Icons.inventory_2_outlined;
    if (action.contains('shop')) return Icons.storefront_outlined;
    return Icons.history;
  }

  Color _colorFor(String action) {
    if (action.contains('approved')) return Colors.green;
    if (action.contains('rejected')) return Colors.redAccent;
    if (action.contains('sale')) return Colors.indigo;
    if (action.contains('expense')) return Colors.deepOrange;
    if (action.contains('product')) return AppTheme.primaryColor;
    if (action.contains('shop')) return AppTheme.secondaryColor;
    return Colors.blueGrey;
  }

  String _labelFor(String action) {
    if (action == 'subscription_approved') return 'تمت الموافقة على اشتراك';
    if (action == 'subscription_rejected') return 'تم رفض اشتراك';
    return action;
  }

  String _format(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
