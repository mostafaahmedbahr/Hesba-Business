import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// ملاحظة/شكوى/اقتراح واصل من المستخدم عبر "تواصل معنا".
///
/// المستندات القديمة (قبل إضافة إدارة الملاحظات) مش بيكون فيها `handled`
/// — تُعتبر جديدة افتراضيًا.
class FeedbackEntry {
  const FeedbackEntry({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.type,
    required this.title,
    required this.description,
    required this.handled,
    required this.createdAt,
    required this.handledAt,
  });

  final String id;
  final String userId;
  final String userEmail;

  /// النوع كما هو مخزّن من الفورم: 'feedbackComplaint' | 'feedbackSuggestion' |
  /// 'feedbackNote' | 'feedbackInquiry' | 'feedbackOther'.
  final String type;
  final String title;
  final String description;
  final bool handled;
  final DateTime? createdAt;
  final DateTime? handledAt;

  factory FeedbackEntry.fromMap(String id, Map<String, dynamic> data) {
    return FeedbackEntry(
      id: id,
      userId: data['userId'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      type: data['type'] as String? ?? '',
      title: (data['title'] as String? ?? '').trim(),
      description: (data['description'] as String? ?? '').trim(),
      handled: data['handled'] as bool? ?? false,
      createdAt: _dateOf(data['createdAt']),
      handledAt: _dateOf(data['handledAt']),
    );
  }

  static DateTime? _dateOf(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  /// النوع بالعربي + أيقونة + لون (للوحة الأدمن).
  static (String label, IconData icon, Color color) typeMeta(String type) {
    return switch (type) {
      'feedbackComplaint' => ('شكوى'.tr(), Icons.report_gmailerrorred_outlined, Color(0xFFEF4444)),
      'feedbackSuggestion' => ('اقتراح'.tr(), Icons.lightbulb_outline, Color(0xFF3B82F6)),
      'feedbackNote' => ('ملاحظة'.tr(), Icons.sticky_note_2_outlined, Color(0xFFF59E0B)),
      'feedbackInquiry' => ('استفسار'.tr(), Icons.help_outline, Color(0xFF8B5CF6)),
      'feedbackOther' => ('أخرى'.tr(), Icons.more_horiz, Color(0xFF64748B)),
      _ => ('ملاحظة'.tr(), Icons.sticky_note_2_outlined, Color(0xFF64748B)),
    };
  }
}
