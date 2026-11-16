import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/app_constants.dart';

/// مصدر واحد لمعرفة "مين المستخدم الحالي؟" — يُستخدم لتوجيه الموظف
/// لشاشة الإدخال المقيّدة بدل الواجهة الكاملة، ولحظر المسارات الحساسة.
///
/// القيمة تُخزَّن مؤقتًا في الذاكرة عشان الـ router (اللي متزامن) يقدر
/// يسأل عنها فورًا. تُحدَّث عند الدخول/الخروج وعند فتح التطبيق.
class UserRoleService {
  UserRoleService({required FirebaseAuth auth, required FirebaseFirestore firestore})
      : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String? _role;
  String? _ownerId;
  String? _shopId;
  String? _uidForCache;

  /// null = لم يُحدد بعد (مستخدم مش مسجّل دخول أو لم تُقرأ البيانات).
  String? get role => _role;
  bool get isStaff => _role == AppConstants.roleStaff;
  bool get isOwner => _role == AppConstants.roleOwner;
  bool get isAdmin => _role == 'admin';
  bool get isLoaded => _role != null;

  /// صاحب المحل المرتبط بالحساب (للموظف: uid بتاع صاحب المحل).
  String? get ownerId => _ownerId;

  Future<void> load({bool refresh = false}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      clear();
      return;
    }
    if (!refresh && _role != null && _uidForCache == uid) return;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      final storedRole = data?['role'] as String?;
      _role = (storedRole != null && storedRole.trim().isNotEmpty)
          ? storedRole.trim()
          : AppConstants.roleOwner;
      final linkedOwner = data?['ownerId'] as String?;
      _ownerId = (linkedOwner != null && linkedOwner.isNotEmpty)
          ? linkedOwner
          : uid;
      final shop = data?['shopId'] as String?;
      _shopId = (shop != null && shop.isNotEmpty) ? shop : null;
      _uidForCache = uid;
    } catch (_) {
      // الفشل هنا معناه إن مفيش بيانات دور متاحة — نعتبرها مالك عشان
      // ما نblocksش صاحب المحل لو Firestore كان offline مؤقتًا.
      _role = AppConstants.roleOwner;
      _ownerId = uid;
      _uidForCache = uid;
    }
  }

  Future<void> reload() => load(refresh: true);

  void clear() {
    _role = null;
    _ownerId = null;
    _shopId = null;
    _uidForCache = null;
  }

  String? get cachedShopId => _shopId;
}
