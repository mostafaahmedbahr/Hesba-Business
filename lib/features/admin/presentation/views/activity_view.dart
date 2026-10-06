import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ActivityView extends StatelessWidget {
  const ActivityView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('activity_logs')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('لا يوجد نشاط بعد'));
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final d = docs[i].data();
            return ListTile(
              leading: const Icon(Icons.history),
              title: Text(d['action'] as String? ?? ''),
              subtitle: Text(d['description'] as String? ?? ''),
              trailing: Text(d['createdAt'] != null ? (d['createdAt'] as dynamic).toDate().toString().substring(0, 16) : ''),
            );
          },
        );
      },
    );
  }
}
