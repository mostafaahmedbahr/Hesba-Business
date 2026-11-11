import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/paged_fetch.dart';
import '../models/expense_model.dart';
import '../expense_reminder_scheduler.dart';
import '../repos/expenses_repo.dart';

class ExpensesRepoImpl implements ExpensesRepo {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  ExpensesRepoImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  String? get _uid => auth.currentUser?.uid;

  Future<String?> _resolveShopId(String? providedShopId) async {
    if (providedShopId != null && providedShopId.isNotEmpty) return providedShopId;
    if (_uid == null) return null;
    final doc = await firestore.collection('users').doc(_uid).get();
    if (!doc.exists) return null;
    return doc.data()?['shopId'] as String?;
  }

  @override
  Future<String?> getShopId() => _resolveShopId(null);

  Future<String?> _resolveOwnerId(String? providedOwnerId) async {
    if (providedOwnerId != null && providedOwnerId.isNotEmpty) return providedOwnerId;
    return _uid;
  }

  @override
  Future<ExpenseModel> addExpense({
    required String ownerId,
    required String shopId,
    required String shopName,
    required String title,
    required String category,
    required double amount,
    required String note,
    required DateTime date,
    String recurrence = ExpenseModel.recurrenceNone,
    String dueTime = '',
  }) async {
    if (title.trim().isEmpty) throw Exception('عنوان المصروف مطلوب');
    if (amount <= 0) throw Exception('المبلغ يجب أن يكون أكبر من صفر');
    if (category.isEmpty) throw Exception('اختر تصنيف المصروف');

    final resolvedShopId = await _resolveShopId(shopId);
    final resolvedOwnerId = await _resolveOwnerId(ownerId);

    if (resolvedShopId == null || resolvedShopId.isEmpty) {
      throw Exception('لم يتم العثور على المتجر');
    }
    if (resolvedOwnerId == null || resolvedOwnerId.isEmpty) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final isRecurring = recurrence != ExpenseModel.recurrenceNone;
    final time = _parseDueTime(dueTime);
    if (isRecurring && time == null) {
      throw Exception('حدد موعد الاستحقاق (الساعة والدقيقة)');
    }
    final anchorDue = isRecurring
        ? DateTime(date.year, date.month, date.day, time!.hour, time.minute)
        : null;

    final ref = firestore.collection(AppConstants.expensesCollection).doc();
    final expense = ExpenseModel(
      expenseId: ref.id,
      shopName: shopName,
      ownerId: resolvedOwnerId,
      shopId: resolvedShopId,
      title: title.trim(),
      category: category,
      amount: amount,
      note: note.trim(),
      date: date,
      createdAt: DateTime.now(),
      recurrence: recurrence,
      dueTime: dueTime,
      nextDue: anchorDue,
    );

    await ref.set(expense.toJson());
    if (isRecurring) {
      // يولّد أي موعد استحق اليوم (ويعيد جدولة التذكيرات).
      await syncRecurringExpenses();
    }
    return expense;
  }

@override
  Future<ExpenseModel> updateExpense({
    required String expenseId,
    required String ownerId,
    required String shopId,
    required String shopName,
    required String title,
    required String category,
    required double amount,
    required String note,
    required DateTime date,
    String recurrence = ExpenseModel.recurrenceNone,
    String dueTime = '',
  }) async {
    if (title.trim().isEmpty) throw Exception('عنوان المصروف مطلوب');
    if (amount <= 0) throw Exception('المبلغ يجب أن يكون أكبر من صفر');
    if (category.isEmpty) throw Exception('اختر تصنيف المصروف');

    final resolvedShopId = await _resolveShopId(shopId);
    final resolvedOwnerId = await _resolveOwnerId(ownerId);

    if (resolvedShopId == null || resolvedShopId.isEmpty) {
      throw Exception('لم يتم العثور على المتجر');
    }
    if (resolvedOwnerId == null || resolvedOwnerId.isEmpty) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final docRef = firestore.collection(AppConstants.expensesCollection).doc(expenseId);
    final existingSnap = await docRef.get();
    final existingData = existingSnap.data();
    if (!existingSnap.exists || existingData == null) {
      throw Exception('المصروف غير موجود');
    }
    // Ownership check: never touch another shop's document by ID.
    if (existingData['shopId'] != resolvedShopId || existingData['ownerId'] != resolvedOwnerId) {
      throw Exception('غير مصرح بتعديل هذا المصروف');
    }
    final existingCreatedAt = (existingData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final existingRecurrence =
        (existingData['recurrence'] as String?) ?? ExpenseModel.recurrenceNone;
    final existingDueTime = (existingData['dueTime'] as String?) ?? '';

    final isRecurring = recurrence != ExpenseModel.recurrenceNone;
    final time = _parseDueTime(dueTime);
    if (isRecurring && time == null) {
      throw Exception('حدد موعد الاستحقاق (الساعة والدقيقة)');
    }

    // يعيد حساب الموعد القادم فقط لو تغيّرت الجدولة (التكرار / الوقت / التاريخ)
    // — تعديل العنوان أو المبلغ لا يلمس الجدول.
    final scheduleChanged = existingRecurrence != recurrence ||
        existingDueTime != dueTime ||
        (existingData['date'] is Timestamp &&
            ((existingData['date'] as Timestamp).toDate().year != date.year ||
                (existingData['date'] as Timestamp).toDate().month != date.month ||
                (existingData['date'] as Timestamp).toDate().day != date.day));
    DateTime? nextDue;
    if (isRecurring) {
      if (scheduleChanged) {
        nextDue = DateTime(date.year, date.month, date.day, time!.hour, time.minute);
      } else {
        // يحتفظ بالجدول القائم (لو موجود) — أو يبدأ من تاريخ البداية.
        final ts = existingData['nextDue'];
        if (ts is Timestamp) {
          nextDue = ts.toDate();
        } else {
          nextDue = DateTime(date.year, date.month, date.day, time!.hour, time.minute);
        }
      }
    }

    final updated = ExpenseModel(
      expenseId: expenseId,
      shopName: shopName,
      ownerId: resolvedOwnerId,
      shopId: resolvedShopId,
      title: title.trim(),
      category: category,
      amount: amount,
      note: note.trim(),
      date: date,
      createdAt: existingCreatedAt,
      recurrence: recurrence,
      dueTime: dueTime,
      nextDue: nextDue,
    );

    await docRef.update(updated.toJson());
    await syncRecurringExpenses();
    return updated;
  }

  @override
  Future<List<ExpenseModel>> getExpenses({required String shopId}) async {
    final resolvedShopId = await _resolveShopId(shopId);
    // اعرض الكل لو الـ shopId فاضي — يضمن ظهور البيانات حتى لو الحقل مختلف
    Query<Map<String, dynamic>> query = firestore.collection(AppConstants.expensesCollection);
    try {
      if (resolvedShopId != null && resolvedShopId.isNotEmpty) {
        query = query.where('shopId', isEqualTo: resolvedShopId);
      } else if (_uid != null) {
        query = query.where('ownerId', isEqualTo: _uid);
      }
      final snap = await query.orderBy('createdAt', descending: true).limit(500).get();
      return snap.docs.map((d) => ExpenseModel.fromJson(d.data())).toList();
    } catch (_) {
      // fallback بدون index — حمّل الكل وفلتر محلياً (للمالك فقط، أبداً الكل).
      if (_uid == null) throw Exception('يجب تسجيل الدخول أولاً');
      final snap = await firestore.collection(AppConstants.expensesCollection).orderBy('createdAt', descending: true).limit(500).get();
      final all = snap.docs.map((d) => ExpenseModel.fromJson(d.data())).toList();
      if (resolvedShopId != null && resolvedShopId.isNotEmpty) {
        return all.where((e) => e.shopId == resolvedShopId || e.shopId.isEmpty).toList();
      }
      return all.where((e) => e.ownerId == _uid || e.shopId.isEmpty).toList();
    }
  }

  /// يحول الـ snapshot لقائمة مع فلترة محلية حسب المحل.
  /// لا تعرض أبداً بيانات محل آخر: عند غياب التطابق ترجع قائمة فارغة
  /// (مستندات shopId فارغ القديمة تُعرض لصاحبها فقط كتوافق).
  List<ExpenseModel> _toFiltered(
    QuerySnapshot<Map<String, dynamic>> snap,
    String? resolvedShopId,
  ) {
    final all = snap.docs.map((d) => ExpenseModel.fromJson(d.data())).toList();
    if (resolvedShopId != null && resolvedShopId.isNotEmpty) {
      return all.where((e) => e.shopId == resolvedShopId || e.shopId.isEmpty).toList();
    }
    if (_uid != null) {
      return all.where((e) => e.ownerId == _uid || e.shopId.isEmpty).toList();
    }
    return const [];
  }

  @override
  Stream<List<ExpenseModel>> watchExpenses({required String shopId}) async* {
    final resolvedShopId = await _resolveShopId(shopId);
    Query<Map<String, dynamic>> query = firestore.collection(AppConstants.expensesCollection);
    if (resolvedShopId != null && resolvedShopId.isNotEmpty) {
      query = query.where('shopId', isEqualTo: resolvedShopId);
    } else if (_uid != null) {
      query = query.where('ownerId', isEqualTo: _uid);
    }
    try {
      // المحاولة الأساسية (تحتاج composite index).
      await for (final snap
          in query.orderBy('createdAt', descending: true).limit(500).snapshots()) {
        yield _toFiltered(snap, resolvedShopId);
      }
    } catch (_) {
      // الـ index ناقص: fallback لقراءة بدون where + فلترة محلية.
      await for (final snap in firestore
          .collection(AppConstants.expensesCollection)
          .orderBy('createdAt', descending: true)
          .limit(500)
          .snapshots()) {
        yield _toFiltered(snap, resolvedShopId);
      }
    }
  }

  @override
  Future<PagedResult<ExpenseModel>> fetchAllExpenses({required String shopId}) {
    return fetchAllPages<ExpenseModel>(
      idOf: (expense) => expense.expenseId,
      fetchPage: (cursor) async {
        Query<Map<String, dynamic>> query = firestore
            .collection(AppConstants.expensesCollection)
            .where('shopId', isEqualTo: shopId)
            .orderBy('createdAt', descending: true)
            .limit(kReportPageSize);
        if (cursor != null) {
          query = query
              .startAfterDocument(cursor as DocumentSnapshot<Map<String, dynamic>>);
        }
        final snap = await query.get();
        return PageResult<ExpenseModel>(
          items: snap.docs.map((d) => ExpenseModel.fromJson(d.data())).toList(),
          cursor: snap.docs.isEmpty ? null : snap.docs.last,
          hasMore: snap.docs.length >= kReportPageSize,
        );
      },
    );
  }

  @override
  Stream<void> watchLatestExpense({required String shopId}) {
    return firestore
        .collection(AppConstants.expensesCollection)
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map<void>((_) {});
  }

  @override
  Future<void> deleteExpense({required String expenseId, required String shopId}) async {
    final resolvedShopId = await _resolveShopId(shopId);
    if (resolvedShopId == null) throw Exception('لم يتم العثور على المتجر');
    final docRef = firestore.collection(AppConstants.expensesCollection).doc(expenseId);
    final snap = await docRef.get();
    final data = snap.data();
    if (!snap.exists || data == null) throw Exception('المصروف غير موجود');
    if (data['shopId'] != resolvedShopId || (data['ownerId'] as String?) != _uid) {
      throw Exception('غير مصرح بحذف هذا المصروف');
    }
    // لو قالب متكرر — الغاء كل تذكيراته الجدولة.
    if ((data['recurrence'] as String?) != null &&
        (data['recurrence'] as String) != ExpenseModel.recurrenceNone) {
      await ExpenseReminderScheduler.cancelAll(expenseId);
    }
    await docRef.delete();
  }

  @override
  Future<int> syncRecurringExpenses() async {
    final shopId = await _resolveShopId(null);
    if (shopId == null || shopId.isEmpty) return 0;
    final snap = await firestore
        .collection(AppConstants.expensesCollection)
        .where('shopId', isEqualTo: shopId)
        .limit(500)
        .get();

    var created = 0;
    final now = DateTime.now();
    for (final doc in snap.docs) {
      final data = doc.data();
      final recurrence =
          (data['recurrence'] as String?) ?? ExpenseModel.recurrenceNone;
      if (recurrence == ExpenseModel.recurrenceNone) continue;
      if ((data['ownerId'] as String?) == null) continue;
      final template = ExpenseModel.fromJson(data);
      final dueTimeStr = (data['dueTime'] as String?) ?? '';
      final time = _parseDueTime(dueTimeStr);
      var nextDue = template.nextDue;
      if (nextDue == null) {
        final dateTs = data['date'];
        final anchor = dateTs is Timestamp ? dateTs.toDate() : now;
        final t = time ?? const _DueTime(hour: 9, minute: 0);
        nextDue =
            DateTime(anchor.year, anchor.month, anchor.day, t.hour, t.minute);
      }

      // يولّد كل موعد فات — مع تخطي أي موعد سُجّل فعلًا (idempotent).
      var hop = 0;
      var cursor = nextDue;
      while (!cursor.isAfter(now) && hop < 500) {
        hop++;
        final already = await _occurrenceExists(shopId, doc.id, cursor);
        if (!already) {
          final ref = firestore.collection(AppConstants.expensesCollection).doc();
          final occ = ExpenseModel(
            expenseId: ref.id,
            ownerId: data['ownerId'] as String,
            shopId: shopId,
            shopName: data['shopName'] as String? ?? '',
            title: (data['title'] as String?) ?? '',
            category: (data['category'] as String?) ?? '',
            amount: (data['amount'] as num?)?.toDouble() ?? 0,
            note: (data['note'] as String?) ?? '',
            date: cursor,
            createdAt: DateTime.now(),
            generatedFrom: doc.id,
          );
          await ref.set(occ.toJson());
          created++;
        }
        cursor = ExpenseModel.advanceNextDue(cursor, recurrence);
      }
      if (cursor != nextDue || template.nextDue == null) {
        await doc.reference.update({'nextDue': Timestamp.fromDate(cursor)});
      }
      await ExpenseReminderScheduler.reschedule(
        ExpenseModel.fromJson(data).copyWith(nextDue: cursor),
      );
    }
    return created;
  }

  /// هل يوجد مصروف مولّد من القالب [templateId] في [due]؟
  Future<bool> _occurrenceExists(
      String shopId, String templateId, DateTime due) async {
    final snap = await firestore
        .collection(AppConstants.expensesCollection)
        .where('shopId', isEqualTo: shopId)
        .where('generatedFrom', isEqualTo: templateId)
        .where('date', isEqualTo: Timestamp.fromDate(due))
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// يقرأ 'HH:mm' ويرجع (ساعة، دقيقة) أو null لو الصيغة خاطئة.
  _DueTime? _parseDueTime(String value) {
    final parts = value.trim().split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(_toLatinDigits(parts[0]));
    final minute = int.tryParse(_toLatinDigits(parts[1]));
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return _DueTime(hour: hour, minute: minute);
  }

  /// يحول الأرقام العربية الهندية إلى لاتينية.
  String _toLatinDigits(String input) {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const indic = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    var out = input;
    for (var i = 0; i < 10; i++) {
      out = out.replaceAll(arabic[i], '$i').replaceAll(indic[i], '$i');
    }
    return out;
  }
}

/// وقت الاستحقاق (ساعة/دقيقة) — خاص بطبقة البيانات (بدون Material).
class _DueTime {
  final int hour;
  final int minute;
  const _DueTime({required this.hour, required this.minute});
}
