import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductDetailsView extends StatelessWidget {
  const ProductDetailsView({super.key, required this.data, required this.id});

  final Map<String, dynamic> data;
  final String id;

  String _date(dynamic v) {
    if (v == null) return '-';
    if (v is Timestamp) return v.toDate().toString().substring(0, 16);
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['imageUrl'] as String? ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(data['name'] as String? ?? 'تفاصيل المنتج')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(imageUrl, height: 200, fit: BoxFit.cover),
            )
          else
            Container(
              height: 140,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFFEBEEFF), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.inventory_2_outlined, size: 56, color: Color(0xFF1A4FD6)),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'] as String? ?? '-', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 12),
                _row('المحل (ID)', data['shopId']),
                _row('التصنيف', data['category']),
                _row('السعر', '${data['price'] ?? 0} ج'),
                _row('الكمية', '${data['stock'] ?? 0}'),
                _row('تاريخ الإضافة', _date(data['createdAt'])),
                _row('آخر تحديث', _date(data['updatedAt'])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value?.toString() ?? '-')),
        ],
      ),
    );
  }
}
