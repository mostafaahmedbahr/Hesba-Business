import '../../../../core/services/app_events.dart';
import 'models/activity_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hesba/core/utils/dynamic_text.dart';

/// نص جاهز لنشاط واحد + الوجهة اللي يفتحها لو اتنضغط عليه.
///
/// [payload] بيتسجّل في السجل وبيتبعت كـ notification payload، وبعدين
/// `main.dart` يحوّله لـ route (`activity:sale` → تاب المبيعات، إلخ).
class ActivityMessage {
  final ActivityType type;
  final String title;
  final String body;
  final String payload;

  const ActivityMessage({
    required this.type,
    required this.title,
    required this.body,
    required this.payload,
  });
}

/// يحوّل حدث عام لنشاط غني بالتفاصيل (اسم المنتج، السعر، المكسب).
///
/// بيرجع `null` للحدث العام `productChanged` (متغطّى بالحالات المحددة).
ActivityMessage? buildActivityMessage(AppEvent event) {
  final data = event.data ?? const <String, dynamic>{};

  switch (event.type) {
    case AppEventType.saleCreated:
      final items = _list(data['items']);
      final lines = <String>[];
      for (final raw in items.take(3)) {
        final m = _map(raw);
        lines.add(uiTr('${_name(m['name'])} × ${_num(m['qty'])} = ${_money(m['total'])} ج.م'));
      }
      if (items.length > 3) {
        final extra = items.length - 3;
        lines.add(extra == 1 ? 'ومنتج تاني'.tr() : uiTr('و$extra منتجات تانية'));
      }

      final total = _double(data['total']);
      final discount = _double(data['discount']);
      final profit = _double(data['profit']);
      final pay = _payLabel(data['paymentMethod']);

      final head = lines.isEmpty ? 'فاتورة جديدة'.tr() : lines.join('\n');
      final tail = StringBuffer(uiTr('الإجمالي: ${_money(total)} ج.م'));
      if (discount > 0) tail.write(uiTr(' • خصم ${_money(discount)}'));
      // الربح دايمًا ظاهر (حتى لو صفر) عشان اللي يقرا يعرف يكسب كام.
      tail.write(uiTr('\nالربح: ${_money(profit)} ج.م'));
      if (pay.isNotEmpty) tail.write(' • $pay');

      return ActivityMessage(
        type: ActivityType.sale,
        title: 'تم تسجيل بيع جديد'.tr(),
        body: '$head\n$tail',
        payload: 'activity:sale',
      );

    case AppEventType.returnCreated:
      final items = _list(data['items']);
      final names = items
          .map((e) => '${_name(_map(e)['name'])} × ${_num(_map(e)['qty'])}')
          .take(3)
          .join('، ');
      final reason = (data['reason'] ?? '').toString().trim();

      final body = StringBuffer();
      if (names.isNotEmpty) body.write('$names\n');
      body.write(uiTr('الإجمالي: ${_money(_double(data['total']))} ج.م'));
      if (reason.isNotEmpty) body.write(uiTr('\nالسبب: $reason'));

      return ActivityMessage(
        type: ActivityType.returnAdd,
        title: 'تم تسجيل مرتجع'.tr(),
        body: body.toString(),
        payload: 'activity:return',
      );

    case AppEventType.expenseCreated:
      return ActivityMessage(
        type: ActivityType.expenseAdd,
        title: 'تم تسجيل مصروف'.tr(),
        body: _expenseBody(data),
        payload: 'activity:expense',
      );

    case AppEventType.expenseUpdated:
      return ActivityMessage(
        type: ActivityType.expenseUpdate,
        title: 'تم تعديل مصروف'.tr(),
        body: _expenseBody(data),
        payload: 'activity:expense',
      );

    case AppEventType.expenseDeleted:
      return ActivityMessage(
        type: ActivityType.expenseDelete,
        title: 'تم حذف مصروف'.tr(),
        body: _expenseBody(data),
        payload: 'activity:expense',
      );

    case AppEventType.productAdded:
      return ActivityMessage(
        type: ActivityType.productAdd,
        title: 'تم إضافة منتج'.tr(),
        body: _productBody(data),
        payload: 'activity:product',
      );

    case AppEventType.productUpdated:
      return ActivityMessage(
        type: ActivityType.productUpdate,
        title: 'تم تعديل منتج'.tr(),
        body: _productBody(data),
        payload: 'activity:product',
      );

    case AppEventType.productDeleted:
      final name = (data['name'] ?? '').toString().trim();
      return ActivityMessage(
        type: ActivityType.productDelete,
        title: 'تم حذف منتج'.tr(),
        body: name.isEmpty ? 'منتج اتشال من المخزون'.tr() : uiTr('$name اتشال من المخزون'),
        payload: 'activity:product',
      );

    case AppEventType.productChanged:
      return null; // عام — متغطّي بالحالات المحددة.
  }
}

// ── مساعدين ────────────────────────────────────────────────

String _expenseBody(Map<String, dynamic> data) {
  final title = (data['title'] ?? '').toString().trim();
  final category = (data['category'] ?? '').toString().trim();
  final amount = _money(_double(data['amount']));

  final parts = <String>[
    if (title.isEmpty) 'مصروف'.tr() else title,
    uiTr('$amount ج.م'),
  ];
  var body = parts.join(' — ');
  if (category.isNotEmpty) body = '$body\n$category';
  return body;
}

String _productBody(Map<String, dynamic> data) {
  final name = _name(data['name'], '');
  final category = (data['category'] ?? '').toString().trim();
  final price = _double(data['price']);
  final stock = _double(data['stock']);

  final lines = <String>[
    if (name.isEmpty) 'منتج جديد'.tr() else name,
    uiTr('السعر: ${_money(price)} ج.م • المخزون: ${_num(stock)}'),
    if (category.isNotEmpty) uiTr('القسم: $category'),
  ];
  return lines.join('\n');
}

String _payLabel(dynamic value) {
  switch ((value ?? '').toString()) {
    case 'cash':
      return 'نقدي'.tr();
    case 'card':
      return 'بطاقة'.tr();
    case 'mobile_wallet':
      return 'محفظة إلكترونية'.tr();
    case 'credit':
      return 'آجل'.tr();
    default:
      return (value ?? '').toString().trim();
  }
}

double _double(dynamic v) => v is num ? v.toDouble() : 0;

/// اسم منتج بيتحط fallback لو ناقص (بيانات قديمة ممكن تبقى فاضية).
String _name(dynamic v, [String? fallback]) {
  final s = (v ?? '').toString().trim();
  return s.isEmpty ? (fallback ?? 'منتج'.tr()) : s;
}

/// رقم بدون كسور مشروطة (0.5 يفضل 0.5).
String _num(dynamic v) {
  final d = _double(v);
  return d == d.roundToDouble() ? d.toInt().toString() : d.toStringAsFixed(2);
}

/// مبلغ: صحيح بدون كسور، وكسر بخانتين.
String _money(dynamic v) {
  final d = _double(v);
  return d == d.roundToDouble() ? d.toInt().toString() : d.toStringAsFixed(2);
}

List<dynamic> _list(dynamic v) => v is List ? v : const [];

Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : const <String, dynamic>{};
