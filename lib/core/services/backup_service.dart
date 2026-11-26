import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';
import 'shop_resolver.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hesba/core/utils/dynamic_text.dart';

/// تصدير نسخة احتياطية كاملة لمحل واحد بصيغة JSON **محايدة** (غير مرتبطة
/// بـ Firestore)، لتصلح للاحتفاظ بها أو لرفعها على أي API أو إعادة رفعها على
/// Firebase عبر سكربت Admin SDK في `tool/restore_backup/`.
///
/// القواعد الذهبية للصيغة:
///  - كل تواريخ Firestore تُخزَّن كـ `{'__type':'timestamp','s':..,'ns':..}`
///    (ثانية + نانوثانية) بدل `Timestamp`، فلا يوجد أي نوع خاص بـ Firestore
///    في الملف، وتُستعاد بنفس الدقة في Node وPython.
///  - المراجع والجغرافيا تُخزَّن كـ wrapper أيضاً، وكل مستند يحفظ مساره
///    الأصلي في `__doc.path` (بما فيه subcollections مثل payments).
///  - معرّف المستند الأصلي محفوظ، فإعادة الرفع بنفس الـ id + merge لا تكرّر
///    أي سجل ولا تغيّر تواريخه.
class BackupService {
  BackupService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required ShopResolver shopResolver,
  })  : _firestore = firestore,
        _auth = auth,
        _shopResolver = shopResolver;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ShopResolver _shopResolver;

  /// الكولكشنز الخاصة بالمحل. الترتيب مش مهم للاستعادة، بس ثابت عشان العرض.
  static const List<String> _shopCollections = <String>[
    AppConstants.productsCollection,
    AppConstants.salesCollection,
    AppConstants.returnsCollection,
    AppConstants.expensesCollection,
    AppConstants.stockPurchasesCollection,
    AppConstants.stockMovementsCollection,
    AppConstants.suppliersCollection,
    AppConstants.personsCollection,
    AppConstants.debtsCollection,
  ];

  Future<BackupResult> exportCurrentShop() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw BackupException('لازم تسجّل الدخول أولاً.'.tr());

    final shopId = await _shopResolver.getShopId();
    if (shopId == null || shopId.isEmpty) {
      throw BackupException('تعذر تحديد المحل الحالي. أعد فتح التطبيق.'.tr());
    }

    final docs = <Map<String, dynamic>>[];
    final counts = <String, int>{};
    final debtIds = <String>[];
    var fromCache = false;

    Future<void> addShopCollection(String name) async {
      final snap = await _guard(
        name,
        () => _firestore
            .collection(name)
            .where('shopId', isEqualTo: shopId)
            .get(),
      );
      fromCache = fromCache || snap.metadata.isFromCache;
      for (final doc in snap.docs) {
        docs.add(_encodeDoc(doc.reference.path, doc.data()));
        if (name == AppConstants.debtsCollection) debtIds.add(doc.id);
      }
      counts[name] = snap.docs.length;
    }

    Future<void> addSingle(String path) async {
      final snap = await _guard(path, () => _firestore.doc(path).get());
      fromCache = fromCache || snap.metadata.isFromCache;
      if (!snap.exists || snap.data() == null) return;
      docs.add(_encodeDoc(snap.reference.path, snap.data()!));
      counts[path] = 1;
    }

    for (final name in _shopCollections) {
      await addShopCollection(name);
    }

    // حركات الدفع subcollections — نقرأها من معرّفات الذمم اللي لقيناها،
    // عشان نتفادى collection group index غير موجود على المشروع.
    var paymentCount = 0;
    for (final debtId in debtIds) {
      final payments = await _guard(
        'حركات الدفع'.tr(),
        () => _firestore
            .collection(AppConstants.debtsCollection)
            .doc(debtId)
            .collection(AppConstants.debtPaymentsSubCollection)
            .get(),
      );
      fromCache = fromCache || payments.metadata.isFromCache;
      for (final doc in payments.docs) {
        docs.add(_encodeDoc(doc.reference.path, doc.data()));
      }
      paymentCount += payments.docs.length;
    }
    counts['debts/${AppConstants.debtPaymentsSubCollection}'] = paymentCount;

    // المستخدمون: قواعد Firestore بتسمح لصاحب المحل يقرأ مستند حسابه هو
    // (myUid == userId) ومستندات موظفيه بس لو الاستعلام مقيد بـ ownerId + role.
    // الاستعلام بـ shopId لوحده بترفضه القواعد → permission-denied.
    final ownerDoc = await _guard(
      'بيانات الحساب'.tr(),
      () => _firestore.collection(AppConstants.usersCollection).doc(uid).get(),
    );
    fromCache = fromCache || ownerDoc.metadata.isFromCache;
    var userCount = 0;
    if (ownerDoc.exists && ownerDoc.data() != null) {
      docs.add(_encodeDoc(ownerDoc.reference.path, ownerDoc.data()!));
      userCount++;
    }

    final staff = await _guard(
      'الحسابات الفرعية'.tr(),
      () => _firestore
          .collection(AppConstants.usersCollection)
          .where('ownerId', isEqualTo: uid)
          .where('role', isEqualTo: AppConstants.roleStaff)
          .get(),
    );
    fromCache = fromCache || staff.metadata.isFromCache;
    for (final user in staff.docs) {
      docs.add(_encodeDoc(user.reference.path, user.data()));
    }
    userCount += staff.docs.length;
    counts[AppConstants.usersCollection] = userCount;

    // الاشتراكات: القواعد بتسمح للعميل يقرأ اشتراكه هو فقط. قراءة اشتراك
    // حساب فرعي من حساب صاحب المحل مرفوضة، فبنكتفي باشتراك صاحب المحل.
    await addSingle('${AppConstants.usersCollection}/$uid/subscription/current');
    await addSingle('subscriptions/$uid');

    await addSingle('${AppConstants.shopsCollection}/$shopId');

    final requests = await _guard(
      'طلبات الاشتراك'.tr(),
      () => _firestore
          .collection('subscription_requests')
          .where('userId', isEqualTo: uid)
          .get(),
    );
    fromCache = fromCache || requests.metadata.isFromCache;
    for (final doc in requests.docs) {
      docs.add(_encodeDoc(doc.reference.path, doc.data()));
    }
    counts['subscription_requests'] = requests.docs.length;

    await addSingle('admin_settings/settings');

    final exportedAt = DateTime.now().toUtc();
    final stamp = exportedAt.toIso8601String().replaceAll(':', '-');
    final envelope = <String, dynamic>{
      'format': 'hesba-shop-backup',
      'schemaVersion': 1,
      'app': 'hesba',
      'exportedAt': exportedAt.toIso8601String(),
      'shopId': shopId,
      'ownerUid': uid,
      'fromCache': fromCache,
      'counts': counts,
      'docs': docs,
    };

    final jsonBytes = utf8.encode(jsonEncode(envelope));
    final dir = await _backupDirectory();
    final baseName = 'hesba_${_safeName(shopId)}_$stamp';
    final jsonFile = File('${dir.path}${Platform.pathSeparator}$baseName.json');
    final gzipFile =
        File('${dir.path}${Platform.pathSeparator}$baseName.json.gz');

    await jsonFile.writeAsBytes(jsonBytes, flush: true);
    await gzipFile.writeAsBytes(gzip.encode(jsonBytes), flush: true);

    return BackupResult(
      filePath: jsonFile.path,
      gzipPath: gzipFile.path,
      sizeBytes: gzipFile.lengthSync(),
      docCount: docs.length,
      counts: counts,
      shopId: shopId,
      fromCache: fromCache,
      exportedAt: exportedAt,
    );
  }

  Future<List<BackupFile>> listBackups() async {
    final dir = await _backupDirectory();
    if (!dir.existsSync()) return const <BackupFile>[];
    final files = dir
        .listSync()
        .whereType<File>()
        .where(
          (f) => f.path.endsWith('.json') || f.path.endsWith('.json.gz'),
        )
        .map(
          (f) => BackupFile(
            name: f.uri.pathSegments.last,
            path: f.path,
            sizeBytes: f.lengthSync(),
            modified: f.statSync().modified.toLocal().toString().substring(0, 16),
          ),
        )
        .toList()
      ..sort((a, b) => b.name.compareTo(a.name));
    return files;
  }

  Future<Directory> _backupDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}${Platform.pathSeparator}backups');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// يحوّل رفض الصلاحية من رسالة عامة إلى رسالة بتقول الداتا المطلوبة،
  /// عشان العميل/المطوّر يعرف سبب الفشل من غير فتح الـ console.
  Future<T> _guard<T>(String label, Future<T> Function() read) async {
    try {
      return await read();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw BackupException(
          uiTr('الصلاحية مرفوضة عند قراءة $label. تأكد أنك صاحب المحل وأن الاشتراك مفعّل.'),
        );
      }
      rethrow;
    }
  }

  String _safeName(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  Map<String, dynamic> _encodeDoc(String path, Map<String, dynamic> data) =>
      <String, dynamic>{
        '__doc': <String, dynamic>{'path': path},
        'data': _encodeValue(data),
      };

  Object? _encodeValue(Object? value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is Timestamp) {
      return <String, dynamic>{
        '__type': 'timestamp',
        's': value.seconds,
        'ns': value.nanoseconds,
      };
    }
    if (value is DateTime) {
      final micros = value.microsecondsSinceEpoch;
      final seconds = (micros / 1000000).floor();
      return <String, dynamic>{
        '__type': 'timestamp',
        's': seconds,
        'ns': (micros - seconds * 1000000) * 1000,
      };
    }
    if (value is DocumentReference) {
      return <String, dynamic>{
        '__type': 'ref',
        'path': value.path,
      };
    }
    if (value is GeoPoint) {
      return <String, dynamic>{
        '__type': 'geo',
        'lat': value.latitude,
        'lng': value.longitude,
      };
    }
    if (value is Map) {
      return value.map(
        (key, child) => MapEntry<String, Object?>(
          key.toString(),
          _encodeValue(child),
        ),
      );
    }
    if (value is Iterable) {
      return value.map(_encodeValue).toList();
    }
    // أي نوع مش متوقع (مثلاً FieldValue) ما ينكتبش في الملف بدل ما يكسره.
    return null;
  }
}

class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupResult {
  const BackupResult({
    required this.filePath,
    required this.gzipPath,
    required this.sizeBytes,
    required this.docCount,
    required this.counts,
    required this.shopId,
    required this.fromCache,
    required this.exportedAt,
  });

  final String filePath;
  final String gzipPath;
  final int sizeBytes;
  final int docCount;
  final Map<String, int> counts;
  final String shopId;
  final bool fromCache;
  final DateTime exportedAt;
}

class BackupFile {
  const BackupFile({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.modified,
  });

  final String name;
  final String path;
  final int sizeBytes;
  final String modified;
}
