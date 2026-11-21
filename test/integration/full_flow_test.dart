import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hesba/core/constants/app_constants.dart';
import 'package:hesba/core/services/cloudinary_image_service.dart';
import 'package:hesba/features/accounts/data/repos_impl/accounts_repo_impl.dart';
import 'package:hesba/features/admin/data/repos_impl/admin_repo_impl.dart';
import 'package:hesba/features/returns/data/models/return_model.dart';
import 'package:hesba/features/returns/data/repos_impl/returns_repo_impl.dart';
import 'package:hesba/features/sales/data/models/sale_model.dart';
import 'package:hesba/features/sales/data/repos_impl/sales_repo_impl.dart';
import 'package:hesba/features/subscription/data/models/subscription_model.dart';
import 'package:hesba/features/subscription/data/models/subscription_plan.dart';
import 'package:hesba/features/subscription/data/models/subscription_request_model.dart';
import 'package:hesba/features/subscription/data/repos_impl/subscription_repo_impl.dart';

import '../helpers/test_auth.dart';

class MockCloudinary extends Mock implements CloudinaryImageService {}

/// End-to-end business flow over the REAL repos with an in-memory Firestore:
/// credit sale -> idempotent retry -> return -> debt settlement -> renewal
/// request -> admin approval -> later rejection that must not revoke the
/// already-paid period. This is integration coverage of the money path.
void main() {
  late FakeFirebaseFirestore db;
  late SalesRepoImpl sales;
  late ReturnsRepoImpl returns;
  late SubscriptionRepoImpl subscriptions;
  late AdminRepoImpl admin;

  const uid = 'owner-1';
  const shop = 'shop-1';

  Future<void> seedSubscription({
    String status = 'active',
    DateTime? endDate,
    String? lastRequestId,
  }) =>
      db.collection('users').doc(uid).collection('subscription').doc('current').set({
        'status': status,
        'plan': SubscriptionPlan.monthly.id,
        'startDate': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'endDate': Timestamp.fromDate(endDate ?? DateTime(2026, 12, 31)),
        'isTrial': false,
        'lastRequestId': lastRequestId,
        'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });

  Future<Map<String, dynamic>> currentSubscription() async =>
      (await db.collection('users').doc(uid).collection('subscription').doc('current').get()).data()!;

  setUp(() async {
    db = FakeFirebaseFirestore();
    await db.collection('users').doc(uid).set({
      'shopId': shop,
      'shopName': 'محلي',
      'ownerName': 'مالك',
      'phone': '01000000001',
      'role': 'owner',
    });
    await db.collection(AppConstants.productsCollection).doc('p1').set({
      'id': 'p1',
      'name': 'منتج 1',
      'shopId': shop,
      'ownerId': uid,
      'stock': 10,
      'costPrice': 60,
      'price': 100,
      'isActive': true,
    });
    await seedSubscription();

    final auth = signedInAuth(uid);
    final accounts = AccountsRepoImpl(auth: auth, firestore: db);
    sales = SalesRepoImpl(firestore: db, auth: auth, accountsRepo: accounts);
    returns = ReturnsRepoImpl(firestore: db, auth: auth);
    subscriptions = SubscriptionRepoImpl(
      auth: auth,
      firestore: db,
      cloudinary: MockCloudinary(),
    );
    admin = AdminRepoImpl(auth: auth, firestore: db);
  });

  Future<SaleModel> creditSale(String requestId) => sales.addSale(
        ownerId: uid,
        shopId: shop,
        items: [
          SaleItemModel(
            productId: 'p1',
            productName: 'منتج 1',
            quantity: 2,
            unitPrice: 100,
            costPrice: 60,
          ),
        ],
        discount: 0,
        paymentMethod: AppConstants.paymentCredit,
        note: '',
        customerName: 'أحمد',
        customerPhone: '01001112223',
        requestId: requestId,
      );

  Future<double> stock() async {
    final doc = await db.collection(AppConstants.productsCollection).doc('p1').get();
    return (doc.data()!['stock'] as num).toDouble();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> debts() =>
      db.collection(AppConstants.debtsCollection).get();

  test('credit sale -> retry -> partial return settles debt exactly once', () async {
    final first = await creditSale('sale-req-1');
    final retry = await creditSale('sale-req-1');

    expect(retry.saleId, first.saleId);
    expect((await db.collection(AppConstants.salesCollection).get()).docs, hasLength(1));
    expect(await stock(), 8);

    final debtDocs = (await debts()).docs;
    expect(debtDocs, hasLength(1));
    final debtId = debtDocs.single.id;
    expect((debtDocs.single.data()['amount'] as num).toDouble(), 200);
    expect((debtDocs.single.data()['paidAmount'] as num).toDouble(), 0);

    final result = await returns.addReturn(
      ownerId: uid,
      shopId: shop,
      originalSaleId: first.saleId,
      items: [
        ReturnItemModel(
          productId: 'p1',
          productName: 'منتج 1',
          quantity: 1,
          unitPrice: 100,
        ),
      ],
      reason: 'تلف',
      note: '',
      requestId: 'return-req-1',
    );
    expect(result, isA<ReturnModel>());
    expect(await stock(), 9);
    expect((await debts()).docs.single.id, debtId);
    final settled = (await debts()).docs.single.data();
    expect((settled['paidAmount'] as num).toDouble(), 100);
    final payments =
        await db.collection('${AppConstants.debtsCollection}/$debtId/payments').get();
    expect(payments.docs, hasLength(1));

    // Retry after a lost response must not restore stock or settle twice.
    await returns.addReturn(
      ownerId: uid,
      shopId: shop,
      originalSaleId: first.saleId,
      items: [
        ReturnItemModel(
          productId: 'p1',
          productName: 'منتج 1',
          quantity: 1,
          unitPrice: 100,
        ),
      ],
      reason: 'تلف',
      note: '',
      requestId: 'return-req-1',
    );
    expect(await stock(), 9);
    final afterRetry = (await debts()).docs.single.data();
    expect((afterRetry['paidAmount'] as num).toDouble(), 100);
  });

  test('renewal approval extends the live period; rejection keeps it', () async {
    // A live period that ends soon: approval must APPEND to it, not start over.
    await seedSubscription(endDate: DateTime.now().add(const Duration(days: 10)));
    final before = (await currentSubscription())['endDate'] as Timestamp;
    final request = await subscriptions.submitRequest(
      plan: SubscriptionPlan.monthly,
      paymentMethod: SubscriptionPaymentMethod.instapay,
      paymentProofUrl: 'https://example.com/receipt.png',
    );

    await admin.approveRequest(request);
    final approved = await currentSubscription();
    expect(approved['status'], 'active');
    expect(approved['lastRequestId'], request.requestId);
    final after = (approved['endDate'] as Timestamp).toDate();
    expect(after.isAfter(before.toDate()), isTrue);

    // A newer request arrives, then an admin rejects it — the paid period
    // granted by the approval above must survive untouched.
    const secondId = 'req-2';
    final second = SubscriptionRequestModel(
      requestId: secondId,
      userId: uid,
      ownerName: 'مالك',
      shopName: 'محلي',
      phone: '01000000001',
      plan: SubscriptionPlan.monthly,
      amount: 99,
      paymentMethod: SubscriptionPaymentMethod.instapay.id,
      paymentProofUrl: 'https://example.com/receipt2.png',
      status: SubscriptionRequestModel.statusPending,
      createdAt: DateTime.now(),
    );
    await db.collection('subscription_requests').doc(secondId).set(second.toJson());
    await db.collection('users').doc(uid).collection('subscription').doc('current').update({
      'status': 'pending',
      'lastRequestId': secondId,
    });

    await admin.rejectRequest(second, 'مرفوض');
    final rejected = await currentSubscription();
    expect(rejected['status'], SubscriptionStatus.active.id);
    expect((rejected['endDate'] as Timestamp).toDate(), after);

    // Stale/duplicate decision cannot be replayed.
    await expectLater(admin.rejectRequest(second, 'مرفوض'), throwsA(isA<StateError>()));
    expect((await currentSubscription())['status'], SubscriptionStatus.active.id);
  });
}
