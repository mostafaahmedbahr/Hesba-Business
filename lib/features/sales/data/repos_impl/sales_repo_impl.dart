import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/paged_fetch.dart';
import '../../../accounts/data/models/debt_model.dart';
import '../../../accounts/data/models/person_model.dart';
import '../../../accounts/data/repos/accounts_repo.dart';
import '../models/sale_model.dart';
import '../repos/sales_repo.dart';
import 'package:hesba/core/services/app_logger.dart';

class SalesRepoImpl implements SalesRepo {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final AccountsRepo _accounts;

  SalesRepoImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required AccountsRepo accountsRepo,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance,
        _accounts = accountsRepo;

  String? get _uid => auth.currentUser?.uid;

  Future<String?> _resolveShopId(String? providedShopId) async {
    if (providedShopId != null && providedShopId.isNotEmpty) {
      return providedShopId;
    }
    if (_uid == null) return null;
    final doc = await firestore.collection('users').doc(_uid).get();
    if (!doc.exists) return null;
    return doc.data()?['shopId'] as String?;
  }

  Future<String?> _resolveOwnerId(String? providedOwnerId) async {
    if (providedOwnerId != null && providedOwnerId.isNotEmpty) {
      return providedOwnerId;
    }
    return _uid;
  }

  /// عند رفض Firestore لكتابة المبيعة، نقرأ نفس البيانات اللي القواعد
  /// بتتحقق منها ونرجّع سببًا عربيًا واضحًا يظهر للمستخدم بدل رسالة
  /// permission-denied غامضة. قراءات فقط وما بيغيّرش أي حاجة.
  Future<String> _describeDenial(SaleModel sale) async {
    try {
      final uid = _uid;
      final ownerId = sale.ownerId;
      final shopId = sale.shopId;
      final userDoc = await firestore.collection('users').doc(uid).get();
      final u = userDoc.data() ?? const <String, dynamic>{};
      final subDoc = await firestore
          .collection('users')
          .doc(uid)
          .collection('subscription')
          .doc('current')
          .get();
      final s = subDoc.data() ?? const <String, dynamic>{};

      final rawEnd = s['endDate'];
      DateTime? end;
      if (rawEnd is Timestamp) {
        end = rawEnd.toDate();
      } else if (rawEnd is DateTime) {
        end = rawEnd;
      }
      final endLive = end != null && end.isAfter(DateTime.now());
      final status = s['status']?.toString() ?? 'غير موجود';
      final suspended = s['suspended'] == true;
      final userShop = u['shopId']?.toString() ?? '';

      // باقي شروط قاعدة المبيعات: معرّف الحساب، قيم الفاتورة، والعميل المختار.
      DocumentSnapshot<Map<String, dynamic>>? personSnap;
      if (sale.personId.isNotEmpty) {
        personSnap = await firestore.collection('persons').doc(sale.personId).get();
      }
      final personShop = personSnap?.data()?['shopId']?.toString() ?? '';
      final badAmounts = sale.subtotal < 0 || sale.discount < 0 || sale.total < 0;

      // تحديث المخزون داخل نفس الـ transaction لازم يعدي قاعدة المنتجات،
      // اللي بتشترط إن ownerId بتاع المنتج = معرّف المستخدم الحالي.
      final productOwners = <String>[];
      for (final item in sale.items) {
        if (item.productId.isEmpty) continue;
        try {
          final p = await firestore.collection('products').doc(item.productId).get();
          final d = p.data() ?? const <String, dynamic>{};
          var supplierInfo = '';
          final sid = d['supplierId'];
          if (sid != null && sid.toString().isNotEmpty) {
            final sup = await firestore.collection('suppliers').doc(sid.toString()).get();
            supplierInfo =
                ' supExists=${sup.exists} supShop=${sup.data()?['shopId']}';
          }
          productOwners.add(
            '${item.productName} owner=${d['ownerId']} price=${d['price']} '
            'stock=${d['stock']} low=${d['lowStockThreshold']} '
            'supId=$sid supName=${d['supplierName']}$supplierInfo',
          );
        } catch (logErr, logSt) {
          AppLogger.nonFatal('SALES_DIAG_PRODUCT', logErr, logSt);
          productOwners.add('${item.productName}:? $logErr');
        }
      }

      late final String reason;
      if (uid != ownerId) {
        reason = 'معرّف الحساب مختلف عن معرّف الفاتورة';
      } else if (badAmounts) {
        reason = 'قيم الفاتورة (الإجمالي/الخصم) غير صالحة';
      } else if (sale.personId.isNotEmpty && !personSnap!.exists) {
        reason = 'العميل المختار غير موجود';
      } else if (sale.personId.isNotEmpty && personShop != shopId) {
        reason = 'العميل المختار غير مرتبط بهذا المحل';
      } else if (!subDoc.exists) {
        reason = 'لا يوجد اشتراك مسجّل لهذا الحساب';
      } else if (suspended) {
        reason = 'الحساب موقوف من الإدارة';
      } else if (!endLive) {
        reason = 'انتهت مدة الاشتراك';
      } else if (status != 'trial' && status != 'active') {
        reason = 'حالة الاشتراك ($status) لا تسمح بالبيع — لازم الأدمن يوافق على التجديد';
      } else if (u['isActive'] == false) {
        reason = 'الحساب غير مفعّل';
      } else if (userShop.isEmpty || userShop != shopId) {
        reason = 'المحل المرتبط بالحساب مختلف عن محل المبيعة';
      } else {
        reason = 'الصلاحية مرفوضة من إعدادات الأمان';
      }

      AppLogger.warning(
        'uid=$uid role=${u['role']} active=${u['isActive']} userShopId=$userShop '
        'saleOwnerId=$ownerId saleShopId=$shopId '
        'subtotal=${sale.subtotal} discount=${sale.discount} total=${sale.total} '
        'personId=${sale.personId} personShop=$personShop '
        'productOwners=$productOwners | '
        'subExists=${subDoc.exists} subStatus=$status '
        'subEnd=$end subSuspended=$suspended | سبب الرفض: $reason',
        context: 'SALES_DIAG',
      );
      return reason;
    } catch (logErr, logSt) {
      AppLogger.nonFatal('SALES_DIAG', logErr, logSt);
      return 'تعذر التأكد من حالة الاشتراك، حاول مرة أخرى';
    }
  }

