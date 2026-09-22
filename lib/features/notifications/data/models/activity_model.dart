import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType { sale, saleUpdate, saleDelete, productAdd, productUpdate, productDelete, returnAdd, expenseAdd, expenseUpdate, expenseDelete, generic }

extension ActivityTypeX on ActivityType {
  String get label {
    switch (this) {
      case ActivityType.sale: return 'sale';
      case ActivityType.saleUpdate: return 'saleUpdate';
      case ActivityType.saleDelete: return 'saleDelete';
      case ActivityType.productAdd: return 'productAdd';
      case ActivityType.productUpdate: return 'productUpdate';
      case ActivityType.productDelete: return 'productDelete';
      case ActivityType.returnAdd: return 'returnAdd';
      case ActivityType.expenseAdd: return 'expenseAdd';
      case ActivityType.expenseUpdate: return 'expenseUpdate';
      case ActivityType.expenseDelete: return 'expenseDelete';
      case ActivityType.generic: return 'generic';
    }
  }

  static ActivityType fromString(String s) {
    return ActivityType.values.firstWhere((e) => e.label == s, orElse: () => ActivityType.generic);
  }
}

class ActivityModel {
  final String id;
  final ActivityType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  const ActivityModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });

  ActivityModel copyWith({bool? isRead}) {
    return ActivityModel(
      id: id, type: type, title: title, body: body, createdAt: createdAt, isRead: isRead ?? this.isRead);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.label,
    'title': title,
    'body': body,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'isRead': isRead,
  };

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as String? ?? '',
      type: ActivityTypeX.fromString(json['type'] as String? ?? 'generic'),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: json['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}
