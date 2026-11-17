import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hesba/core/services/app_events.dart';
import 'package:hesba/features/notifications/data/activity_message.dart';
import 'package:hesba/features/sales/data/models/sale_model.dart';
import 'package:hesba/features/sales/data/repos/sales_repo.dart';
import 'package:hesba/features/sales/presentation/cubit/sales_cubit.dart';

class MockSalesRepo extends Mock implements SalesRepo {}

/// Bug 1: إشعار البيع كان يعرض مجموع أرباح الأسطر (قبل الخصم) كـ"الربح"،
/// فيُبالغ في الربح بمقدار الخصم. الآن يمرّ عبر ReportsCalculator.netProfitForSale.
void main() {
  late MockSalesRepo repo;
  late SaleModel sale;

  final items = [
    SaleItemModel(
      productId: 'p1',
      productName: 'منتج p1',
      quantity: 2,
      unitPrice: 100,
      costPrice: 60,
    ),
    SaleItemModel(
      productId: 'p2',
      productName: 'منتج p2',
      quantity: 1,
      unitPrice: 50,
      costPrice: 30,
    ),
  ];

  setUp(() {
    repo = MockSalesRepo();
    // subtotal 250، خصم 50 (20%)، total 200، تكلفة اللقطات 150 ⇒ ربح 50.
    sale = SaleModel(
      saleId: 's1',
      ownerId: 'owner-1',
      shopId: 'shop-1',
      items: items,
      subtotal: 250,
      discount: 50,
      total: 200,
      paymentMethod: 'cash',
      note: '',
      createdAt: DateTime(2026, 1, 5),
    );
    when(
      () => repo.addSale(
        ownerId: any(named: 'ownerId'),
        shopId: any(named: 'shopId'),
        items: any(named: 'items'),
        discount: any(named: 'discount'),
        paymentMethod: any(named: 'paymentMethod'),
        note: any(named: 'note'),
        customerName: any(named: 'customerName'),
        customerPhone: any(named: 'customerPhone'),
        requestId: any(named: 'requestId'),
      ),
    ).thenAnswer((_) async => sale);
  });

  test('حدث البيع يحمل صافي الربح بعد الخصم، لا مجموع أرباح الأسطر', () async {
    final eventFuture = AppEvents.instance.stream
        .where((e) => e.type == AppEventType.saleCreated)
        .first;
    final cubit = SalesCubit(salesRepo: repo);

    await cubit.addSale(
      ownerId: 'owner-1',
      shopId: 'shop-1',
      items: items,
      discount: 50,
      paymentMethod: 'cash',
      note: '',
    );

    final event = await eventFuture;
    expect(event.data!['profit'], 50); // وليس 100
    expect(event.data!['total'], 200);
    expect(event.data!['discount'], 50);

    final message = buildActivityMessage(event);
    expect(message, isNotNull);
    expect(message!.body, contains('الربح: 50'));
    expect(message.body, isNot(contains('الربح: 100')));
    // لا ننشر ربح سطر خاطئًا داخل تفاصيل الأصناف.
    for (final line in event.data!['items'] as List<dynamic>) {
      expect((line as Map<String, dynamic>).containsKey('profit'), isFalse);
    }
    await cubit.close();
  });
}
