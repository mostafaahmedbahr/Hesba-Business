import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/paged_fetch.dart';
import '../../../accounts/data/models/debt_model.dart';
import '../../../accounts/data/models/person_model.dart';
import '../../../accounts/data/repos/accounts_repo.dart';
import '../models/sale_model.dart';
import '../repos/sales_repo.dart';

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
    } catch (_) {
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
      final person = await _accounts.findOrCreatePerson(
        name: cleanCustomerName,
        phone: cleanCustomerPhone,
        partyType: PersonModel.typeCustomer,
      );
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

    final saleRef = firestore.collection(AppConstants.salesCollection).doc();

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
    await firestore.runTransaction((transaction) async {
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

    return sale;
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
  Future<PagedResult<SaleModel>> fetchAllSales({required String shopId}) {
    return fetchAllPages<SaleModel>(
      idOf: (sale) => sale.saleId,
      fetchPage: (cursor) async {
        Query<Map<String, dynamic>> query = firestore
            .collection(AppConstants.salesCollection)
            .where('shopId', isEqualTo: shopId)
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
