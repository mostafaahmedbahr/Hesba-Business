import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/app_constants.dart';
import 'package:hesba/core/services/app_logger.dart';

/// مصدر واحد لمعرفة "مين المستخدم الحالي؟" — يُستخدم لتوجيه الموظف
/// لشاشة الإدخال المقيّدة بدل الواجهة الكاملة، ولحظر المسارات الحساسة.
///
/// القيمة تُخزَّن مؤقتًا في الذاكرة عشان الـ router (اللي متزامن) يقدر
/// يسأل عنها فورًا. تُحدَّث عند الدخول/الخروج وعند فتح التطبيق.
///
/// أمان — "فشل القراءة ≠ مالك":
/// لو قراءة مستند المستخدم فشلت (أوفلاين / rules / timeout) ولم يكن
/// هناك دور مخزّن في هذه الجلسة، لا نفترض أي دور (وبالتأكيد ليس مالك).
/// [isLoaded] تبقى false و [loadFailed] تصبح true، والـ router يعيد
/// التوجيه لشاشة البداية بدل فتح مسارات المالك على حساب موظف حقيقي.
/// الدور الغائب من المستند نفسه (legacy بدون حقل role) يبقى يعني مالك
/// كما كانت الحال — ذلك سلوك مقصود للتوافق مع الحسابات القديمة.
class UserRoleService {
  UserRoleService({required this._auth, required this._firestore});

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String? _role;
  String? _ownerId;
  String? _shopId;
  String? _shopName;
  String? _uidForCache;
  bool _loadFailed = false;

  /// null = لم يُحدد بعد (مستخدم مش مسجّل دخول، أو فشل التحميل، أو لم تُقرأ البيانات).
  String? get role => _role;
  bool get isStaff => _role == AppConstants.roleStaff;
  bool get isOwner => _role == AppConstants.roleOwner;
  bool get isAdmin => _role == 'admin';
  bool get isLoaded => _role != null;

  /// true لو آخر محاولة تحميل فشلت. لو في كاش صالح من نفس الجلسة بيفضل —
  /// القراءة المؤقتة لا تسقط الدور المخزّن، بس [loadFailed] بتقول إنها
  /// ما اتجددتش من السيرفر.
  bool get loadFailed => _loadFailed;

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
      // دور غائب عن المستند = مالك (توافق مع الحسابات القديمة بدون role).
      // النقص/الفراغ شيء مقصود؛ الفشل في القراءة شيء مختلف تمامًا (انظر catch).
      _role = (storedRole != null && storedRole.trim().isNotEmpty)
          ? storedRole.trim()
          : AppConstants.roleOwner;
      final linkedOwner = data?['ownerId'] as String?;
      _ownerId = (linkedOwner != null && linkedOwner.isNotEmpty)
          ? linkedOwner
          : uid;
      final shop = data?['shopId'] as String?;
      _shopId = (shop != null && shop.isNotEmpty) ? shop : null;
      // نفس قراءة المستخدم — مفيش طلب إضافي عشان اسم المحل.
      _shopName = data?['shopName'] as String?;
      _uidForCache = uid;
      _loadFailed = false;
    } catch (logErr, logSt) {
      AppLogger.nonFatal('core/services/user_role_service.dart', logErr, logSt, severity: LoggingSeverity.warning);
      if (_uidForCache == uid && _role != null) {
        // انقطاع مؤقت — نكمّل بالدور المخزّن من نفس الجلسة ولا نخترع دورًا جديدًا.
        _loadFailed = true;
        return;
      }
      // مفيش دور معروف: لا مالك ولا موظف. الـ router يعامل ده كـ "غير معروف"
      // ويرجّع التوجيه للبداية بدل فتح مسارات المالك.
      _role = null;
      _ownerId = null;
      _shopId = null;
      _shopName = null;
      _uidForCache = null;
      _loadFailed = true;
    }
  }

  Future<void> reload() => load(refresh: true);

  void clear() {
    _role = null;
    _ownerId = null;
    _shopId = null;
    _shopName = null;
    _uidForCache = null;
    _loadFailed = false;
  }

  /// معرّف المحل من قراءة المستخدم الوحيدة عند الدخول.
  String? get cachedShopId => _shopId;

  /// uid اللي اتحمل له الكاش — بيمنع استخدام كاش حساب سابق بعد تبديل الحساب.
  String? get cachedUid => _uidForCache;

  /// اسم المحل من نفس القراءة (للحالات اللي محتاجة الاسم كمان).
  String? get cachedShopName => _shopName;
}