  /// اسم المحل ليُحفظ مع كل فاتورة.
  ///
  /// يُجلب من shops/{shopName} مع fallback لاسم المستخدم، ويُخزَّن للجلسة
  /// حتى لا نقرأه في كل عملية. الفشل لا يمنع حفظ الفاتورة ('').
  String? _cachedShopNameFor;
  String? _cachedShopName;

  Future<String> _resolveShopName(String shopId) async {
    if (_cachedShopNameFor == shopId && _cachedShopName != null) {
      return _cachedShopName!;
    }
    try {
      final shopDoc = await firestore
          .collection(AppConstants.shopsCollection)
          .doc(shopId)
          .get();
      var name = shopDoc.data()?['shopName'] as String? ?? '';
      if (name.trim().isEmpty && _uid != null) {
        final userDoc = await firestore.collection('users').doc(_uid!).get();
        name = userDoc.data()?['shopName'] as String? ?? '';
      }
      name = name.trim();
      if (name.isEmpty) return '';
      _cachedShopNameFor = shopId;
      _cachedShopName = name;
      return name;
    } catch (logErr, logSt) {
      AppLogger.nonFatal('features/sales/data/repos_impl/sales_repo_impl.dart', logErr, logSt, severity: LoggingSeverity.warning);
      return '';
    }
  }

  @override
  Future<SaleModel> addSale({
    required String ownerId,
    required String shopId,
    required List<SaleItemModel> items,
    required double discount,
    required String paymentMethod,
    required String note,
    String? customerName,
    String? customerPhone,
    String? requestId,
  }) async {
    if (items.isEmpty) {
      throw Exception('يجب إضافة منتج واحد على الأقل');
    }

    final resolvedShopId = await _resolveShopId(shopId);
    final resolvedOwnerId = await _resolveOwnerId(ownerId);

    if (resolvedShopId == null || resolvedShopId.isEmpty) {
      throw Exception('لم يتم العثور على المتجر');
    }
    if (resolvedOwnerId == null || resolvedOwnerId.isEmpty) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final shopName = await _resolveShopName(resolvedShopId);

    // Validate items
    for (final item in items) {
      if (item.productName.trim().isEmpty) {
        throw Exception('اسم المنتج مطلوب');
      }
      if (item.quantity <= 0) {
        throw Exception('الكمية يجب أن تكون أكبر من صفر: ${item.productName}');
      }
      if (item.unitPrice <= 0) {
        throw Exception('سعر المنتج يجب أن يكون أكبر من صفر: ${item.productName}');
      }
    }

    // ربط اختياري بجهة اتصال (persons): الاتنين معًا أو الاتنين فاضيين.
    // يُنشأ/يُوجد الشخص قبل كتابة الفاتورة — قواعد Firestore تُقيَّم
    // أثناء تنفيذ العملية فتحتاج مستند الشخص موجودًا فعلًا.
    final cleanCustomerName = customerName?.trim() ?? '';
    final cleanCustomerPhone = customerPhone?.trim() ?? '';
    var personId = '';
    var personName = '';
    var personPhone = '';
    if (cleanCustomerName.isNotEmpty || cleanCustomerPhone.isNotEmpty) {
      if (cleanCustomerName.isEmpty || cleanCustomerPhone.isEmpty) {
        throw Exception('اكتب اسم العميل ورقم هاتفه معًا');
      }
      // خطوة منفصلة عن كتابة الفاتورة: عميل جديد = إنشاء مستند persons أولًا.
      // لو القواعد رفضتها، رسالة البيع العامة كانت بتضلل المستخدم (بتقول إنها
      // مشكلة موظف/اشتراك). هنا نسمّي الخطوة نفسها عشان يفهم إيه اللي فشل.
      late final PersonModel person;
      try {
        person = await _accounts.findOrCreatePerson(
          name: cleanCustomerName,
          phone: cleanCustomerPhone,
          partyType: PersonModel.typeCustomer,
        );
      } on FirebaseException catch (logErr, logSt) {
        AppLogger.nonFatal(
          'features/sales/data/repos_impl/sales_repo_impl.dart (create person)',
          logErr,
          logSt,
          severity: LoggingSeverity.warning,
        );
        throw Exception(
          'تعذّر حفظ بيانات العميل الجديد (الاسم والرقم). تأكد من سريان الاشتراك ونشر قواعد Firestore، أو اختر عميلًا موجودًا.',
        );
      }
      personId = person.id;
      personName = cleanCustomerName;
      personPhone = cleanCustomerPhone;
    }

    final isCredit = paymentMethod == AppConstants.paymentCredit;
    // البيع الآجل يفرض اختيار عميل — مفيش ذمة من غير شخص.
    if (isCredit &&
        (cleanCustomerName.isEmpty || cleanCustomerPhone.isEmpty)) {
      throw Exception('البيع الآجل يتطلب اختيار عميل');
    }

    final subtotal = items.fold<double>(0, (acc, item) => acc + item.total);
    final double finalDiscount = discount < 0 ? 0 : discount > subtotal ? subtotal : discount;
    final double total = subtotal - finalDiscount < 0 ? 0 : subtotal - finalDiscount;

    // المديونية تتسجل بمبلغ > 0 (قواعد Firestore تتطلب ذلك).
    if (isCredit && total <= 0) {
      throw Exception('لا يمكن تسجيل بيع آجل بإجمالي صفر');
    }

    // An idempotency key fixes the document id: a retry after a lost response
    // reads back the original sale instead of creating a second one.
    final saleRef = requestId == null
        ? firestore.collection(AppConstants.salesCollection).doc()
        : firestore.collection(AppConstants.salesCollection).doc(requestId);

    final sale = SaleModel(
      saleId: saleRef.id,
      ownerId: resolvedOwnerId,
      shopId: resolvedShopId,
      shopName: shopName,
      items: items,
      subtotal: subtotal,
      discount: finalDiscount.toDouble(),
      total: total,
      paymentMethod: paymentMethod,
      note: note.trim(),
      personId: personId,
      personName: personName,
      personPhone: personPhone,
      createdAt: DateTime.now(),
    );

    // Use transaction to ensure stock availability and decrement atomically
    SaleModel? alreadyWritten;
    try {
      await firestore.runTransaction((transaction) async {
      if (requestId != null) {
        final existing = await transaction.get(saleRef);
        if (existing.exists && existing.data() != null) {
          alreadyWritten = SaleModel.fromJson(existing.data()!);
          return; // identical retry — skip ALL writes, including stock
        }
      }
      // Check stock for items that have productId
      for (final item in items) {
        if (item.productId.isNotEmpty) {
          final productRef = firestore
              .collection(AppConstants.productsCollection)
              .doc(item.productId);
          final snap = await transaction.get(productRef);
          if (!snap.exists) {
            throw Exception('المنتج غير موجود: ${item.productName}');
          }
          final data = snap.data()!;
          // The product must belong to the same shop as the sale.
          if ((data['shopId'] as String?) != resolvedShopId) {
            throw Exception('المنتج لا يتبع هذا المحل: ${item.productName}');
          }
          final currentStock = (data['stock'] as num?)?.toDouble() ?? 0;
          final isActive = data['isActive'] as bool? ?? true;
          if (!isActive) {
            throw Exception('المنتج غير متاح: ${item.productName}');
          }
          if (currentStock < item.quantity) {
            throw Exception(
                'الكمية المطلوبة غير متوفرة لـ ${item.productName} (المتاح: $currentStock)');
          }
          // Decrement stock (نص كيلو = خصم 0.5 تماماً)
          transaction.update(productRef, {
            'stock': currentStock - item.quantity,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      transaction.set(saleRef, sale.toJson());

      // البيع الآجل: ذمة بقيمة الإجمالي على العميل — تُكتب في نفس
      // الـ transaction، فالفاتورة والذمة بيتسجّلوا مع بعض أو لا شيء.
      // الذمة تظهر فورًا في شاشة الحسابات (live stream).
      if (isCredit) {
        final debtRef = firestore
            .collection(AppConstants.debtsCollection)
            .doc();
        final invoiceShort =
            saleRef.id.length >= 6 ? saleRef.id.substring(0, 6) : saleRef.id;
        final saleNote = note.trim();
        final debtNote = saleNote.isEmpty
            ? 'فاتورة #$invoiceShort'
            : 'فاتورة #$invoiceShort — $saleNote';
        final debt = DebtModel(
          id: debtRef.id,
          ownerId: resolvedOwnerId,
          shopId: resolvedShopId,
          personId: personId,
          personName: personName,
          personPhone: personPhone,
          partyType: DebtParty.customer,
          direction: DebtDirection.receivable,
          amount: total,
          paidAmount: 0,
          note: debtNote,
        );
        transaction.set(debtRef, {
          ...debt.toJson(),
          'id': debtRef.id,
          'saleId': saleRef.id,
          'ownerId': resolvedOwnerId,
          'shopId': resolvedShopId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      });
    } on FirebaseException catch (e) {
      final reason = await _describeDenial(sale);
      if (e.code == 'permission-denied') {
        throw Exception('تعذر حفظ المبيعة: $reason');
      }
      rethrow;
    }

    return alreadyWritten ?? sale;
  }

  @override
  Future<List<SaleModel>> getSales({required String shopId}) async {
    final resolvedShopId = await _resolveShopId(shopId);
    if (resolvedShopId == null) return [];
    final snap = await firestore
        .collection(AppConstants.salesCollection)
        .where('shopId', isEqualTo: resolvedShopId)
        .orderBy('createdAt', descending: true)
        .limit(500)
        .get();
    return snap.docs
        .map((d) => SaleModel.fromJson(d.data()))
        .toList();
  }

  @override
  Stream<List<SaleModel>> watchSalesForPerson({
    required String shopId,
    required String personId,
  }) {
    if (personId.isEmpty) return const Stream.empty();
    return firestore
        .collection(AppConstants.salesCollection)
        .where('shopId', isEqualTo: shopId)
        .where('personId', isEqualTo: personId)
        .orderBy('createdAt', descending: true)
        .limit(500)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => SaleModel.fromJson(d.data())).toList());
  }

  /// id محل اليوزر الحالي.
  @override
  Future<String?> getShopId() => _resolveShopId(null);

  @override
  Stream<List<SaleModel>> watchSales({required String shopId}) {
    return firestore
        .collection(AppConstants.salesCollection)
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt', descending: true)
        .limit(500)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => SaleModel.fromJson(d.data())).toList());
  }

  @override
  Future<PagedResult<SaleModel>> fetchAllSales({
    required String shopId,
    DateTime? from,
  }) {
    return fetchAllPages<SaleModel>(
      idOf: (sale) => sale.saleId,
      fetchPage: (cursor) async {
        Query<Map<String, dynamic>> query = firestore
            .collection(AppConstants.salesCollection)
            .where('shopId', isEqualTo: shopId);
        if (from != null) {
          query = query.where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(from),
          );
        }
        query = query
            .orderBy('createdAt', descending: true)
            .limit(kReportPageSize);
        if (cursor != null) {
          query = query
              .startAfterDocument(cursor as DocumentSnapshot<Map<String, dynamic>>);
        }
        final snap = await query.get();
        return PageResult<SaleModel>(
          items: snap.docs.map((d) => SaleModel.fromJson(d.data())).toList(),
          cursor: snap.docs.isEmpty ? null : snap.docs.last,
          hasMore: snap.docs.length >= kReportPageSize,
        );
      },
    );
  }

  @override
  Stream<void> watchLatestSale({required String shopId}) {
    return firestore
        .collection(AppConstants.salesCollection)
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map<void>((_) {});
  }
}
